# Coach mode — design

- **Date:** 2026-05-16
- **Issue:** #10 — Add coach mode for sharing swimmer details
- **Author:** Paul Snow
- **Status:** Approved (design); ready for implementation plan

## Summary

Coach mode lets a swimmer share selected details of selected profiles with a
coach in a controlled, read-only way. It has two delivery paths, both
offline-first:

1. An on-device, **sealed read-only coach view** the swimmer can hand to a
   coach in person.
2. A **PDF export** of a shared profile's shared data the swimmer can send to
   a remote coach.

Sharing is opt-in per profile and per data category. Nothing is shared until
the swimmer explicitly enables it.

## Goals

- Per-profile, per-category opt-in sharing, persisted locally.
- A read-only coach view that exposes only shared data and no editing.
- A PDF report of a shared profile for remote coaches.
- Clear visibility of what is currently shared, and a one-action revoke.
- Preserve the offline-first contract — no network dependency.

## Non-goals

- Remote or cloud delivery of shared data. The PDF file is the bridge to a
  remote coach until the sync layer gains a live backend.
- Coach write-back or editing of swimmer data.
- A PIN or passcode lock on the coach view (the sealed view with an explicit
  exit is sufficient for this iteration).
- Multiple named coaches or per-coach identity.

## Decisions

Settled during brainstorming:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Coach access | On-device coach view **and** PDF export | Covers in-person and remote coaches without a backend. |
| Export format | PDF | Universally viewable; "official" feel for a coach. |
| Coach view lock | Sealed read-only screen, explicit exit, no PIN | Meets the read-only requirement without PIN infrastructure. |
| Category granularity | One opt-in toggle per category, all default off | Matches issue #10's privacy requirements. |

## Architecture

A new feature module `lib/features/coach/`, following the project's
domain/data/presentation layout.

```
lib/features/coach/
├── domain/
│   ├── entities/
│   │   ├── coach_share_category.dart   # enum of shareable categories
│   │   └── coach_share.dart            # per-profile sharing config
│   └── services/
│       ├── coach_report_builder.dart   # assembles the shared-data report model
│       └── coach_pdf_builder.dart      # renders the report model to a PDF
├── data/
│   └── coach_share_repository.dart     # wraps CoachShareDao
└── presentation/
    ├── providers/
    │   └── coach_providers.dart
    ├── screens/
    │   ├── coach_sharing_settings_screen.dart
    │   └── coach_view_screen.dart
    └── widgets/
        └── (read-only category panels for the coach view)
```

Plus:

- `lib/database/daos/coach_share_dao.dart` — persistence DAO.
- Route entries in `lib/app.dart`.
- `pdf` and `printing` dependencies in `pubspec.yaml`.

### Central report model

`coach_report_builder` assembles a single **report model** for a chosen
profile: the profile, plus each shared category's data, pulled from the
existing DAOs (`SwimSessionDao`, `RaceTimeDao`, `PbDao`, `DrylandDao`, and the
analytics computation). Both the coach view and `coach_pdf_builder` consume
this one model, so "what is shared" is defined in exactly one place and the
two outputs cannot diverge.

### Data model

New table `coach_shares`, one row per profile:

| Column | Type | Notes |
|--------|------|-------|
| `profile_id` | TEXT | Primary key; `REFERENCES profiles(id) ON DELETE CASCADE`. |
| `enabled` | INTEGER | Master "share with coach" flag (0/1). |
| `shared_categories` | TEXT | The set of shared categories, stored as a JSON array of category keys — the same pattern already used for `SwimmerProfile.preferredStrokes` (the `preferred_strokes_json` column). |

A profile with no row is not shared. `kDbVersion` bumps **12 → 13**, with a
matching branch added to `_onUpgrade` in `AppDatabase` and the table created
in `_onCreate`.

`CoachShareCategory` enum — eight independent categories:

`profileDetails`, `goals`, `notes`, `swimSessions`, `raceTimes`,
`personalBests`, `analytics`, `dryland`.

Every category defaults to **off**. `notes` and `profileDetails` in
particular are only ever included when explicitly enabled.

## Features

### Sharing configuration

`coach_sharing_settings_screen` (route `/coach/sharing/:profileId`), reached
from a **"Coach sharing" action on each profile card** on the Profiles screen.

- A master *Share with coach* switch — toggles `enabled`.
- A per-category toggle list, shown when sharing is enabled.
- A plain-language summary of what is currently shared.
- A *Stop sharing* action that disables sharing for the profile.
- Notes/personal-detail categories carry a short caution that they are only
  shared when explicitly switched on.

### Sharing status

Each profile card on the Profiles screen shows a **"Shared with coach"**
indicator (icon or chip) when that profile has sharing enabled.

### Coach view

`coach_view_screen` (route `/coach`), rendered **outside the adaptive shell**
— no bottom navigation, no navigation rail. Reached from a *Coach view*
action on the Profiles screen, which is available only when at least one
profile has sharing enabled.

- If more than one profile is shared, a picker lists **only shared profiles**.
- Selecting a profile shows a read-only dashboard: one panel per **shared**
  category. Unshared categories do not appear at all.
- An *Export PDF* action for the selected profile.
- A single explicit *Exit coach view* action returns to normal mode.
- No edit, add, or delete controls anywhere in this view.

### PDF export

`coach_pdf_builder` renders the report model to a `pdf.Document` containing
only the shared categories, headed with the swimmer's name and the list of
included categories. The `printing` package handles sharing/saving the file.
Export is available from the coach view and produces the same data the view
shows.

## Error handling

- A profile whose sharing is revoked mid-session drops out of the coach-view
  picker; an in-progress export for it is guarded against the revoked state.
- Empty categories (for example a profile with no race times) render a
  "No data" placeholder rather than an error.
- A PDF generation or share failure surfaces a clear message and does not
  crash the app.
- Deleting a profile cascades to remove its `coach_shares` row.

## Testing

Per issue #10's acceptance criteria:

- **Unit tests** — `CoachShareCategory` / `CoachShare` rules; `coach_report_builder`
  includes only the enabled categories and only the selected profile's data
  (profile scoping); `coach_pdf_builder` produces a document for a populated
  report.
- **Widget tests** — enabling sharing, toggling individual categories,
  reviewing the shared-categories summary, and disabling sharing; the coach
  view renders only shared categories and exposes no edit affordances.
- **Integration tests** — `CoachShareDao` round-trip persistence of the
  sharing configuration, and cascade deletion when the owning profile is
  removed.

## Acceptance criteria (issue #10)

- [x] Enable coach sharing from profile management — *Sharing configuration*.
- [x] Select profiles and data categories to share — *Sharing configuration*.
- [x] Shared data stays scoped to the selected profile — *Central report
  model* + scoping unit tests.
- [x] Review what is currently shared — *Sharing configuration* summary +
  Profiles-screen indicator.
- [x] Revoke sharing — *Stop sharing* action.
- [x] UI distinguishes coach/read-only from editing — *Coach view* (sealed,
  no edit controls).
- [x] Unit tests for sharing rules and profile scoping — *Testing*.
- [x] Widget tests for enable/review/disable — *Testing*.
- [x] Integration tests for persistence — *Testing*.

## Risks

- **New dependencies** — `pdf` and `printing` are added to the project. Both
  are widely used Flutter packages, but they are the first such additions for
  this feature; the implementation plan pins versions and the build is
  verified after they are added.
- **Schema migration** — the v12 → v13 migration must create `coach_shares`
  without disturbing existing data; covered by an integration/migration test.
