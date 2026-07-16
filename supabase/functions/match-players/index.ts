/**
 * Lanista Matching Engine — Supabase Edge Function
 *
 * Calculates match scores between a player and all discoverable coaches,
 * then upserts results into player_coach_matches.
 *
 * Scoring weights (total = 100):
 *   Tactical   35%  — formation/position overlap
 *   Position   25%  — primary position need + open roster slot
 *   Physical   20%  — height, foot preference, speed rating
 *   Academic   15%  — GPA and test score compatibility
 *   Timeline    5%  — graduation year vs. recruiting class years
 *
 * match_reasons    = things the player satisfies  (green hits)
 * match_gaps       = requirements the player misses (red gaps — the differentiator)
 * match_reasons_es / match_gaps_es = Spanish equivalents
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

// ── Interfaces ────────────────────────────────────────────────────────────────

interface Player {
  id: string
  user_id: string
  primary_position: string | null
  secondary_position: string | null
  dominant_foot: string | null
  height_cm: number | null
  weight_kg: number | null
  graduation_year: number | null
  date_of_birth: string | null
  gpa: number | null
  sat_score: number | null
  act_score: number | null
  speed_rating: number | null
  target_division: string | null
  is_discoverable: boolean
}

interface CoachPositionRequirement {
  position_key: string
  min_height_cm: number | null
  preferred_foot: string | null       // 'left' | 'right' | 'both' | 'any'
  min_speed_rating: number | null
  min_gpa: number | null
  min_age_years: number | null
  max_age_years: number | null
  min_physical_build: string | null   // 'any' | 'slight_ok' | 'athletic' | 'powerful'
  is_published: boolean
}

interface RosterSlot {
  position_key: string
  slot_status: string
  graduation_year: number | null
}

interface Coach {
  id: string
  school_name: string | null
  division: string | null
  primary_formation: string | null
  recruiting_class_years: number[] | null
  requirements: CoachPositionRequirement[]
  roster_slots: RosterSlot[]
}

// ── Serve ────────────────────────────────────────────────────────────────────

serve(async (req) => {
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

    // 1. Load player profile
    const { data: player, error: playerErr } = await supabase
      .from('players')
      .select('id, user_id, primary_position, secondary_position, dominant_foot, height_cm, weight_kg, graduation_year, date_of_birth, gpa, sat_score, act_score, speed_rating, target_division, is_discoverable')
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

    // 2. Load all coaches with published requirements + roster slots
    const { data: coaches, error: coachErr } = await supabase
      .from('coaches')
      .select(`
        id,
        school_name,
        division,
        primary_formation,
        recruiting_class_years,
        coach_position_requirements!inner(
          position_key,
          min_height_cm,
          preferred_foot,
          min_speed_rating,
          min_gpa,
          min_age_years,
          max_age_years,
          min_physical_build,
          is_published
        ),
        roster_slots(
          position_key,
          slot_status,
          graduation_year
        )
      `)
      .eq('is_published', true)

    if (coachErr || !coaches || coaches.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No coaches with published requirements found', matches: 0 }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // 3. Score each coach
    const matches = []

    for (const coach of coaches as Coach[]) {
      const score = computeMatchScore(player as Player, coach)
      if (score.total >= 30) {
        matches.push({
          player_id: player.id,
          coach_id: coach.id,
          total_score: Math.round(score.total),
          tactical_score: Math.round(score.tactical),
          position_score: Math.round(score.position),
          physical_score: Math.round(score.physical),
          academic_score: Math.round(score.academic),
          timeline_score: Math.round(score.timeline),
          match_reasons: score.reasons,
          match_reasons_es: score.reasonsEs,
          match_gaps: score.gaps,
          match_gaps_es: score.gapsEs,
          last_computed_at: new Date().toISOString(),
        })
      }
    }

    // 4. Upsert
    if (matches.length > 0) {
      const { error: upsertErr } = await supabase
        .from('player_coach_matches')
        .upsert(matches, { onConflict: 'player_id,coach_id' })

      if (upsertErr) {
        console.error('Upsert error:', upsertErr)
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

// ── Scoring ───────────────────────────────────────────────────────────────────

interface ScoreBreakdown {
  total: number
  tactical: number
  position: number
  physical: number
  academic: number
  timeline: number
  reasons: string[]    // hits — what the player satisfies
  reasonsEs: string[]
  gaps: string[]       // misses — what's holding the score down
  gapsEs: string[]
}

function computeMatchScore(player: Player, coach: Coach): ScoreBreakdown {
  const reasons: string[] = []
  const reasonsEs: string[] = []
  const gaps: string[] = []
  const gapsEs: string[] = []

  // Find the requirement for the player's primary position
  const primaryReq = coach.requirements?.find(
    r => r.position_key === player.primary_position && r.is_published
  )
  const secondaryReq = player.secondary_position
    ? coach.requirements?.find(r => r.position_key === player.secondary_position && r.is_published)
    : null

  // ── Tactical (35 pts) ─────────────────────────────────────────────────────
  let tactical = 0

  if (primaryReq) {
    tactical += 25
    reasons.push(`Needs a ${fmtPosition(player.primary_position)} in their ${coach.primary_formation ?? ''} system`)
    reasonsEs.push(`Necesita un ${fmtPosition(player.primary_position)} en su sistema ${coach.primary_formation ?? ''}`)
  } else {
    gaps.push(`No open ${fmtPosition(player.primary_position)} requirement in their system`)
    gapsEs.push(`No hay requisito abierto de ${fmtPosition(player.primary_position)} en su sistema`)
  }

  if (secondaryReq) {
    tactical += 10
    reasons.push(`Can also fill ${fmtPosition(player.secondary_position)} as needed`)
    reasonsEs.push(`También puede cubrir ${fmtPosition(player.secondary_position)} según sea necesario`)
  }

  tactical = Math.min(tactical, 35)

  // ── Position / Roster slot (25 pts) ───────────────────────────────────────
  let position = 0

  if (primaryReq) {
    const openSlot = coach.roster_slots?.find(
      s => s.position_key === player.primary_position && s.slot_status === 'open'
    )
    if (openSlot) {
      position += 20
      reasons.push(`Has an open roster slot for ${fmtPosition(player.primary_position)}`)
      reasonsEs.push(`Tiene un lugar abierto en el plantel para ${fmtPosition(player.primary_position)}`)

      if (openSlot.graduation_year && player.graduation_year) {
        const diff = Math.abs(openSlot.graduation_year - player.graduation_year)
        if (diff === 0) {
          position += 5
          reasons.push(`Roster slot opens your graduation year (${player.graduation_year})`)
          reasonsEs.push(`El lugar del plantel abre tu año de graduación (${player.graduation_year})`)
        } else if (diff === 1) {
          position += 3
        }
      }
    } else {
      position += 8 // position is relevant even without an open slot
      gaps.push(`No open roster slot right now — monitoring for future need`)
      gapsEs.push(`Sin lugar disponible ahora — monitoreando necesidades futuras`)
    }
  }

  position = Math.min(position, 25)

  // ── Physical (20 pts) ─────────────────────────────────────────────────────
  let physical = 0

  if (primaryReq) {
    // Height
    if (primaryReq.min_height_cm) {
      const playerHeight = player.height_cm ?? 0
      if (playerHeight >= primaryReq.min_height_cm) {
        physical += 7
        reasons.push(`Meets height requirement (${fmtHeight(playerHeight)} ≥ ${fmtHeight(primaryReq.min_height_cm)} min)`)
        reasonsEs.push(`Cumple el requisito de altura (${fmtHeight(playerHeight)} ≥ ${fmtHeight(primaryReq.min_height_cm)} mín)`)
      } else if (playerHeight > 0) {
        const diff = primaryReq.min_height_cm - playerHeight
        gaps.push(`Height ${fmtHeight(playerHeight)} is ${diff} cm below their ${fmtHeight(primaryReq.min_height_cm)} minimum`)
        gapsEs.push(`Altura ${fmtHeight(playerHeight)} está ${diff} cm por debajo del mínimo de ${fmtHeight(primaryReq.min_height_cm)}`)
      } else {
        gaps.push(`Height not set on your profile — required minimum is ${fmtHeight(primaryReq.min_height_cm)}`)
        gapsEs.push(`Altura no configurada en tu perfil — el mínimo requerido es ${fmtHeight(primaryReq.min_height_cm)}`)
      }
    } else {
      physical += 7 // no height requirement set — no penalty
    }

    // Dominant foot
    if (primaryReq.preferred_foot && primaryReq.preferred_foot !== 'any') {
      const foot = player.dominant_foot
      const req = primaryReq.preferred_foot
      const footMatch = req === 'both' || foot === req || foot === 'both'
      if (footMatch) {
        physical += 5
        reasons.push(`Foot preference matches (${fmtFoot(foot)} / coach wants ${fmtFoot(req)})`)
        reasonsEs.push(`Preferencia de pie coincide (${fmtFootEs(foot)} / el entrenador quiere ${fmtFootEs(req)})`)
      } else if (foot) {
        gaps.push(`Foot preference: you are ${fmtFoot(foot)}, coach prefers ${fmtFoot(req)}`)
        gapsEs.push(`Preferencia de pie: eres ${fmtFootEs(foot)}, el entrenador prefiere ${fmtFootEs(req)}`)
      } else {
        gaps.push(`Dominant foot not set — coach prefers ${fmtFoot(req)}`)
        gapsEs.push(`Pie dominante no configurado — el entrenador prefiere ${fmtFootEs(req)}`)
      }
    } else {
      physical += 5 // no foot requirement — no penalty
    }

    // Speed rating
    if (primaryReq.min_speed_rating) {
      const playerSpeed = player.speed_rating ?? 0
      if (playerSpeed >= primaryReq.min_speed_rating) {
        physical += 8
        reasons.push(`Speed rating ${playerSpeed}/10 meets their minimum of ${primaryReq.min_speed_rating}/10`)
        reasonsEs.push(`Calificación de velocidad ${playerSpeed}/10 cumple su mínimo de ${primaryReq.min_speed_rating}/10`)
      } else if (playerSpeed > 0) {
        gaps.push(`Speed rating ${playerSpeed}/10 is below their minimum of ${primaryReq.min_speed_rating}/10`)
        gapsEs.push(`Calificación de velocidad ${playerSpeed}/10 está por debajo del mínimo de ${primaryReq.min_speed_rating}/10`)
      } else {
        gaps.push(`Speed rating not set — required minimum is ${primaryReq.min_speed_rating}/10`)
        gapsEs.push(`Calificación de velocidad no configurada — el mínimo requerido es ${primaryReq.min_speed_rating}/10`)
      }
    } else {
      physical += 8 // no speed requirement
    }

    // Physical build (height + weight → BMI-based category)
    const buildReq = primaryReq.min_physical_build ?? 'any'
    if (buildReq !== 'any') {
      const playerBuild = computeBuildCategory(player.height_cm, player.weight_kg)
      if (playerBuild === null) {
        gaps.push(`Height or weight not set — coach requires at least ${fmtBuild(buildReq)} build`)
        gapsEs.push(`Altura o peso no configurados — el entrenador requiere al menos complexión ${fmtBuildEs(buildReq)}`)
      } else {
        const buildOrder = ['slight', 'athletic', 'powerful']
        const playerIdx = buildOrder.indexOf(playerBuild)
        const reqIdx = buildOrder.indexOf(buildReq === 'slight_ok' ? 'slight' : buildReq)
        if (playerIdx >= reqIdx) {
          reasons.push(`Physical build (${fmtBuild(playerBuild)}) meets their ${fmtBuild(buildReq)} requirement`)
          reasonsEs.push(`Complexión física (${fmtBuildEs(playerBuild)}) cumple el requisito de ${fmtBuildEs(buildReq)}`)
        } else {
          gaps.push(`Physical build (${fmtBuild(playerBuild)}) is below their ${fmtBuild(buildReq)} minimum — may be pushed off the ball`)
          gapsEs.push(`Complexión física (${fmtBuildEs(playerBuild)}) está por debajo del mínimo de ${fmtBuildEs(buildReq)} — puede ser desplazado en el juego físico`)
        }
      }
    }

    // Age
    if (primaryReq.min_age_years || primaryReq.max_age_years) {
      const age = playerAge(player.date_of_birth)
      if (age !== null) {
        const aboveMin = !primaryReq.min_age_years || age >= primaryReq.min_age_years
        const belowMax = !primaryReq.max_age_years || age <= primaryReq.max_age_years
        if (aboveMin && belowMax) {
          // age is fine — no reason needed, just no penalty
        } else if (!aboveMin) {
          gaps.push(`Age ${age} is below their minimum of ${primaryReq.min_age_years}`)
          gapsEs.push(`Edad ${age} está por debajo del mínimo de ${primaryReq.min_age_years}`)
        } else {
          gaps.push(`Age ${age} is above their maximum of ${primaryReq.max_age_years}`)
          gapsEs.push(`Edad ${age} está por encima del máximo de ${primaryReq.max_age_years}`)
        }
      }
    }
  } else {
    // No requirement found for this position — give baseline physical score
    physical = 14
  }

  physical = Math.min(physical, 20)

  // ── Academic (15 pts) ─────────────────────────────────────────────────────
  let academic = 0
  const playerGpa = player.gpa ?? null

  if (primaryReq?.min_gpa && primaryReq.min_gpa > 0) {
    if (playerGpa !== null) {
      if (playerGpa >= primaryReq.min_gpa) {
        academic += 12
        reasons.push(`GPA ${playerGpa.toFixed(1)} meets their ${primaryReq.min_gpa.toFixed(1)} minimum`)
        reasonsEs.push(`GPA ${playerGpa.toFixed(1)} cumple su mínimo de ${primaryReq.min_gpa.toFixed(1)}`)
        // Bonus for strong GPA
        if (playerGpa >= 3.8) {
          academic += 3
          reasons.push(`Exceptional GPA (${playerGpa.toFixed(1)}) — a recruiting advantage`)
          reasonsEs.push(`GPA excepcional (${playerGpa.toFixed(1)}) — ventaja en el reclutamiento`)
        }
      } else {
        const diff = (primaryReq.min_gpa - playerGpa).toFixed(1)
        gaps.push(`GPA ${playerGpa.toFixed(1)} is ${diff} below their ${primaryReq.min_gpa.toFixed(1)} minimum`)
        gapsEs.push(`GPA ${playerGpa.toFixed(1)} está ${diff} puntos por debajo del mínimo de ${primaryReq.min_gpa.toFixed(1)}`)
        // Partial credit if close
        if (playerGpa >= primaryReq.min_gpa - 0.3) {
          academic += 5
        }
      }
    } else {
      gaps.push(`GPA not set on your profile — required minimum is ${primaryReq.min_gpa.toFixed(1)}`)
      gapsEs.push(`GPA no configurado en tu perfil — el mínimo requerido es ${primaryReq.min_gpa.toFixed(1)}`)
    }
  } else {
    // No GPA requirement — score based on player's GPA alone
    if (playerGpa !== null) {
      if (playerGpa >= 3.8) { academic = 15; reasons.push(`Exceptional GPA (${playerGpa.toFixed(1)})`); reasonsEs.push(`GPA excepcional (${playerGpa.toFixed(1)})`) }
      else if (playerGpa >= 3.5) { academic = 12; reasons.push(`Strong GPA (${playerGpa.toFixed(1)})`); reasonsEs.push(`Buen GPA (${playerGpa.toFixed(1)})`) }
      else if (playerGpa >= 3.0) { academic = 9 }
      else if (playerGpa >= 2.5) { academic = 6 }
      else if (playerGpa >= 2.3) { academic = 3 }
    }
  }

  // SAT / ACT bonus (up to 3 pts)
  if (player.sat_score && player.sat_score >= 1200) {
    academic = Math.min(academic + 2, 15)
    reasons.push(`SAT ${player.sat_score} — strong academic profile`)
    reasonsEs.push(`SAT ${player.sat_score} — perfil académico sólido`)
  }
  if (player.act_score && player.act_score >= 26) {
    academic = Math.min(academic + 2, 15)
  }

  academic = Math.min(academic, 15)

  // ── Timeline (5 pts) ──────────────────────────────────────────────────────
  let timeline = 0

  if (player.graduation_year && coach.recruiting_class_years) {
    const years = coach.recruiting_class_years.map(Number)
    if (years.includes(player.graduation_year)) {
      timeline = 5
      reasons.push(`Actively recruiting Class of ${player.graduation_year}`)
      reasonsEs.push(`Reclutando activamente la Clase de ${player.graduation_year}`)
    } else if (years.some(y => Math.abs(y - player.graduation_year!) === 1)) {
      timeline = 3
    } else if (player.graduation_year) {
      gaps.push(`Not currently recruiting your graduation year (${player.graduation_year})`)
      gapsEs.push(`No está reclutando actualmente tu año de graduación (${player.graduation_year})`)
    }
  }

  // Division match bonus
  if (player.target_division && coach.division) {
    const divMatch = coach.division.toLowerCase().includes(
      player.target_division.toLowerCase().replace('d', '')
    )
    if (divMatch) {
      reasons.push(`Matches your target division (${coach.division})`)
      reasonsEs.push(`Coincide con tu división objetivo (${coach.division})`)
    }
  }

  const total = tactical + position + physical + academic + timeline

  return { total, tactical, position, physical, academic, timeline, reasons, reasonsEs, gaps, gapsEs }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function fmtPosition(pos: string | null): string {
  return pos?.toUpperCase() ?? 'your position'
}

function fmtHeight(cm: number): string {
  const totalInches = Math.round(cm / 2.54)
  const feet = Math.floor(totalInches / 12)
  const inches = totalInches % 12
  return `${cm} cm (${feet}'${inches}")`
}

function fmtFoot(foot: string | null): string {
  if (!foot) return 'unspecified'
  return foot.charAt(0).toUpperCase() + foot.slice(1)
}

function fmtFootEs(foot: string | null): string {
  const map: Record<string, string> = { left: 'zurdo', right: 'diestro', both: 'ambidiestro' }
  return foot ? (map[foot] ?? foot) : 'no especificado'
}

function playerAge(dob: string | null): number | null {
  if (!dob) return null
  const birth = new Date(dob)
  const today = new Date()
  let age = today.getFullYear() - birth.getFullYear()
  const m = today.getMonth() - birth.getMonth()
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--
  return age
}

// Build category thresholds use athlete-adjusted BMI ranges:
//   Slight:   BMI < 21   — lean, can be pushed off the ball
//   Athletic: BMI 21–25  — ideal proportion for most positions
//   Powerful: BMI > 25   — strong physical presence
function computeBuildCategory(height_cm: number | null, weight_kg: number | null): 'slight' | 'athletic' | 'powerful' | null {
  if (!height_cm || !weight_kg || height_cm <= 0 || weight_kg <= 0) return null
  const heightM = height_cm / 100
  const bmi = weight_kg / (heightM * heightM)
  if (bmi >= 25) return 'powerful'
  if (bmi >= 21) return 'athletic'
  return 'slight'
}

function fmtBuild(build: string): string {
  const map: Record<string, string> = {
    slight: 'Slight', athletic: 'Athletic', powerful: 'Powerful',
    slight_ok: 'Slight or above', any: 'Any',
  }
  return map[build] ?? build
}

function fmtBuildEs(build: string): string {
  const map: Record<string, string> = {
    slight: 'liviana', athletic: 'atlética', powerful: 'robusta',
    slight_ok: 'liviana o superior', any: 'cualquiera',
  }
  return map[build] ?? build
}
