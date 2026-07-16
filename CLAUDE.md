# Lanista — Claude Code Project Context

## What This Is
Bilingual (EN/ES) college soccer recruiting platform connecting elite youth players (MLS Next, ECNL) with college coaches. Flutter + Supabase monorepo.

## Tech Stack
- **Mobile**: Flutter (iOS + Android), BLoC, GoRouter, GetIt
- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Edge Functions, Storage)
- **Services**: Firebase FCM (push), Mux (video), OpenAI GPT-4o, Twelve Labs
- **Removed** (do not re-add): `stripe_flutter`, `sentry_flutter` — caused iOS startup crash

## Project Structure
```
mobile/          Flutter app
  lib/
    features/    Feature modules by role: auth, player, coach, mentor, parent,
                 messaging, notifications, search, education
    core/        theme, router, di, widgets
supabase/
  migrations/    091 migrations applied (always use next number)
  functions/     7 edge functions: match-players, matching-engine,
                 video-analysis, roadmap-generator, notification-dispatch,
                 ncaa-compliance, stripe-webhooks (unused)
scripts/
  scrape-rosters/   NCAA roster scraper (Python, 100 schools)
  run-matching-engine.py   Run match-players for all players
dart_defines/
  dev.json       API keys — NOT in git, share separately
```

## Running the App
```bash
# iOS (simulator)
cd mobile && flutter run --dart-define-from-file=../dart_defines/dev.json

# iOS release build + install on device
flutter build ios --release --dart-define-from-file=../dart_defines/dev.json
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app

# Test devices
# iPhone 17 Pro Max: B55E6C4F-7BFD-51CB-AF03-67DCC53A6FC7
# iPad Air 13" M2:   01AE5E7C-9A0B-5B06-861B-79B0A84C79A8
```

## Database
- **91 migrations** in `supabase/migrations/` — always increment, never edit applied migrations
- Apply to prod: `npx supabase db push` (from project root)
- Key tables: `users`, `players`, `coaches`, `roster_slots`, `player_coach_matches`,
  `recruiting_pipeline`, `conversations`, `messages`, `player_videos`, `college_roster_players`

### Auth (test accounts)
- All 20 original coaches: `coach.NAME@lanista.test` / `Lanista2026!`
- Player (Jaylen Brooks, RB, 2028): `icarovazquez+jaylen@gmail.com`
- When manually inserting auth.users via SQL, always set:
  - `instance_id = '00000000-0000-0000-0000-000000000000'`
  - `auth.identities.provider_id` = UUID string (not email)
  - All token fields to `''` (not NULL)

## Key Conventions
- **Positions**: stored **lowercase** in DB (`rb`, `cb`, `gk`). Formation-specific variants
  used in `roster_slots` (`rcb`, `lcb`, `rcm`, `lcm`). Map via `_expandPosition()` in
  `player_openings_page.dart` when querying.
- **Coach side**: optimized for tablet layout (coaches are primary tablet users)
- **Player side**: permanently dark mode (`PlayerThemeMode.dark` on init)
- **Height display**: always show both metric + imperial — `"180 cm (5'11")"`
- `PlayerColors` at `mobile/lib/core/theme/player_colors.dart` — neon lime `#C8F135`

## Matching Engine
- Edge function: `match-players` — takes `{ player_id: user_id }`
- Run for all players: `python3 scripts/run-matching-engine.py`
- Run for one: `python3 scripts/run-matching-engine.py <user_id>`
- Stores in `player_coach_matches` (threshold: score ≥ 30)
- Coach must have `is_published = true` AND `coach_position_requirements` records

## Edge Functions
Deploy: `npx supabase functions deploy <function-name>`
Secrets set via: `npx supabase secrets set KEY=value`

## Supabase Env
- URL and anon key in `dart_defines/dev.json`
- Service role key in `scripts/scrape-rosters/.env`
- Supabase project ID: `yfyutdbxfwqajzsejenz`

## Common Pitfalls
- `needs_recruit` is a `GENERATED ALWAYS AS (STORED)` column — do not INSERT it
- `coach_position_requirements.is_published` must be `true` for the matching engine to score
- PostgREST `.eq('nested_table.column', val)` on `!inner` joins can silently return 0 rows —
  filter the parent table or filter in JS instead
- `analysis_result` lives on `player_videos`, not `players`
- `gender_program` constraint: `'male'` or `'female'` (not `'men'`/`'women'`)
