/**
 * mux-upload Edge Function
 *
 * Creates a Mux direct upload URL for a player video.
 * The app uploads directly to Mux — never through Supabase.
 *
 * POST /functions/v1/mux-upload
 * Body: { player_id: string, video_type: 'highlight' | 'game_film', title?: string }
 *
 * Returns: { upload_url: string, upload_id: string, video_id: string }
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify user is authenticated
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Get the calling user
    const { data: { user }, error: userErr } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (userErr || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { player_id, video_type, title } = await req.json()

    if (!player_id || !video_type) {
      return new Response(
        JSON.stringify({ error: 'player_id and video_type are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (!['highlight', 'game_film'].includes(video_type)) {
      return new Response(
        JSON.stringify({ error: 'video_type must be highlight or game_film' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Verify this player belongs to the calling user
    const { data: player, error: playerErr } = await supabase
      .from('players')
      .select('id')
      .eq('id', player_id)
      .eq('user_id', user.id)
      .single()

    if (playerErr || !player) {
      return new Response(
        JSON.stringify({ error: 'Player not found or not owned by user' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Create Mux direct upload
    const muxTokenId     = Deno.env.get('MUX_TOKEN_ID') ?? ''
    const muxTokenSecret = Deno.env.get('MUX_TOKEN_SECRET') ?? ''
    const muxAuth = btoa(`${muxTokenId}:${muxTokenSecret}`)

    const muxRes = await fetch('https://api.mux.com/video/v1/uploads', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${muxAuth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        cors_origin: '*',
        new_asset_settings: {
          playback_policy: ['public'],
          mp4_support: 'capped-1080p',
        },
        timeout: 3600, // 1 hour upload window
      }),
    })

    if (!muxRes.ok) {
      const muxErr = await muxRes.text()
      console.error('Mux error:', muxErr)
      return new Response(
        JSON.stringify({ error: 'Failed to create Mux upload' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const muxData = await muxRes.json()
    const uploadId = muxData.data.id
    const uploadUrl = muxData.data.url

    // Upsert player_videos row (replace existing if re-uploading same type)
    const { data: videoRow, error: dbErr } = await supabase
      .from('player_videos')
      .upsert({
        player_id,
        video_type,
        source: 'mux',
        title: title ?? (video_type === 'highlight' ? 'Highlight Film' : 'Full Game Film'),
        mux_upload_id: uploadId,
        status: 'waiting',
        // Clear previous asset/playback IDs if re-uploading
        mux_asset_id: null,
        mux_playback_id: null,
      }, { onConflict: 'player_id,video_type' })
      .select('id')
      .single()

    if (dbErr || !videoRow) {
      console.error('DB error:', dbErr)
      return new Response(
        JSON.stringify({ error: 'Failed to create video record' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    return new Response(
      JSON.stringify({
        upload_url: uploadUrl,
        upload_id: uploadId,
        video_id: videoRow.id,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (err) {
    console.error('Unexpected error:', err)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
