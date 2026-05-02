/**
 * mux-webhook Edge Function
 *
 * Receives Mux webhook events and updates player_videos status.
 * Verifies Mux-Signature header using the webhook signing secret.
 *
 * Events handled:
 *   video.upload.asset_created  → link upload to asset, set status=processing
 *   video.asset.ready           → set playback_id, status=ready, duration
 *   video.asset.errored         → set status=errored
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, mux-signature',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const rawBody = await req.text()

    // ── Verify Mux signature ──────────────────────────────────────────────
    const webhookSecret = Deno.env.get('MUX_WEBHOOK_SECRET')
    if (webhookSecret) {
      const signature = req.headers.get('mux-signature') ?? ''
      // Mux signature format: "t=<timestamp>,v1=<hmac>"
      const parts = Object.fromEntries(
        signature.split(',').map(p => p.split('=') as [string, string])
      )
      const timestamp = parts['t']
      const v1 = parts['v1']

      if (!timestamp || !v1) {
        return new Response(
          JSON.stringify({ error: 'Missing signature' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }

      const payload = `${timestamp}.${rawBody}`
      const key = await crypto.subtle.importKey(
        'raw',
        new TextEncoder().encode(webhookSecret),
        { name: 'HMAC', hash: 'SHA-256' },
        false,
        ['sign'],
      )
      const sigBytes = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload))
      const expected = Array.from(new Uint8Array(sigBytes)).map(b => b.toString(16).padStart(2, '0')).join('')

      if (expected !== v1) {
        return new Response(
          JSON.stringify({ error: 'Invalid signature' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const body = JSON.parse(rawBody)
    const { type, data } = body

    console.log('Mux webhook received:', type)

    if (type === 'video.upload.asset_created') {
      const uploadId = data.upload_id
      const assetId  = data.id

      await supabase
        .from('player_videos')
        .update({ mux_asset_id: assetId, status: 'processing' })
        .eq('mux_upload_id', uploadId)

    } else if (type === 'video.asset.ready') {
      const assetId      = data.id
      const playbackId   = data.playback_ids?.[0]?.id ?? null
      const durationSecs = data.duration ?? null

      await supabase
        .from('player_videos')
        .update({
          mux_playback_id:  playbackId,
          status:           'ready',
          duration_seconds: durationSecs,
        })
        .eq('mux_asset_id', assetId)

    } else if (type === 'video.asset.errored') {
      const assetId = data.id

      await supabase
        .from('player_videos')
        .update({ status: 'errored' })
        .eq('mux_asset_id', assetId)
    }

    return new Response(
      JSON.stringify({ received: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (err) {
    console.error('Webhook error:', err)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
