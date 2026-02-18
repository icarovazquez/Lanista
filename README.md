# Lanista

> Connecting elite youth soccer players with college coaches.

Lanista is a bilingual (English/Spanish) discovery platform for college soccer recruiting. Players find programs that fit their tactical profile; coaches find recruits that match their system of play.

## Monorepo Structure

```
lanista/
├── mobile/          # Flutter app (iOS, Android, Web)
├── supabase/        # Database migrations, Edge Functions, seed data
└── docs/            # Product spec, architecture docs
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.41+ (Dart) |
| Backend | Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions) |
| State Management | BLoC pattern (flutter_bloc) |
| Navigation | GoRouter |
| Payments | Stripe |
| Video | Mux + Chewie |
| AI/Matching | OpenAI GPT-4o + Twelve Labs |
| Analytics | PostHog |
| Error Tracking | Sentry |
| Hosting | Vercel (web) |
| CI/CD | GitHub Actions + Fastlane |

## Getting Started

### Prerequisites

- Flutter 3.41+ (`flutter --version`)
- Dart 3.0+
- Supabase CLI (`brew install supabase/tap/supabase`)
- A Supabase project (create at [supabase.com](https://supabase.com))

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/YOUR_ORG/lanista.git
   cd lanista
   ```

2. **Install Flutter dependencies**
   ```bash
   cd mobile
   flutter pub get
   ```

3. **Configure environment variables**

   Create `dart_defines/dev.json`:
   ```json
   {
     "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
     "SUPABASE_ANON_KEY": "your-anon-key",
     "ENVIRONMENT": "development"
   }
   ```

4. **Run the app**
   ```bash
   flutter run --dart-define-from-file=dart_defines/dev.json
   ```

5. **Run Supabase locally (optional)**
   ```bash
   cd supabase
   supabase start
   supabase db reset  # Applies migrations + seed data
   ```

## Project Structure (Flutter)

```
mobile/lib/
├── app.dart                          # Root widget
├── main.dart                         # Entry point
├── core/
│   ├── config/app_config.dart        # Env vars
│   ├── theme/                        # Colors, typography, Material theme
│   ├── router/app_router.dart        # GoRouter routes
│   ├── di/injection.dart             # GetIt dependency injection
│   └── localization/                 # EN/ES strings
├── features/
│   ├── auth/                         # Login, register, role selection, splash
│   ├── player/
│   │   ├── profile/                  # Dashboard, profile setup wizard
│   │   ├── roadmap/                  # Development roadmap
│   │   └── matches/                  # Program matches
│   ├── coach/
│   │   ├── roster_map/               # Coach dashboard
│   │   └── tactical_blueprint/       # Formation + position requirements setup
│   ├── parent/companion/             # Parent companion mode
│   └── mentor/dashboard/             # Mentor dashboard
└── shared/
    ├── models/                       # AppUser, UserRole
    └── widgets/                      # Shared UI components
```

## Database

Supabase migrations are in `supabase/migrations/`:

| Migration | Description |
|-----------|-------------|
| 001 | Extensions & custom enums |
| 002 | Users & relationships |
| 003 | Reference data (sports, formations, positions, divisions) |
| 004 | Player profiles |
| 005 | Coach profiles & roster |
| 006 | Matching engine |
| 007 | Messaging |
| 008 | Notifications, subscriptions, legal |

## User Roles

- **Player** — 6th–12th grade soccer players
- **Parent** — Parent/guardian companion mode
- **Coach** — College soccer coaches
- **Mentor** — Club coaches / advisors
- **Admin** — Internal team (future)

## License

Proprietary — All rights reserved © 2026 Lanista Inc.
