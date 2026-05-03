# repSwim Implementation Status & Roadmap

## 1. Current Implementation Status

This status reflects the current codebase after consolidating the PRD, V1 build spec, and desktop/sync/profile updates.

## 2. Completed

### App Foundation

- Flutter app shell with Material themes.
- go_router routes.
- Riverpod state management.
- Feature-first folder structure.
- Local SQLite persistence.
- Desktop SQLite support for Windows/Linux through `sqflite_common_ffi`.
- Adaptive shell with phone bottom navigation and tablet/desktop navigation rail.
- README and contributor guide.

### Profiles / Multi-Tenant Foundation

- `SwimmerProfile` domain entity.
- `swimmer_profiles` table.
- Default local swimmer profile.
- Profile DAO.
- Active profile providers.
- Home screen profile switcher.
- Dedicated profile management screen.
- Add/edit/archive swimmer profiles.
- Profile-scoped sessions, laps, PBs, dryland workouts, and analytics.
- Persisted active swimmer selection.
- Initials-based profile avatars.
- Profile summary statistics.
- Preferred pool length used as the default lap distance in swim logging.

### Swim Tracking

- Manual swim session creation.
- Stroke selection.
- Notes.
- Lap entry.
- Auto-calculated total distance, total time, and pace.
- Swim session detail screen.
- Lap breakdown on detail screen.
- Session deletion.
- Full session history screen.
- Search by notes/stroke/date text.
- Filter by stroke and date range.
- Desktop session table layout.
- CSV export to clipboard.

### Stopwatch & Intervals

- Stopwatch start/pause/reset.
- Manual lap splits.
- Save stopwatch splits as swim sessions.
- Interval timer with configurable sets, reps, swim time, and rest time.
- Interval start/pause/reset/skip.
- Save interval timer config as a reusable template.
- Load saved interval templates into the timer.

### Personal Bests

- PB detection per profile, stroke, and distance.
- PB persistence with profile-scoped uniqueness.
- PB rebuild after session deletion.
- PB screen grouped by stroke.

### Race Times & Qualification Standards

- Race time logging with meet name, date, event, course, time, placement,
  location, and notes.
- Race time search, filters, sort options, mobile cards, and desktop table.
- Manual qualification standards scoped to the active swimmer profile.
- Manual standards store age, event, course, and gold/silver/bronze thresholds.
- Qualification standard validation keeps gold faster than silver and bronze.
- Qualification matching by profile, age, distance, stroke, and course.
- Age-based medal standards table on the Qualification Standards screen.
- Imported Victorian Metro SC 2026/27 meet standards as local reference data.
- Local sync queue payloads for manual qualification standard mutations.

### Analytics

- Total sessions.
- Total distance.
- Average pace.
- Last-7-days distance chart.
- Pace trend chart.
- Consistency score.
- PB highlights.

### Dryland

- Dryland workout creation.
- Exercise entry with sets, reps, and optional weight.
- Workout list.
- Workout expansion view.
- Workout editing.
- Workout deletion.
- Exercise list replacement on update.
- Save dryland workouts as reusable routine templates.
- Create dryland workouts from routine templates.

### Training Templates

- `interval_templates` table.
- `dryland_routine_templates` table.
- `dryland_routine_template_exercises` table.
- Profile-scoped template providers.
- Template create/delete mutations queued for future sync.

### Sync Foundation

- `sync_queue` table.
- Sync mode enum.
- Sync queue item model.
- Sync queue DAO with deterministic JSON payloads.
- Backend client interface.
- Sync service pushes pending queue items when a backend client is configured.
- Local-only default mode.
- Local mutation queueing for swim sessions, dryland workouts, and swimmer profiles.
- Local mutation queueing for interval and dryland routine templates.
- Sync settings screen with local/manual/automatic mode selection.
- Active-profile queue summary counts.

### Tests

- Duration utility tests.
- PB service tests.
- Profile-isolated PB rebuild test.
- Analytics provider tests.
- Stopwatch provider and widget tests.
- Interval timer provider and widget tests.
- Swim session widget tests.
- Swim session detail widget tests.
- Race time service, provider, and widget tests.
- Qualification standard service, provider, widget, source, and DAO tests.
- Dryland provider update test.
- Sync payload tests.
- Sync queue provider integration tests.
- Training template provider tests.
- Sync settings widget test.
- Profile widget tests.

## 3. Partially Complete

### Desktop Support

Done:

- Windows/Linux SQLite FFI support.
- Flutter platform folders exist in the worktree.
- Adaptive navigation shell is implemented.
- Wider layouts use a navigation rail and profile selector.
- Linux release build verified in the local development environment.

Remaining:

- Verify desktop builds on Windows and macOS.
- Add desktop-specific layouts for analytics and session history.

### Multi-Profile UX

Done:

- Add and switch swimmer profiles from home.
- Dedicated profile management screen.
- Edit profile name, notes, and preferred pool length.
- Archive non-default profiles.
- Data scoping is in place.
- Persist last active profile between app launches.
- Profile avatars.
- Preferred pool length per profile used in swim logging defaults.
- Profile summary statistics.

Remaining:

- Optional custom profile images.

### Sync

Done:

- Local schema and service interfaces.
- Queue writes from local profile, swim session, and dryland mutations.
- Queue writes from local template mutations.
- Sync settings UI.
- Pending/failed/complete queue status.

Remaining:

- API client implementation.
- Auth/account model.
- Tenant/workspace model.
- Remote backend.
- Conflict handling.

## 4. Recommended Next Work

The immediate engineering hardening work is tracked in
[Code Review Implementation Plan](code-review-implementation-plan.md). Complete
the correctness and migration phases there before starting larger backend or
desktop work.

### Priority 1: Backend Sync Client

Implement the remote sync side:

- Implement a real API client.
- Add remote pull/apply and conflict handling.
- Add backend auth/account wiring.

### Priority 2: Desktop Polish

Refine wider-screen workflows:

- Multi-column analytics.
- Session table/detail split view.
- Desktop build verification.

### Priority 3: Profile Polish

Round out multi-profile UX:

- Optional custom profile images.
- Deeper profile trend summaries.

Acceptance criteria:

- Local app behavior is unchanged.
- Sync mode remains `localOnly` by default.
- Sync remains optional and non-blocking.

## 5. Backend Roadmap

Do not make backend required for V1.

Recommended later backend:

- Spring Boot or Quarkus.
- PostgreSQL.
- REST sync endpoints.
- Flyway/Liquibase migrations.
- JWT auth.

Initial backend entities:

- accounts
- tenants/workspaces
- swimmer_profiles
- swim_sessions
- laps
- personal_bests
- dryland_workouts
- dryland_exercises
- sync_changes or sync_events

Initial endpoints:

```http
POST /auth/register
POST /auth/login
GET /profiles
POST /profiles
PUT /profiles/{id}
GET /sync/pull?tenantId=...&since=...
POST /sync/push
POST /sync/resolve-conflict
```

## 6. Deferred Features

These are intentionally not next:

- AI workout generation.
- AI stroke analysis.
- Video annotation.
- Wearable import.
- Open-water GPS mode.
- Social features.
- Squad/club management.
- Payments/subscriptions.

## 7. Migration Notes

Current database version: `6`.

Important migrations already represented:

- Version 2: PB uniqueness hardening.
- Version 3: profile support, profile ownership columns, sync queue.
- Version 4: profile-scoped sync queue records.
- Version 5: interval and dryland routine template tables.
- Version 6: app settings table for persisted local preferences.

If the project later migrates from sqflite to Drift, preserve:

- Existing table names where practical.
- `profile_id` on all swimmer-owned tables.
- PB uniqueness by `(profile_id, stroke, distance)`.
- Sync queue semantics.
- Default local profile migration.

## 8. Development Checklist

Before merging future work:

- Run `dart format lib test`.
- Run `flutter analyze`.
- Run `flutter test`.
- Verify new data access is profile-scoped.
- Add tests for business logic and profile isolation.
- Keep sync optional and local-first.
