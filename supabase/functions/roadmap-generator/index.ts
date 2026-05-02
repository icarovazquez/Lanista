import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const openAiKey = Deno.env.get('OPENAI_API_KEY')!;

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Use service role client (no user-JWT global header) — same pattern as match-players.
    // getUser(token) validates the JWT explicitly without needing it on the client.
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get authenticated user
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized', detail: authError?.message }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── 1. Fetch player profile ──────────────────────────────────────────────
    const { data: player, error: playerError } = await supabase
      .from('players')
      .select(`
        id, grade, graduation_year, height_cm, gpa, sat_score, act_score,
        target_division, dominant_foot, bio,
        player_positions(is_primary, positions(name, abbreviation))
      `)
      .eq('user_id', user.id)
      .single();

    if (playerError || !player) {
      return new Response(JSON.stringify({ error: 'Player profile not found' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Extract primary position
    const primaryPositionRow = (player.player_positions as any[])?.find((p: any) => p.is_primary);
    const positionName = primaryPositionRow?.positions?.name ?? 'Unknown';
    const positionAbbr = primaryPositionRow?.positions?.abbreviation ?? '';

    // ── 2. Fetch coach preferences for this position ─────────────────────────
    const { data: coachPrefs } = await supabase
      .from('coach_position_requirements')
      .select('min_height_cm, preferred_foot, min_speed_rating, required_qualities')
      .eq('position_key', positionAbbr.toLowerCase());

    // Aggregate coach prefs
    let avgMinHeight: number | null = null;
    let footCounts: Record<string, number> = {};
    let allQualities: string[] = [];

    if (coachPrefs && coachPrefs.length > 0) {
      const heights = coachPrefs
        .map((p: any) => p.min_height_cm)
        .filter((h: any) => h != null) as number[];
      if (heights.length > 0) {
        avgMinHeight = Math.round(heights.reduce((a, b) => a + b, 0) / heights.length);
      }

      for (const pref of coachPrefs) {
        const foot = pref.preferred_foot ?? 'any';
        footCounts[foot] = (footCounts[foot] ?? 0) + 1;
        if (Array.isArray(pref.required_qualities)) {
          allQualities.push(...pref.required_qualities);
        }
      }
    }

    // Top qualities by frequency
    const qualityFreq: Record<string, number> = {};
    for (const q of allQualities) {
      qualityFreq[q] = (qualityFreq[q] ?? 0) + 1;
    }
    const topQualities = Object.entries(qualityFreq)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([q]) => q);

    const dominantFoot = Object.entries(footCounts).sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'any';

    // Coach GPA min
    const { data: coachGpaData } = await supabase
      .from('coaches')
      .select('min_gpa')
      .not('min_gpa', 'is', null);
    const gpaValues = (coachGpaData ?? []).map((c: any) => c.min_gpa).filter((g: any) => g != null);
    const avgMinGpa = gpaValues.length > 0
      ? (gpaValues.reduce((a: number, b: number) => a + b, 0) / gpaValues.length).toFixed(2)
      : null;

    // ── 3. Compute gaps ───────────────────────────────────────────────────────
    const gaps: string[] = [];
    const playerHeightCm = player.height_cm ?? null;
    if (avgMinHeight && playerHeightCm && playerHeightCm < avgMinHeight) {
      const diffCm = avgMinHeight - playerHeightCm;
      const diffIn = Math.round(diffCm / 2.54);
      gaps.push(
        `Player height (${playerHeightCm}cm / ${Math.floor(playerHeightCm / 30.48)}\'${Math.round((playerHeightCm % 30.48) / 2.54)}\") is ${diffCm}cm (${diffIn} inches) below the average minimum height (${avgMinHeight}cm) that coaches require for ${positionName}`
      );
    }
    if (avgMinGpa && player.gpa && parseFloat(player.gpa) < parseFloat(avgMinGpa)) {
      gaps.push(
        `Player GPA (${player.gpa}) is below the average minimum GPA coaches require (${avgMinGpa})`
      );
    }
    if (dominantFoot !== 'any' && player.dominant_foot && player.dominant_foot !== dominantFoot && dominantFoot !== 'both') {
      gaps.push(
        `Most coaches prefer ${dominantFoot}-footed players for ${positionName}; player is ${player.dominant_foot}-footed`
      );
    }

    const currentGrade = player.grade ?? 8;
    const targetDivision = player.target_division ?? 'D1';

    // Build the list of grades to cover (9 through 12, starting from current grade)
    const startGrade = Math.max(currentGrade, 9);
    const gradesToCover: number[] = [];
    for (let g = startGrade; g <= 12; g++) gradesToCover.push(g);
    const gradeListStr = gradesToCover.join(', ');

    // Build example JSON showing the expected multi-grade structure
    const exampleAcademic = gradesToCover.flatMap(g => [
      `    { "grade": ${g}, "title": "Example milestone A", "description": "Specific action for grade ${g}" }`,
      `    { "grade": ${g}, "title": "Example milestone B", "description": "Another action for grade ${g}" }`,
      `    { "grade": ${g}, "title": "Example milestone C", "description": "Third action for grade ${g}" }`,
    ]).join(',\n');

    // ── 4. Build GPT-4o prompt ────────────────────────────────────────────────
    const prompt = `You are an expert college soccer recruiting advisor in the United States. Generate a detailed, personalized recruiting roadmap for the following player.

PLAYER PROFILE:
- Position: ${positionName} (${positionAbbr})
- Current Grade: ${currentGrade}
- Graduation Year: ${player.graduation_year ?? 'Unknown'}
- Height: ${playerHeightCm ? `${playerHeightCm}cm (${Math.floor(playerHeightCm / 30.48)}'${Math.round((playerHeightCm % 30.48) / 2.54)}")` : 'Unknown'}
- GPA: ${player.gpa ?? 'Unknown'}
- SAT: ${player.sat_score ?? 'Not taken yet'}
- ACT: ${player.act_score ?? 'Not taken yet'}
- Target Division: ${targetDivision}
- Dominant Foot: ${player.dominant_foot ?? 'Unknown'}

REAL COACH DATA FOR ${positionName.toUpperCase()} AT ${targetDivision} LEVEL:
- Average minimum height coaches require: ${avgMinHeight ? `${avgMinHeight}cm` : 'No data'}
- Most valued qualities coaches look for: ${topQualities.length > 0 ? topQualities.join(', ') : 'No data'}
- Average minimum GPA coaches require: ${avgMinGpa ?? 'No data'}
- Preferred foot most coaches want: ${dominantFoot}

IDENTIFIED GAPS (areas where player falls short of coach expectations):
${gaps.length > 0 ? gaps.map(g => `- ${g}`).join('\n') : '- No significant gaps identified'}

INSTRUCTIONS:
You MUST generate milestones for ALL of the following grades: ${gradeListStr}.
Do NOT skip any grade. Every grade listed above MUST have exactly 3 milestones in EACH of the 4 categories (academic, conditioning, strength, skills).
This means the total milestone count will be: ${gradesToCover.length} grades × 4 categories × 3 milestones = ${gradesToCover.length * 12} milestones minimum.

Make every milestone highly specific to the player's position (${positionName}), identified gaps, and target division (${targetDivision}).
Milestones should show clear progression year-over-year (early grades = foundation, later grades = showcase/commitment).
For target schools, suggest realistic options based on the player's current profile and target division.

Return ONLY valid JSON with this exact structure (notice milestones span ALL grades ${gradeListStr}):
{
  "target_schools": [
    { "name": "School Name", "division": "D1", "bucket": "reach", "notes": "Why this school fits" },
    { "name": "School Name", "division": "D1", "bucket": "target", "notes": "Why this school fits" },
    { "name": "School Name", "division": "D2", "bucket": "safety", "notes": "Why this school fits" }
  ],
  "academic": [
${exampleAcademic}
  ],
  "conditioning": [
${exampleAcademic}
  ],
  "strength": [
${exampleAcademic}
  ],
  "skills": [
${exampleAcademic}
  ]
}

CRITICAL REQUIREMENTS:
1. Include 5-8 target schools (mix of reach/target/safety across ${targetDivision} and adjacent divisions).
2. Include EXACTLY 3 milestones per grade per category — for grades ${gradeListStr}.
3. Each milestone must have a specific, actionable title and description (not generic).
4. Milestones in later grades must directly build on earlier grades (show progression).
5. Milestones must directly address the identified gaps above.`;

    // ── 5. Call OpenAI GPT-4o ─────────────────────────────────────────────────
    const openAiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openAiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: 'You are a college soccer recruiting expert. Always respond with valid JSON only, no markdown, no code blocks.' },
          { role: 'user', content: prompt },
        ],
        temperature: 0.7,
        max_tokens: 8000,
      }),
    });

    if (!openAiResponse.ok) {
      const errText = await openAiResponse.text();
      return new Response(JSON.stringify({ error: `OpenAI error: ${errText}` }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const aiData = await openAiResponse.json();
    const rawContent = aiData.choices[0].message.content;

    let roadmapJson: any;
    try {
      roadmapJson = JSON.parse(rawContent);
    } catch {
      // Try stripping markdown code blocks if GPT added them
      const stripped = rawContent.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      roadmapJson = JSON.parse(stripped);
    }

    // ── 6. Upsert roadmap into DB ─────────────────────────────────────────────
    // Upsert player_roadmaps
    const { data: roadmap, error: roadmapError } = await supabase
      .from('player_roadmaps')
      .upsert(
        { player_id: player.id, generated_at: new Date().toISOString(), raw_ai_response: roadmapJson },
        { onConflict: 'player_id' }
      )
      .select('id')
      .single();

    if (roadmapError || !roadmap) {
      return new Response(JSON.stringify({ error: `DB error: ${roadmapError?.message}` }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const roadmapId = roadmap.id;

    // Delete old schools and milestones before re-inserting
    await supabase.from('roadmap_target_schools').delete().eq('roadmap_id', roadmapId);
    await supabase.from('roadmap_milestones').delete().eq('roadmap_id', roadmapId);

    // Insert target schools
    const schools = (roadmapJson.target_schools ?? []).map((s: any, i: number) => ({
      roadmap_id: roadmapId,
      school_name: s.name,
      division: s.division,
      bucket: s.bucket,
      notes: s.notes,
      order_index: i,
    }));
    if (schools.length > 0) {
      await supabase.from('roadmap_target_schools').insert(schools);
    }

    // Insert milestones for all 4 categories
    const milestones: any[] = [];
    let idx = 0;
    for (const category of ['academic', 'conditioning', 'strength', 'skills'] as const) {
      const items = roadmapJson[category] ?? [];
      for (const item of items) {
        milestones.push({
          roadmap_id: roadmapId,
          category,
          grade: item.grade,
          title: item.title,
          description: item.description,
          is_completed: false,
          order_index: idx++,
        });
      }
    }
    if (milestones.length > 0) {
      await supabase.from('roadmap_milestones').insert(milestones);
    }

    // ── 7. Return full roadmap ────────────────────────────────────────────────
    const { data: finalSchools } = await supabase
      .from('roadmap_target_schools')
      .select('*')
      .eq('roadmap_id', roadmapId)
      .order('order_index');

    const { data: finalMilestones } = await supabase
      .from('roadmap_milestones')
      .select('*')
      .eq('roadmap_id', roadmapId)
      .order('grade')
      .order('order_index');

    return new Response(
      JSON.stringify({
        roadmap_id: roadmapId,
        gaps,
        target_schools: finalSchools ?? [],
        milestones: finalMilestones ?? [],
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
