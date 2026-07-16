import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SRK = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
// Set via: supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)"
const FIREBASE_SA_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? ''

// ── FCM V1 helpers ────────────────────────────────────────────────────────────

async function getAccessToken(sa: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header  = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss:   sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud:   'https://oauth2.googleapis.com/token',
    iat:   now,
    exp:   now + 3600,
  }

  const b64url = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  const signingInput = `${b64url(header)}.${b64url(payload)}`

  const pemBody = sa.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  const keyBytes = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0))

  const key = await crypto.subtle.importKey(
    'pkcs8', keyBytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  )

  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(signingInput),
  )
  const encodedSig = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  const jwt = `${signingInput}.${encodedSig}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion:  jwt,
    }),
  })
  const { access_token } = await res.json()
  return access_token as string
}

async function sendFcmV1(
  projectId: string,
  token: string,
  accessToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          apns: { payload: { aps: { sound: 'default' } } },
          android: { priority: 'HIGH' },
        },
      }),
    },
  )
  return res.ok
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  try {
    const { coach_id, position_key, graduation_year } =
      await req.json() as {
        coach_id: string
        position_key: string
        graduation_year: number
        slot_status: string
      }

    const db = createClient(SUPABASE_URL, SUPABASE_SRK)

    // Get school name
    const { data: coachRow } = await db
      .from('coaches')
      .select('school_name')
      .eq('id', coach_id)
      .single()
    const schoolName = coachRow?.school_name ?? 'A program'
    const posDisplay = position_key.toUpperCase()

    // Find players matched with this coach at ≥40 score
    const { data: matches } = await db
      .from('player_coach_matches')
      .select(`
        player_id,
        total_score,
        players!inner(user_id, primary_position, graduation_year)
      `)
      .eq('coach_id', coach_id)
      .gte('total_score', 40)

    if (!matches?.length) {
      return new Response('No matches for this coach', { status: 200 })
    }

    // Filter by position + graduation year
    const relevant = matches.filter((m: any) => {
      const p = m.players
      return (
        p.graduation_year === graduation_year &&
        p.primary_position?.toLowerCase() === position_key.toLowerCase()
      )
    })

    if (!relevant.length) {
      return new Response('No players match position+year', { status: 200 })
    }

    const userIds = relevant.map((m: any) => m.players.user_id as string)

    // Save in-app notifications
    const notifRows = relevant.map((m: any) => ({
      user_id:  m.players.user_id,
      type:     'roster_opening',
      title:    `Roster opening at ${schoolName}`,
      title_es: `Vacante en ${schoolName}`,
      body:     `${schoolName} needs a ${posDisplay} for Class of ${graduation_year}. You're a ${Math.round(m.total_score)}% match.`,
      body_es:  `${schoolName} necesita un ${posDisplay} para la Clase del ${graduation_year}. Eres un ${Math.round(m.total_score)}% de coincidencia.`,
      data:     { coach_id, school_name: schoolName, position: posDisplay },
    }))
    await db.from('notifications').insert(notifRows)

    // Get FCM tokens
    const { data: tokenRows } = await db
      .from('device_tokens')
      .select('token')
      .in('user_id', userIds)

    const tokens = tokenRows?.map((r: any) => r.token as string) ?? []

    if (!tokens.length || !FIREBASE_SA_JSON) {
      return new Response(
        JSON.stringify({ in_app: notifRows.length, push: 0 }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 },
      )
    }

    // Get OAuth2 access token from service account
    const sa = JSON.parse(FIREBASE_SA_JSON)
    const accessToken = await getAccessToken(sa)

    const notifTitle = `${schoolName} has an opening`
    const notifBody  = `They need a ${posDisplay} — Class of ${graduation_year}`
    const notifData  = {
      type:        'roster_opening',
      coach_id,
      school_name: schoolName,
      position:    posDisplay,
      screen:      'matches',
    }

    // Send one message per token (FCM V1 doesn't support multicast in a single call)
    let sent = 0
    for (const token of tokens) {
      const ok = await sendFcmV1(sa.project_id, token, accessToken, notifTitle, notifBody, notifData)
      if (ok) sent++
    }

    return new Response(
      JSON.stringify({ in_app: notifRows.length, push: sent }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 },
    )
  } catch (err) {
    console.error('notify-roster-opening error:', err)
    return new Response(String(err), { status: 500 })
  }
})
