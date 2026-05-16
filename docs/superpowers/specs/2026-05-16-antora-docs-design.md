# Antora documentation site — design

- **Date:** 2026-05-16
- **Issue:** #9 — Add Antora documentation for app pages and features
- **Author:** Paul Snow
- **Status:** Approved (design); ready for implementation plan

## Summary

repSwim has grown to 15 screens across 11 feature areas with no user or
contributor documentation. This design introduces an Antora documentation
component rooted at `src/docs/`, with one page per feature, grouped
navigation, a self-contained npm-based build, and migration of the two
existing Markdown feature docs into the new structure.

## Goals

- An Antora-compatible component exists at `src/docs/` and builds cleanly.
- Every app page and major feature has concise, accurate documentation.
- Navigation is grouped so the site stays maintainable as the app grows.
- A single source of truth — existing Markdown feature docs are migrated, not
  duplicated.
- A contributor can add docs for a new page by following one short page.

## Non-goals

- Screenshots. The `images/` directory is created empty (with `.gitkeep`);
  capturing screens is deferred to a follow-up issue.
- Gradle integration. The global `gradle21w antora` alias belongs to the
  user's Java/Quarkus projects; this Flutter repo uses an npm-based build.
- Internal planning docs. `docs/design/`, `docs/plans/`, and `docs/ideas/`
  are contributor planning material and are left untouched.
- Versioned documentation. The component is single-version.

## Decisions

These were settled during brainstorming:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Build tooling | npm + `npx antora` | Self-contained, standard Antora; no Gradle in this Flutter repo. |
| Existing Markdown docs | Migrate into Antora, delete originals | Single source of truth, no drift. |
| Page granularity | One page per feature, grouped nav | Matches issue scope; cleaner navigation than per-screen. |
| Screenshots | Text-only this pass | Keeps the change focused and reviewable. |
| Module layout | Single `ROOT` module | Matches issue #9; trivial cross-references. |

## Architecture

### Component & build

A new Antora component, built with a committed npm toolchain.

- **`src/docs/antora.yml`** — component descriptor:
  - `name: repswim`
  - `title: repSwim`
  - `version: '0.0.0'` (per project convention; may switch to unversioned
    `~` if clean URLs without a version segment are preferred)
  - `nav: [modules/ROOT/nav.adoc]`
- **`antora-playbook.yml`** (repo root) — build playbook:
  - single local content source, `start_path: src/docs`, current branch
  - `output.dir: build/docs/site`
  - `ui.bundle.url` — the default Antora UI bundle (requires network on first
    build; cached thereafter)
- **`package.json`** (repo root) — docs toolchain:
  - `devDependencies`: `@antora/cli`, `@antora/site-generator`
  - script: `"docs:build": "antora antora-playbook.yml"`
  - `package-lock.json` is committed for reproducible builds
- **`.gitignore`** — add `node_modules/`. The `build/` directory is already
  ignored by the Flutter `.gitignore`, which covers `build/docs/site`.

### Directory structure

```
src/docs/
├── antora.yml
└── modules/
    └── ROOT/
        ├── nav.adoc
        ├── pages/
        │   ├── index.adoc
        │   ├── profiles.adoc
        │   ├── swim-sessions.adoc
        │   ├── stopwatch.adoc
        │   ├── interval-timer.adoc
        │   ├── tempo-trainer.adoc
        │   ├── analytics.adoc
        │   ├── personal-bests.adoc
        │   ├── race-times.adoc
        │   ├── qualification-standards.adoc
        │   ├── dryland.adoc
        │   ├── sync-settings.adoc
        │   └── contributing.adoc
        ├── partials/
        │   └── profile-scoping.adoc
        └── images/
            └── .gitkeep
```

13 pages in one `ROOT` module.

### Navigation (`nav.adoc`)

Grouped into sections. Section headings are non-link list items; pages are
nested `xref:` entries.

```adoc
* xref:index.adoc[Overview]
* Getting started
** xref:profiles.adoc[Profiles]
* Training tools
** xref:swim-sessions.adoc[Swim sessions]
** xref:stopwatch.adoc[Stopwatch]
** xref:interval-timer.adoc[Interval timer]
** xref:tempo-trainer.adoc[Tempo trainer]
** xref:dryland.adoc[Dryland training]
* Records & races
** xref:personal-bests.adoc[Personal bests]
** xref:analytics.adoc[Analytics]
** xref:race-times.adoc[Race times]
** xref:qualification-standards.adoc[Qualification standards]
* Data & sync
** xref:sync-settings.adoc[Sync settings]
* Contributing
** xref:contributing.adoc[Adding documentation]
```

## Page content

Page content is derived by reading the actual screen code under
`lib/features/<feature>/presentation/screens/`, so wording and field names
match the current UI.

### Standard page template

Each feature page covers, scaled to the feature:

1. **Purpose** — what the feature is for.
2. **Reaching it** — route and where it sits in app navigation.
3. **Common actions** — the main workflows on the screen(s).
4. **Important fields** — inputs and what they mean.
5. **Expected behaviour** — what happens on save, calculation, edge cases.
6. **Data ownership** — profile scoping, via the shared partial where relevant.

### Per-page scope

| Page | Screens covered | Notes |
|------|-----------------|-------|
| `index.adoc` | — | Landing page: what repSwim is, offline-first model, links to sections. |
| `profiles.adoc` | `profiles_screen` | Profiles and how data is scoped to a profile. Source of the shared scoping partial. |
| `swim-sessions.adoc` | `swim_sessions_screen`, `swim_session_detail_screen`, `swim_session_screen` | List, detail, create/edit in one page. |
| `stopwatch.adoc` | `stopwatch_screen` | Stopwatch and lap capture. |
| `interval-timer.adoc` | `interval_timer_screen` | Interval timer configuration and behaviour. |
| `tempo-trainer.adoc` | `tempo_trainer_screen`, `tempo_results_screen` | Tempo trainer, presets (USRPT race pace, stroke-rate ramp), and result history. Migrated from `docs/tempo-trainer.md`. |
| `analytics.adoc` | `analytics_screen` | Training analytics and charts. |
| `personal-bests.adoc` | `pb_screen` | Personal bests; `(stroke, distance)` uniqueness. |
| `race-times.adoc` | `race_times_screen` | Covers race name/meet, person/profile, distance, time, short/long course selection (acceptance criterion). |
| `qualification-standards.adoc` | `qualification_standards_screen` | Age-based medal standards. Migrated from `docs/race-qualification-standards.md`. |
| `dryland.adoc` | `dryland_screen` | Dryland training. |
| `sync-settings.adoc` | `sync_settings_screen` | Explains local-first behaviour, optional sync, queue status, and failure handling (acceptance criterion). |
| `contributing.adoc` | — | How to add a page: create the `.adoc`, add the `nav.adoc` entry, run `npm run docs:build`. |

The `home_screen` is described within `index.adoc` rather than given its own
page — it is the app's dashboard and maps naturally to the docs overview.

### Shared partial

`partials/profile-scoping.adoc` — one reusable explanation of how records are
scoped to the active profile, included on pages where data ownership matters
(swim sessions, personal bests, analytics, race times, tempo trainer).

## Content migration

| Source | Destination | Action |
|--------|-------------|--------|
| `docs/tempo-trainer.md` (261 lines) | `src/docs/modules/ROOT/pages/tempo-trainer.adoc` | Convert to AsciiDoc, then delete source. |
| `docs/race-qualification-standards.md` (52 lines) | `src/docs/modules/ROOT/pages/qualification-standards.adoc` | Convert to AsciiDoc, then delete source. |

Migration preserves the existing content and structure; it is reformatted to
AsciiDoc and updated only where it no longer matches the current UI.

## Style

- British spelling throughout (initialise, behaviour, colour, recognise).
- Sentence-case headings (`= Page title`, `== Section title`).
- Heading levels are not skipped (`=` → `==` → `===`).
- Source blocks tag their language.
- Inter-page links use `xref:`, never relative file paths.
- Admonitions used sparingly, only where they earn their place.

## Validation

A docs change is done only when the build is clean.

1. `npm install` once (installs the Antora toolchain; requires network).
2. `npx antora antora-playbook.yml` (or `npm run docs:build`).
3. The build must complete with **zero** warnings about unresolved page
   references, missing partials, or broken `xref:` targets.
4. Confirm `nav.adoc` lists every page and every section resolves.

This satisfies issue #9's testing/validation requirements: Antora resolves the
module navigation and page links, and references are valid.

## Acceptance criteria (issue #9)

- [x] Antora module structure at `src/docs/modules/ROOT` — *Structure section*.
- [x] `nav.adoc` links to all documented pages — *Navigation section*.
- [x] Each page covers purpose, common actions, important fields, behaviour —
  *Standard page template*.
- [x] Feature docs include data ownership/profile scoping — *Shared partial*.
- [x] Sync docs explain local-first, optional sync, queue status, failure
  handling — *`sync-settings.adoc`*.
- [x] Race-time docs explain race name/meet, profile, distance, time,
  short/long course — *`race-times.adoc`*.
- [x] Clear AsciiDoc headings and examples — *Style section*.
- [x] Contributor note on adding docs — *`contributing.adoc`*.

## Risks

- **First build needs network** to fetch the Antora UI bundle and npm
  packages. Once cached, builds are offline-capable.
- **Doc accuracy drift** — pages are written from current screen code; future
  UI changes can make them stale. The `contributing.adoc` page mitigates this
  by making the update path explicit.
