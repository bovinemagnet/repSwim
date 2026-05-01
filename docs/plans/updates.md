Below is a **Copilot-ready architecture design** for extending **repSwim** to mobile + desktop, optional Postgres sync, and multi-profile / multi-tenant swimmer support.

---

# repSwim Architecture Design: Mobile + Desktop + Optional Sync + Multi-Profile

## 1. Goal

Build repSwim as a **local-first Flutter app** that runs on:

* iOS
* Android
* macOS
* Windows
* Linux

The app must support:

* Multiple swimmer profiles on one device
* Separate sessions, PBs, dryland workouts, goals, and analytics per swimmer
* Optional sync to an external backend using PostgreSQL
* Future coach/squad/team features
* Future AI/video analysis features

Flutter supports native desktop builds for Windows, macOS, and Linux, so the same app can scale beyond mobile without a full rewrite. ([Flutter Docs][1])

---

# 2. Recommended Architecture

## High-Level Design

```text
Flutter App
 ├── Mobile UI
 ├── Desktop UI
 ├── Shared App Logic
 ├── Local SQLite Database
 ├── Optional Sync Engine
 └── Platform Integrations

Local Database
 └── Drift / SQLite

Optional Remote Backend
 ├── API Server
 ├── PostgreSQL
 ├── Auth
 └── Sync Endpoints
```

Recommended stack:

```text
Frontend:
- Flutter
- Riverpod
- Drift
- go_router

Local storage:
- SQLite via Drift

Backend:
- Spring Boot or Quarkus
- PostgreSQL
- REST or GraphQL API

Sync:
- Local-first sync engine
- Push/pull changes
- Conflict resolution
```

Drift is a good fit because it is relational, type-safe, reactive, supports migrations, and works across Flutter native platforms including mobile and desktop. It also has PostgreSQL support for server-side Dart use cases, though for your background I’d still lean Spring Boot / Quarkus + Postgres for the backend. ([drift.simonbinder.eu][2])

---

# 3. Core Principle

The app should **not require login or sync to work**.

Use this model:

```text
Local-first by default.
Cloud sync optional.
Profiles always tenant-scoped.
```

That means:

* User can install app and immediately use it offline
* Swimmer data lives locally first
* Sync can be enabled later
* Every table includes profile/tenant ownership
* Desktop can use the same local database model as mobile

---

# 4. Multi-Profile / Multi-Tenant Model

repSwim should treat every swimmer as a separate tenant-like profile.

Example:

```text
App Account
 ├── Profile: Dad
 ├── Profile: Child 1
 ├── Profile: Child 2
 └── Profile: Squad swimmer
```

Each profile has isolated:

* Swim sessions
* Lap times
* PBs
* Dryland workouts
* Goals
* Training plans
* Stroke analysis
* Settings

## Local Multi-Tenant Rule

Every user-owned table must include:

```text
profile_id
```

For remote sync, also include:

```text
account_id
tenant_id
profile_id
```

For V1, `profile_id` is enough locally.

For future sync/team support, design the data model with this hierarchy:

```text
Account
 └── Workspace / Tenant
      └── Swimmer Profile
           ├── Swim Sessions
           ├── Laps
           ├── PBs
           ├── Workouts
           └── Analytics
```

---

# 5. Proposed Data Model

## 5.1 Accounts

Used only when sync is enabled.

```sql
accounts (
  id uuid primary key,
  email text,
  display_name text,
  created_at timestamptz not null,
  updated_at timestamptz not null
)
```

Local app can create a local-only account:

```text
local_account
```

---

## 5.2 Tenants / Workspaces

Use this for future family, squad, club, or coach mode.

```sql
tenants (
  id uuid primary key,
  account_id uuid not null,
  name text not null,
  tenant_type text not null, -- personal, family, squad, club
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

For V1:

```text
Default tenant = "My Swimmers"
```

---

## 5.3 Swimmer Profiles

```sql
swimmer_profiles (
  id uuid primary key,
  tenant_id uuid not null,
  display_name text not null,
  date_of_birth date,
  gender text,
  preferred_pool_length_meters integer default 25,
  avatar_uri text,
  notes text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

Important: do **not** make the app assume one profile equals one login.

A parent may manage several swimmers.

---

## 5.4 Swim Sessions

```sql
swim_sessions (
  id uuid primary key,
  profile_id uuid not null,
  session_date timestamptz not null,
  location_name text,
  pool_length_meters integer not null,
  total_distance_meters integer not null,
  total_time_ms integer not null,
  primary_stroke text,
  session_type text, -- training, race, time_trial, technique, recovery
  perceived_effort integer,
  notes text,
  source text not null, -- manual, stopwatch, watch_import, sync
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

---

## 5.5 Laps

```sql
laps (
  id uuid primary key,
  profile_id uuid not null,
  session_id uuid not null,
  lap_number integer not null,
  distance_meters integer not null,
  time_ms integer not null,
  stroke text not null,
  split_type text, -- lap, interval, rep, rest
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

Keep `profile_id` on laps even though it can be inferred from session. This makes sync, filtering, and data isolation simpler.

---

## 5.6 Personal Bests

```sql
personal_bests (
  id uuid primary key,
  profile_id uuid not null,
  stroke text not null,
  distance_meters integer not null,
  best_time_ms integer not null,
  achieved_session_id uuid,
  achieved_lap_id uuid,
  achieved_at timestamptz not null,
  source text not null, -- manual, auto_detected, imported
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

Unique rule:

```sql
unique(profile_id, stroke, distance_meters)
```

---

## 5.7 Dryland Workouts

```sql
dryland_workouts (
  id uuid primary key,
  profile_id uuid not null,
  workout_date timestamptz not null,
  title text not null,
  workout_type text, -- strength, mobility, core, cardio, rehab
  duration_minutes integer,
  perceived_effort integer,
  notes text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

---

## 5.8 Dryland Exercises

```sql
dryland_exercises (
  id uuid primary key,
  profile_id uuid not null,
  workout_id uuid not null,
  exercise_name text not null,
  sets integer,
  reps integer,
  weight_kg real,
  duration_seconds integer,
  distance_meters integer,
  notes text,
  sort_order integer not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

---

# 6. Local-First Sync Design

## 6.1 Sync Should Be Optional

Add app setting:

```text
Sync mode:
- Local only
- Manual sync
- Auto sync
```

Default:

```text
Local only
```

---

## 6.2 Sync Metadata

Every syncable table should include:

```sql
local_id uuid primary key
remote_id uuid nullable
profile_id uuid not null
tenant_id uuid nullable
sync_status text not null
sync_version integer not null
created_at timestamptz not null
updated_at timestamptz not null
deleted_at timestamptz nullable
last_synced_at timestamptz nullable
```

Possible `sync_status` values:

```text
local_only
pending_create
pending_update
pending_delete
synced
conflict
```

---

## 6.3 Sync Queue

Add a local table:

```sql
sync_queue (
  id uuid primary key,
  entity_type text not null,
  entity_id uuid not null,
  operation text not null, -- create, update, delete
  payload_json text not null,
  status text not null, -- pending, processing, failed, complete
  retry_count integer not null default 0,
  last_error text,
  created_at timestamptz not null,
  updated_at timestamptz not null
)
```

When the user creates or updates data locally:

```text
1. Save to local SQLite immediately.
2. Mark row as pending_create or pending_update.
3. Insert sync_queue record.
4. UI updates instantly.
5. Sync later if enabled.
```

---

# 7. Backend Design

## Recommended Backend

Since you already work in Java/Spring/Quarkus, I would use:

```text
Option A:
- Spring Boot 3
- Spring GraphQL or REST
- PostgreSQL
- Flyway or Liquibase
- JWT auth

Option B:
- Quarkus
- RESTEasy Reactive
- Hibernate Panache or jOOQ
- PostgreSQL
```

My opinion: for this app, **REST is probably better than GraphQL for sync**.

GraphQL is nice for flexible reads, but sync flows usually benefit from boring, explicit endpoints.

---

## 7.1 API Endpoints

```http
POST /auth/login
POST /auth/register

GET /sync/pull?tenantId=...&since=...
POST /sync/push
POST /sync/resolve-conflict

GET /profiles
POST /profiles
PUT /profiles/{id}

GET /profiles/{profileId}/sessions
POST /profiles/{profileId}/sessions

GET /profiles/{profileId}/pbs
GET /profiles/{profileId}/analytics
```

---

## 7.2 Sync Push Payload

```json
{
  "deviceId": "device-uuid",
  "tenantId": "tenant-uuid",
  "changes": [
    {
      "entityType": "swim_session",
      "entityId": "local-uuid",
      "operation": "create",
      "clientUpdatedAt": "2026-05-01T10:00:00Z",
      "version": 1,
      "payload": {}
    }
  ]
}
```

---

## 7.3 Sync Pull Response

```json
{
  "serverTime": "2026-05-01T10:05:00Z",
  "changes": [
    {
      "entityType": "swim_session",
      "entityId": "remote-uuid",
      "operation": "upsert",
      "version": 3,
      "updatedAt": "2026-05-01T10:04:00Z",
      "payload": {}
    }
  ]
}
```

---

# 8. Conflict Resolution

Start simple.

## V1 Conflict Strategy

```text
Last write wins for normal fields.
Manual conflict screen for PBs and deleted records.
```

PBs should not blindly overwrite.

For PB conflict:

```text
Choose fastest time.
Keep achieved_at from the winning result.
Preserve both source records.
```

Example:

```text
If device A records 50m freestyle as 35.20
and device B records 50m freestyle as 34.90
then remote PB becomes 34.90.
```

---

# 9. Desktop-Specific Features

Desktop should not just be “mobile stretched bigger.”

Use desktop for extended features:

## Desktop Dashboard

```text
- Multi-column analytics
- Profile comparison
- Training calendar
- PB progression charts
- CSV import/export
- Coach notes
- Bulk editing
```

## Desktop Layout

```text
Left sidebar:
- Profiles
- Dashboard
- Sessions
- Stopwatch
- PBs
- Analytics
- Dryland
- Settings

Main panel:
- Selected feature

Right panel:
- Current profile summary
- Recent PBs
- Upcoming goals
```

---

# 10. Responsive UI Design

Use adaptive layouts:

```text
Mobile:
- Bottom navigation
- Single active swimmer profile
- Fast logging flow

Tablet/Desktop:
- Navigation rail/sidebar
- Multi-panel views
- Profile switcher always visible
```

Flutter implementation idea:

```dart
enum FormFactor {
  phone,
  tablet,
  desktop,
}

FormFactor getFormFactor(double width) {
  if (width < 600) return FormFactor.phone;
  if (width < 1000) return FormFactor.tablet;
  return FormFactor.desktop;
}
```

---

# 11. Profile Switching UX

## Mobile

Top of home screen:

```text
Current swimmer: Ethan ▼
```

Tap opens:

```text
Switch Profile
- Ethan
- Sophie
- Dad
- Add swimmer
```

## Desktop

Permanent sidebar:

```text
Profiles
- Ethan
- Sophie
- Dad
+ Add Profile
```

All queries must use selected profile:

```dart
final selectedProfileId = ref.watch(selectedProfileProvider);
```

Never show sessions without filtering by profile.

---

# 12. Repository Pattern

Use repositories that always require profile context.

```dart
abstract class SwimSessionRepository {
  Stream<List<SwimSession>> watchSessions(ProfileId profileId);
  Future<void> saveSession(ProfileId profileId, SwimSession session);
  Future<void> deleteSession(ProfileId profileId, SessionId sessionId);
}
```

Avoid this:

```dart
Future<List<SwimSession>> getAllSessions();
```

Prefer this:

```dart
Future<List<SwimSession>> getSessionsForProfile(ProfileId profileId);
```

This avoids accidental data leakage between swimmers.

---

# 13. Folder Structure

```text
lib/
 ├── app/
 │   ├── app.dart
 │   ├── router.dart
 │   └── adaptive_shell.dart
 │
 ├── core/
 │   ├── database/
 │   ├── sync/
 │   ├── tenant/
 │   ├── theme/
 │   └── utils/
 │
 ├── features/
 │   ├── profiles/
 │   ├── swim_sessions/
 │   ├── stopwatch/
 │   ├── personal_bests/
 │   ├── analytics/
 │   ├── dryland/
 │   └── settings/
 │
 └── main.dart
```

---

# 14. Copilot Build Prompt

Paste this into Copilot:

```text
Build a Flutter app called repSwim that supports iOS, Android, macOS, Windows, and Linux.

Use:
- Flutter Material 3
- Riverpod
- go_router
- Drift with SQLite
- Feature-first clean architecture

The app is local-first and must support multiple swimmer profiles. Every domain table must be scoped by profile_id. Design it like a multi-tenant app.

Core concepts:
- Account: optional, only needed for sync
- Tenant/workspace: future family/squad/club support
- SwimmerProfile: active swimmer context
- SwimSession
- Lap
- PersonalBest
- DrylandWorkout
- DrylandExercise
- SyncQueue

Requirements:
1. The app must work fully offline without login.
2. The user can create multiple swimmer profiles.
3. The user can switch active swimmer profile.
4. All swim sessions, laps, PBs, dryland workouts, analytics, and settings must be filtered by the active profile.
5. Add Drift tables for profiles, sessions, laps, PBs, dryland workouts, exercises, and sync queue.
6. Include sync metadata columns on syncable tables:
   - remote_id
   - sync_status
   - sync_version
   - created_at
   - updated_at
   - deleted_at
   - last_synced_at
7. Implement repositories that always require profileId.
8. Implement a profile switcher.
9. Implement adaptive UI:
   - phone uses bottom navigation
   - tablet/desktop uses sidebar/navigation rail
10. Implement placeholder sync service:
   - local only mode
   - manual sync mode
   - auto sync mode
   - push pending changes
   - pull remote changes
   - mark conflicts
11. Do not implement the real backend yet, but define API client interfaces for a future PostgreSQL backend.

Build order:
1. Project structure
2. Drift database schema
3. Profile feature
4. Active profile provider
5. Swim session feature scoped by profile
6. PB feature scoped by profile
7. Dryland feature scoped by profile
8. Analytics scoped by profile
9. Adaptive mobile/desktop shell
10. Sync queue and sync service interfaces

Use UUIDs for IDs.
Use soft deletes with deleted_at.
Use UTC timestamps.
Write production-quality Dart code.
```

---

# 15. Strong Recommendation

For repSwim, the best design is:

```text
Flutter app
+ Drift local database
+ profile-scoped local-first data
+ optional Spring Boot / Quarkus sync backend
+ PostgreSQL remote database
```

Do **not** make Postgres required for V1.

Make sync a premium/advanced feature later. The app should be excellent as an offline training log first.

[1]: https://docs.flutter.dev/platform-integration/desktop?utm_source=chatgpt.com "Desktop support for Flutter"
[2]: https://drift.simonbinder.eu/examples/server_sync/?utm_source=chatgpt.com "Backend synchronization - Drift! - Simon Binder"
