/**
 * Lanista Matching Engine — Supabase Edge Function
 *
 * Calculates match scores between a player and all discoverable coaches,
 * then upserts results into player_coach_matches.
 *
 * Scoring weights (total = 100):
 *   Tactical   35%  — formation/position overlap
 *   Position   25%  — primary position need
 *   Physical   20%  — height, foot preference, athletic profile
 *   Academic   15%  — GPA and test score compatibility
 *   Timeline    5%  — graduation year vs. roster slot need
 *
 * Invoke: POST /functions/v1/match-players
 * Body: { player_id: string }
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Player {
  user_id: string
  primary_position_id: string | null
  secondary_position_id: string | null
  dominant_foot: string | null
  height_cm: string | null
  graduation_year: number | null
  gpa_unweighted: string | null
  sat_score: number | null
  act_score: number | null
  target_division: string | null
  is_discoverable: boolean
}

interface CoachRequirement {
  coach_id: string
  position_id: string
  required_qualities: string[]
  is_published: boolean
}

interface RosterSlot {
  coach_id: string
  position_id: string
  graduation_year: number | null
  slot_status: string
}

interface Coach {
  id: string
  user_id: string
  school_name: string | null
  division: string | null
  primary_formation_id: string | null
  recruiting_class_years: number[] | null
  requirements: CoachRequirement[]
  roster_slots: RosterSlot[]
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { player_id } = await req.json()
    if (!player_id) {
      return new Response(
        JSON.stringify({ error: 'player_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // 1. Load the player profile
    const { data: player, error: playerErr } = await supabase
      .from('players')
      .select('*')
      .eq('user_id', player_id)
      .single()

    if (playerErr || !player) {
      return new Response(
        JSON.stringify({ error: 'Player not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (!player.is_discoverable) {
      return new Response(
        JSON.stringify({ message: 'Player is not discoverable. No matches computed.' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // 2. Load all coaches with their requirements and roster slots
    const { data: coaches, error: coachErr } = await supabase
      .from('coaches')
      .select(`
        id,
        user_id,
        school_name,
        division,
        primary_formation_id,
        recruiting_class_years,
        coach_position_requirements!inner(
          position_id,
          required_qualities,
          is_published
        ),
        roster_slots(
          position_id,
          graduation_year,
          slot_status
        )
      `)
      .eq('coach_position_requirements.is_published', true)

    if (coachErr) {
      console.error('Error loading coaches:', coachErr)
      return new Response(
        JSON.stringify({ error: 'Failed to load coaches' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (!coaches || coaches.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No coaches with published requirements found', matches: 0 }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // 3. Score each coach
    const matches = []

    for (const coach of coaches as Coach[]) {
      const score = computeMatchScore(player as Player, coach)

      if (score.total >= 30) { // Only save meaningful matches
        matches.push({
          player_id: player.user_id,
          coach_id: coach.id,
          total_score: Math.round(score.total),
          tactical_score: Math.round(score.tactical),
          position_score: Math.round(score.position),
          physical_score: Math.round(score.physical),
          academic_score: Math.round(score.academic),
          timeline_score: Math.round(score.timeline),
          match_reasons: score.reasons,
          match_reasons_es: score.reasonsEs,
          last_computed_at: new Date().toISOString(),
        })
      }
    }

    // 4. Upsert all matches (service role bypasses RLS)
    if (matches.length > 0) {
      const { error: upsertErr } = await supabase
        .from('player_coach_matches')
        .upsert(matches, { onConflict: 'player_id,coach_id' })

      if (upsertErr) {
        console.error('Error upserting matches:', upsertErr)
        return new Response(
          JSON.stringify({ error: 'Failed to save matches' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        player_id,
        matches_computed: matches.length,
        top_score: matches.length > 0 ? Math.max(...matches.map(m => m.total_score)) : 0,
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

// ─── Scoring Functions ────────────────────────────────────────────────────────

interface ScoreBreakdown {
  total: number
  tactical: number
  position: number
  physical: number
  academic: number
  timeline: number
  reasons: string[]
  reasonsEs: string[]
}

function computeMatchScore(player: Player, coach: Coach): ScoreBreakdown {
  const reasons: string[] = []
  const reasonsEs: string[] = []

  // ── Tactical Score (35 pts) ─────────────────────────────────────────────
  let tactical = 0

  // Does coach have a requirement for the player's primary position?
  const primaryReq = coach.requirements?.find(
    r => r.position_id === player.primary_position_id
  )
  if (primaryReq) {
    tactical += 25
    reasons.push(`Needs a ${player.primary_position_id?.toUpperCase()} in their ${coach.primary_formation_id} system`)
    reasonsEs.push(`Necesita un ${player.primary_position_id?.toUpperCase()} en su sistema ${coach.primary_formation_id}`)
  }

  // Secondary position bonus
  if (player.secondary_position_id) {
    const secondaryReq = coach.requirements?.find(
      r => r.position_id === player.secondary_position_id
    )
    if (secondaryReq) {
      tactical += 10
      reasons.push(`Can also fill ${player.secondary_position_id?.toUpperCase()} as backup`)
      reasonsEs.push(`También puede cubrir ${player.secondary_position_id?.toUpperCase()} como alternativa`)
    }
  }

  tactical = Math.min(tactical, 35)

  // ── Position Score (25 pts) ─────────────────────────────────────────────
  let position = 0

  if (primaryReq) {
    // Does this position have an open roster slot?
    const openSlot = coach.roster_slots?.find(
      s => s.position_id === player.primary_position_id && s.slot_status === 'open'
    )
    if (openSlot) {
      position += 20
      reasons.push('Has an open roster slot for this position')
      reasonsEs.push('Tiene un lugar abierto en el plantel para esta posición')

      // Graduation year alignment
      if (openSlot.graduation_year && player.graduation_year) {
        const yearDiff = Math.abs(openSlot.graduation_year - player.graduation_year)
        if (yearDiff === 0) {
          position += 5
          reasons.push('Perfect graduation year match')
          reasonsEs.push('Año de graduación perfecto')
        } else if (yearDiff === 1) {
          position += 3
        }
      }
    } else {
      position += 8 // Still relevant even without open slot
    }
  }

  position = Math.min(position, 25)

  // ── Physical Score (20 pts) ─────────────────────────────────────────────
  // Simplified — in production, compare against coach's physical requirements
  let physical = 10 // Base score for having a profile

  if (player.dominant_foot) {
    physical += 5
  }
  if (player.height_cm) {
    physical += 5
  }

  physical = Math.min(physical, 20)

  // ── Academic Score (15 pts) ─────────────────────────────────────────────
  let academic = 0

  if (player.gpa_unweighted) {
    const gpa = parseGpaRange(player.gpa_unweighted)
    if (gpa >= 4.0) {
      academic = 15
      reasons.push('4.0 GPA — strong academic profile')
      reasonsEs.push('GPA 4.0 — perfil académico sobresaliente')
    } else if (gpa >= 3.5) {
      academic = 12
      reasons.push('3.5+ GPA — solid academics')
      reasonsEs.push('GPA 3.5+ — buenos resultados académicos')
    } else if (gpa >= 3.0) {
      academic = 9
    } else if (gpa >= 2.5) {
      academic = 6
    } else if (gpa >= 2.3) {
      academic = 3 // Meets NCAA D1 minimum
    }
  }

  // SAT/ACT bonus
  if (player.sat_score && player.sat_score >= 1200) {
    academic = Math.min(academic + 2, 15)
  }
  if (player.act_score && player.act_score >= 26) {
    academic = Math.min(academic + 2, 15)
  }

  academic = Math.min(academic, 15)

  // ── Timeline Score (5 pts) ──────────────────────────────────────────────
  let timeline = 0

  if (player.graduation_year && coach.recruiting_class_years) {
    if (coach.recruiting_class_years.includes(player.graduation_year)) {
      timeline = 5
      reasons.push(`Actively recruiting Class of ${player.graduation_year}`)
      reasonsEs.push(`Reclutando activamente la Clase de ${player.graduation_year}`)
    } else if (coach.recruiting_class_years.some(y => Math.abs(y - (player.graduation_year ?? 0)) === 1)) {
      timeline = 3
    }
  }

  // Division match bonus — included in academic consideration
  if (player.target_division && coach.division) {
    const divisionMatch = player.target_division.toLowerCase().includes(
      coach.division.toLowerCase().split(' ').pop() ?? ''
    )
    if (divisionMatch) {
      reasons.push(`Matches your target division (${coach.division})`)
      reasonsEs.push(`Coincide con tu división objetivo (${coach.division})`)
    }
  }

  const total = tactical + position + physical + academic + timeline

  return { total, tactical, position, physical, academic, timeline, reasons, reasonsEs }
}

function parseGpaRange(gpaStr: string): number {
  if (gpaStr.startsWith('4.0')) return 4.0
  if (gpaStr.startsWith('3.5')) return 3.5
  if (gpaStr.startsWith('3.0')) return 3.0
  if (gpaStr.startsWith('2.5')) return 2.5
  if (gpaStr.startsWith('2.0')) return 2.0
  return 0
}
