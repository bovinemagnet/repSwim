# repSwim

repSwim is a Flutter mobile app for swimmers to track pool sessions, lap splits, personal bests, training analytics, and dryland workouts. The current implementation is an offline-first V1 focused on reliable tracking and PB workflows.

## Current Features

- Manual swim session logging with stroke, notes, lap distances, lap times, total distance, total time, and pace.
- Swim session history with detail views, filters, search, lap breakdowns, notes, deletion, and CSV export.
- Stopwatch with manual lap splits and save-to-session support.
- Interval timer for structured swim sets with configurable sets, reps, swim time, and rest time.
- Reusable interval templates and dryland routine templates.
- Personal best detection by stroke and distance.
- Analytics dashboard with weekly distance, average pace, pace trend, consistency score, and PB highlights.
- Dryland workout history with exercises, sets, reps, optional weight, notes, editing, and deletion.
- Local SQLite persistence through `sqflite`.
- Multiple swimmer profiles with persisted active-profile selection and scoped sessions, PBs, dryland workouts, and analytics.
- Swimmer profile management with initials avatars, summary stats, preferred pool length, editing, selection, and archiving.
- Adaptive app shell with bottom navigation on phones and a navigation rail on wider screens.
- Desktop-compatible local database setup for Windows and Linux via `sqflite_common_ffi`.
- Optional sync queue scaffolding for future Postgres-backed push/pull without requiring login today.
- Sync settings screen with local/manual/automatic mode selection and queue status counts.

## Tech Stack

- Flutter and Dart
- Riverpod for state management
- go_router for navigation
- sqflite for local storage
- sqflite_common_ffi for desktop SQLite support
- fl_chart for analytics charts
- flutter_test and mocktail for tests

## Project Structure

```text
lib/
  core/                 Shared constants, theme, and utilities
  core/sync/            Optional sync modes, payloads, service, and backend interfaces
  database/             SQLite database and DAO classes
  features/
    analytics/          Dashboard metrics and charts
    dryland/            Dryland workout tracking
    home/               Dashboard/home screen
    pb/                 Personal best entities, logic, and UI
    profiles/           Swimmer profiles and active profile context
    settings/           Sync settings and status
    stopwatch/          Stopwatch and interval timer state/UI
    swim/               Swim sessions, laps, repository, and UI
    templates/          Reusable interval and dryland routine templates
  app.dart              Routing and app shell
  main.dart             Flutter entry point
test/                   Unit and widget tests mirroring feature areas
docs/plans/             Product roadmap and initial build specification
```

## Getting Started

Install dependencies:

```sh
dart pub get
```

Run the app:

```sh
flutter run
```

Run static analysis:

```sh
flutter analyze
```

Run tests:

```sh
flutter test
```

Format code:

```sh
dart format lib test
```

## Testing

The test suite includes:

- Utility tests for duration formatting and pace calculations.
- PB logic tests for new PB detection and duplicate handling.
- Analytics tests for aggregate metrics and PB highlights.
- Stopwatch provider and widget tests.
- Sync payload, queue integration, and settings tests.
- Training template provider tests.
- Swim session widget tests for validation and live totals.
- Profile widget tests for avatars, summaries, and pool-length defaults.

Run all checks before submitting changes:

```sh
flutter analyze && flutter test
```

## Product Direction

The near-term focus is to complete V1 polish: richer desktop layouts and backend-client implementation. Sync is designed as optional and local-first; local mutations are queued now, and a future backend can use Spring Boot or Quarkus with PostgreSQL behind the interfaces in `lib/core/sync/`. AI workout generation, video stroke analysis, wearables, backend sync, and social features are planned later and are described in [docs/plans/prd.md](docs/plans/prd.md) and [docs/plans/updates.md](docs/plans/updates.md).

## Releases & CI/CD

### Android Dev APK

A GitHub Actions workflow (`.github/workflows/android_apk.yml`) automatically builds the Android debug APK and attaches it to the corresponding GitHub Release whenever a **non-major** version tag is pushed.

| Tag example | Behaviour |
|-------------|-----------|
| `v0.0.4`    | ✅ APK built and uploaded to release |
| `v2.1.6`    | ✅ APK built and uploaded to release |
| `v3.0.0`    | 🚫 Skipped (major release) |

**Rule:** a tag is treated as a *major release* when it matches the pattern `v<N>.0.0` (minor and patch are both `0`). All other `v*` tags trigger the build.

To create a release that includes the APK:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The APK (`app-debug.apk`) will appear in the release assets automatically. If no GitHub Release exists for the tag yet, the workflow creates one.

## Contributing

See [AGENTS.md](AGENTS.md) for repository guidelines, coding style, test expectations, and pull request conventions.
