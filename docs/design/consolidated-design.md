# repSwim Consolidated Product & Architecture Design

## 1. Product Vision

repSwim is a local-first training app for swimmers. The long-term goal is to become a swimmer's daily operating system: pool tracking, PBs, interval work, dryland training, analytics, coaching, and later AI/video analysis.

The product direction combines the original V1 build spec with the broader PRD and the later desktop/sync/profile architecture update.

## 2. Product Scope

### V1: Offline Training Log

V1 focuses on reliable local tracking:

- Swim session logging with stroke, distance, lap times, total time, pace, and notes.
- Session history with search, stroke/date filters, desktop table layout, and CSV export.
- Stopwatch with lap splits and save-to-session support.
- Interval timer for structured sets.
- Reusable interval and dryland routine templates.
- Personal best detection by swimmer profile, stroke, and distance.
- Basic analytics: weekly distance, average pace, pace trend, consistency score, and PB highlights.
- Dryland workout tracking with exercises, notes, editing, and deletion.
- Multiple swimmer profiles on one device.
- Local SQLite persistence.

### V2: Coaching & Structured Training

Planned after V1 tracking quality is solid:

- Reusable swim and dryland workout templates.
- Training calendar.
- Goals and upcoming workout planning.
- AI workout generation.
- Video upload and manual video review tools.
- Optional external sync.

### V3: Advanced Platform

Longer-term features:

- AI stroke analysis.
- Pose estimation and technique scoring.
- Wearable imports.
- Open-water mode.
- Coach/squad/team workflows.
- Social features and gamification.
- Recovery and mobility modules.

## 3. Architecture Principles

The app should remain:

- **Local-first:** no login or network required for core use.
- **Profile-scoped:** every user-owned record belongs to a swimmer profile.
- **Offline-safe:** local writes complete immediately.
- **Sync-ready:** data model can later push/pull against a backend.
- **Desktop-ready:** same Flutter app can run on mobile and desktop.

External sync must be optional. Postgres is a future backend target, not a V1 runtime dependency.

## 4. Current Technical Stack

- Flutter and Dart
- Material 3
- Riverpod
- go_router
- sqflite for SQLite on mobile
- sqflite_common_ffi for Windows/Linux desktop SQLite support
- fl_chart for analytics charts
- flutter_test, mocktail, and fake_async for tests

The planning docs recommended Drift. The current implementation uses `sqflite`. A Drift migration may still be useful later, but it is not required before continuing V1.

## 5. Current Code Organization

```text
lib/
  core/
    constants/
    sync/
    theme/
    utils/
  database/
    app_database.dart
    daos/
  features/
    analytics/
    dryland/
    home/
    pb/
    profiles/
    race/
    stopwatch/
    swim/
    tempo/
  app.dart
  main.dart
```

Feature folders are organized around domain entities, providers, screens, and data/repository layers where needed.

## 6. Data Model

### Profiles

Swimmer profiles are the local tenant boundary.

```text
swimmer_profiles
- id
- display_name
- preferred_pool_length_meters
- notes
- created_at
- updated_at
- deleted_at
```

The app creates a default local swimmer profile for existing and first-run data.
The active swimmer selection is persisted locally in `app_settings`, and the
preferred pool length seeds new swim lap entries.

### App Settings

```text
app_settings
- key
- value
- updated_at
```

### Swim Sessions

```text
swim_sessions
- id
- profile_id
- date
- total_distance
- total_time_seconds
- stroke
- notes
```

### Laps

```text
laps
- id
- session_id
- profile_id
- distance
- time_seconds
- lap_number
```

### Personal Bests

```text
personal_bests
- id
- profile_id
- stroke
- distance
- best_time_seconds
- achieved_at
```

Unique rule:

```text
unique(profile_id, stroke, distance)
```

### Race Times And Qualification Standards

```text
race_times
- id
- profile_id
- race_name
- event_date
- distance
- stroke
- course_type
- time_centiseconds
- notes
- placement
- location
- created_at
- updated_at

qualification_standards
- id
- profile_id
- age
- distance
- stroke
- course_type
- gold_centiseconds
- silver_centiseconds
- bronze_centiseconds
- created_at
- updated_at

meet_qualification_standards
- id
- source_name
- sex
- age_group_label
- min_age
- max_age
- is_open
- distance
- stroke
- course_type
- qualifying_centiseconds
- mc_points
- is_relay
- relay_event
- valid_from
- competition_start
- competition_end
```

Manual qualification standards are profile-scoped medal thresholds by age,
event, and course. The Qualification Standards screen includes an age selector
and a gold/silver/bronze table for manual standards. Imported meet standards are
separate local reference data and currently include the 2026/27 Uncloud
Victorian Metro SC Championships source. See
[Race Qualification Standards](../race-qualification-standards.md).

### Dryland

```text
dryland_workouts
- id
- profile_id
- date
- notes

exercises
- id
- workout_id
- profile_id
- name
- sets
- reps
- weight
```

### Training Templates

```text
interval_templates
- id
- profile_id
- name
- sets
- reps
- work_seconds
- rest_seconds
- created_at
- updated_at

dryland_routine_templates
- id
- profile_id
- name
- notes
- created_at
- updated_at

dryland_routine_template_exercises
- id
- template_id
- profile_id
- name
- sets
- reps
- weight
```

### Sync Queue

The local database includes a future-facing sync queue:

```text
sync_queue
- id
- profile_id
- entity_type
- entity_id
- operation
- payload_json
- status
- retry_count
- last_error
- created_at
- updated_at
```

## 7. Profile / Multi-Tenant Rules

Every swimmer-owned feature must read the active profile from Riverpod:

```dart
final profileId = ref.watch(currentProfileIdProvider);
```

Rules:

- Never show sessions, PBs, dryland workouts, or analytics without profile filtering.
- Creation flows must stamp new records with the active `profileId`.
- Deletion and updates must include `profileId` checks.
- PB rebuilds must preserve profile isolation.

## 8. Sync Architecture

Current sync implementation is intentionally local-only unless a backend client
is configured:

- `SyncMode.localOnly`
- `SyncMode.manual`
- `SyncMode.automatic`
- `SyncBackendClient`
- `SyncService`
- `sync_queue` table
- `SyncQueueDao`
- deterministic JSON payload builders for local mutations
- sync settings screen for mode selection and queue status

Future backend recommendation:

- Spring Boot or Quarkus
- PostgreSQL
- REST endpoints for sync
- JWT auth
- Flyway or Liquibase migrations

Recommended API shape:

```http
GET /sync/pull?tenantId=...&since=...
POST /sync/push
POST /sync/resolve-conflict
GET /profiles
POST /profiles
PUT /profiles/{id}
```

Sync strategy should remain local-first:

1. Save local SQLite data immediately.
2. Add pending queue item.
3. Push later if sync is enabled.
4. Pull remote changes.
5. Resolve conflicts.

Conflict policy:

- Last-write-wins for normal text/settings fields.
- Fastest time wins for PB conflicts.
- Manual review for delete conflicts.

## 9. Desktop Direction

The app should run on iOS, Android, Windows, Linux, and macOS. Current database initialization supports Windows/Linux through sqflite FFI. macOS desktop packaging still needs verification.

Desktop should eventually use wider layouts:

- Sidebar navigation.
- Persistent profile switcher.
- Multi-column analytics.
- Session table/detail split view.
- CSV import/export.
- Bulk editing.
- Coach notes.

Mobile should remain optimized for fast logging.

## 10. Non-Goals For Current V1

Do not implement yet:

- Real Postgres sync.
- Authentication.
- AI stroke analysis.
- Video processing.
- Wearable imports.
- Social or squad features.

These are architecture targets, not current dependencies.
