import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const TWELVE_LABS_API = 'https://api.twelvelabs.io/v1.3';
const INDEX_NAME = 'lanista-player-videos';
const TL_KEY = Deno.env.get('TWELVE_LABS_API_KEY')!;
const OPENAI_KEY = Deno.env.get('OPENAI_API_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ── YouTube helpers ──────────────────────────────────────────────────────────

function extractYouTubeId(url: string): string | null {
  const patterns = [
    /[?&]v=([^&#]+)/,
    /youtu\.be\/([^?&#]+)/,
    /youtube\.com\/embed\/([^?&#]+)/,
  ];
  for (const p of patterns) {
    const m = url.match(p);
    if (m) return m[1];
  }
  return null;
}

async function analyzeWithOpenAI(videoId: string, title: string): Promise<Record<string, unknown>> {
  // YouTube exposes 4 sampled frames + high-res thumbnail for every video
  const frameUrls = [
    `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`,
    `https://img.youtube.com/vi/${videoId}/0.jpg`,
    `https://img.youtube.com/vi/${videoId}/1.jpg`,
    `https://img.youtube.com/vi/${videoId}/2.jpg`,
    `https://img.youtube.com/vi/${videoId}/3.jpg`,
  ];

  const imageContent = frameUrls.map(url => ({
    type: 'image_url',
    image_url: { url, detail: 'high' },
  }));

  const prompt = `You are an expert college soccer scout analyzing frames from a player's highlight video titled: "${title}".

You are seeing the main thumbnail and 4 sampled frames from the video.

Based on what you can observe in these frames, provide a JSON object with exactly these fields:
{
  "summary": "2-3 sentence overall assessment of this player based on what is visible",
  "dominant_foot": "right" | "left" | "both" | "unknown",
  "primary_position": "e.g. Center Back, Striker, Midfielder, etc. — infer from video positioning",
  "playing_style": "1-2 sentence description of how this player appears to play",
  "skills_detected": ["list of skills you can observe: pace, dribbling, heading, 1v1, vision, finishing, crossing, pressing, positioning, etc."],
  "strengths": ["2-4 bullet point strengths with specific references to what you observe"],
  "areas_for_improvement": ["1-2 areas (be honest but constructive)"],
  "college_level_projection": "D1" | "D2" | "D3" | "NAIA" | "JUCO" | "unknown",
  "scout_rating": a number between 1 and 10,
  "analysis_note": "Brief note explaining this analysis is based on video frames, not full video"
}

Only describe what you can actually see. If frames are unclear, note that in your assessment.`;

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      max_tokens: 1200,
      messages: [{
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          ...imageContent,
        ],
      }],
    }),
  });

  if (!res.ok) throw new Error(`OpenAI error: ${res.status} ${await res.text()}`);
  const data = await res.json();
  const text: string = data.choices?.[0]?.message?.content ?? '';

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error('No JSON in OpenAI response');
  return JSON.parse(jsonMatch[0]);
}

// ── Twelve Labs helpers (for direct video URLs) ──────────────────────────────

async function tlFetch(path: string, method = 'GET', body?: unknown) {
  const res = await fetch(`${TWELVE_LABS_API}${path}`, {
    method,
    headers: { 'x-api-key': TL_KEY, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Twelve Labs ${method} ${path} → ${res.status}: ${text}`);
  }
  return res.json();
}

async function getOrCreateIndex(): Promise<string> {
  const { data } = await tlFetch('/indexes?page_limit=50');
  const existing = (data as any[]).find((i: any) => i.index_name === INDEX_NAME);
  if (existing) return existing._id;

  const created = await tlFetch('/indexes', 'POST', {
    index_name: INDEX_NAME,
    models: [{ model_name: 'pegasus1.2', model_options: ['visual', 'audio'] }],
  });
  return created._id;
}

async function analyzeWithTwelveLabs(directUrl: string): Promise<Record<string, unknown>> {
  const indexId = await getOrCreateIndex();

  const form = new FormData();
  form.append('index_id', indexId);
  form.append('video_url', directUrl);

  const taskRes = await fetch(`${TWELVE_LABS_API}/tasks`, {
    method: 'POST',
    headers: { 'x-api-key': TL_KEY },
    body: form,
  });
  if (!taskRes.ok) throw new Error(`TL tasks: ${taskRes.status} ${await taskRes.text()}`);
  const task = await taskRes.json();
  const taskId = task._id;

  // Poll for completion (max 5 min)
  const start = Date.now();
  let videoId: string | null = null;
  while (Date.now() - start < 300_000) {
    const t = await tlFetch(`/tasks/${taskId}`);
    if (t.status === 'ready') { videoId = t.video_id; break; }
    if (t.status === 'failed') throw new Error(`TL indexing failed: ${t.error}`);
    await new Promise(r => setTimeout(r, 5000));
  }
  if (!videoId) throw new Error('Twelve Labs indexing timed out');

  const prompt = `You are an expert college soccer scout. Analyze this player's video and return a JSON object:
{
  "summary": "2-3 sentence overall assessment",
  "dominant_foot": "right"|"left"|"both",
  "primary_position": "position name",
  "playing_style": "1-2 sentence description",
  "skills_detected": ["pace","dribbling","heading",...],
  "strengths": ["specific strength 1","strength 2",...],
  "areas_for_improvement": ["area 1","area 2"],
  "college_level_projection": "D1"|"D2"|"D3"|"NAIA"|"JUCO",
  "scout_rating": number 1-10
}`;

  const genRes = await tlFetch('/generate/text', 'POST', { video_id: videoId, prompt });
  const text: string = genRes.data ?? genRes.text ?? '';
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) throw new Error('No JSON in Twelve Labs response');
  return JSON.parse(jsonMatch[0]);
}

// ── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  let videoId: string | null = null;

  try {
    const body = await req.json();
    videoId = body.video_id;
    if (!videoId) return new Response(JSON.stringify({ error: 'video_id required' }), { status: 400, headers: corsHeaders });

    const { data: video, error: videoErr } = await supabase
      .from('player_videos')
      .select('id, external_url, title')
      .eq('id', videoId)
      .single();

    if (videoErr || !video?.external_url) {
      return new Response(JSON.stringify({ error: 'Video not found or missing URL' }), { status: 404, headers: corsHeaders });
    }

    await supabase.from('player_videos').update({ analysis_status: 'processing' }).eq('id', videoId);

    const url: string = video.external_url;
    const title: string = video.title ?? 'Player Highlight';
    const ytId = extractYouTubeId(url);
    let analysis: Record<string, unknown>;

    if (ytId) {
      // YouTube URL → use GPT-4o Vision with sampled frames
      analysis = await analyzeWithOpenAI(ytId, title);
      analysis.engine = 'openai-gpt4o-vision';
    } else {
      // Direct video URL → use Twelve Labs Pegasus
      analysis = await analyzeWithTwelveLabs(url);
      analysis.engine = 'twelve-labs-pegasus';
    }

    analysis.analyzed_at = new Date().toISOString();

    await supabase
      .from('player_videos')
      .update({ analysis_status: 'complete', analysis_result: analysis })
      .eq('id', videoId);

    return new Response(JSON.stringify({ success: true, analysis }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('video-analysis error:', err);
    if (videoId) {
      await supabase.from('player_videos').update({ analysis_status: 'failed' }).eq('id', videoId);
    }
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
