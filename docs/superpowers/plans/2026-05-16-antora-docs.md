# Antora Documentation Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Antora documentation component at `src/docs/` that documents every repSwim app page and major feature, with a self-contained npm build.

**Architecture:** A single Antora component (`repswim`) with one `ROOT` module holding 13 feature pages and grouped navigation. The build runs via a committed npm toolchain (`@antora/cli` + `@antora/site-generator`) driven by a root `antora-playbook.yml`. Page tasks are independent and may be dispatched in parallel to the `asciidoc-antora-writer` subagent; the two migration tasks convert existing Markdown docs.

**Tech Stack:** Antora 3.1, AsciiDoc, npm, Node.js 26.

---

## Conventions (read once before starting)

### Validation is the test

There are no unit tests for documentation. The verification step for every
content task is a clean Antora build:

```bash
npx antora antora-playbook.yml
```

"Clean" means the command exits 0 with **no** warnings about unresolved page
references, missing partials, or broken `xref:` targets. Treat any such
warning as a failing test — fix it before committing.

### Standard feature-page skeleton

Every feature page (Tasks 3–11) follows this AsciiDoc skeleton. Fill each
section from the screen source named in the task; do not invent UI that is
not in the code.

```adoc
= <Feature name>

<One- or two-sentence statement of what the feature is for.>

== Reaching this page

<The route (e.g. `/analytics`) and where the screen sits in app navigation
— bottom navigation, navigation rail, or linked from another screen.>

== Common actions

<The main workflows on the screen(s), as a short list or subsections.>

== Important fields

<Each input the user sets, and what it means. Use a definition list.>

== Expected behaviour

<What happens on save / calculation / navigation, and notable edge cases.>
```

Pages that hold per-profile data also include, after "Reaching this page":

```adoc
include::partial$profile-scoping.adoc[]
```

### Style rules

- British spelling (initialise, behaviour, colour, recognise, organise).
- Sentence-case headings (`= Page title`, not `= Page Title`).
- Do not skip heading levels (`=` → `==` → `===`).
- Inter-page links use `xref:page.adoc[]`, never relative file paths.
- Source/code blocks tag their language (`[source,bash]`).
- Admonitions (NOTE/TIP/IMPORTANT/WARNING) only where they earn their place.

### Source-of-truth screen files

| Feature | Screen source file(s) | Route |
|---------|----------------------|-------|
| Profiles | `lib/features/profiles/presentation/screens/profiles_screen.dart` | `/profiles` |
| Swim sessions | `lib/features/swim/presentation/screens/swim_sessions_screen.dart`, `swim_session_detail_screen.dart`, `swim_session_screen.dart` | `/sessions`, `/sessions/:id`, `/swim`, `/sessions/:id/edit` |
| Stopwatch | `lib/features/stopwatch/presentation/screens/stopwatch_screen.dart` | `/stopwatch` |
| Interval timer | `lib/features/stopwatch/presentation/screens/interval_timer_screen.dart` | `/intervals` |
| Tempo trainer | `lib/features/tempo/presentation/screens/tempo_trainer_screen.dart`, `tempo_results_screen.dart` | `/tempo`, `/tempo/results` |
| Analytics | `lib/features/analytics/presentation/screens/analytics_screen.dart` | `/analytics` |
| Personal bests | `lib/features/pb/presentation/screens/pb_screen.dart` | `/pb` |
| Race times | `lib/features/race/presentation/screens/race_times_screen.dart` | `/races` |
| Qualification standards | `lib/features/race/presentation/screens/qualification_standards_screen.dart` | `/qualification-standards` |
| Dryland | `lib/features/dryland/presentation/screens/dryland_screen.dart` | `/dryland` |
| Sync settings | `lib/features/settings/presentation/screens/sync_settings_screen.dart` | `/settings/sync` |
| Home (in index) | `lib/features/home/presentation/screens/home_screen.dart` | `/home` |

---

## Task 1: Scaffold the Antora component and build toolchain

**Files:**
- Create: `package.json`
- Create: `antora-playbook.yml`
- Create: `src/docs/antora.yml`
- Create: `src/docs/modules/ROOT/nav.adoc`
- Create: `src/docs/modules/ROOT/pages/index.adoc`
- Create: `src/docs/modules/ROOT/images/.gitkeep`
- Create: `src/docs/modules/ROOT/partials/.gitkeep`
- Modify: `.gitignore`

- [ ] **Step 1: Create `package.json`**

```json
{
  "name": "repswim-docs",
  "version": "0.0.0",
  "private": true,
  "description": "Antora documentation build for repSwim",
  "scripts": {
    "docs:build": "antora antora-playbook.yml"
  },
  "devDependencies": {
    "@antora/cli": "^3.1.0",
    "@antora/site-generator": "^3.1.0"
  }
}
```

- [ ] **Step 2: Create `antora-playbook.yml`**

```yaml
site:
  title: repSwim Documentation
  start_page: repswim::index.adoc
content:
  sources:
    - url: .
      start_path: src/docs
      branches: HEAD
ui:
  bundle:
    url: https://gitlab.com/antora/antora-ui-default/-/jobs/artifacts/HEAD/raw/build/ui-bundle.zip?job=bundle-stable
    snapshot: true
output:
  dir: ./build/docs/site
```

`branches: HEAD` lets the build pick up uncommitted edits on the current
branch during development.

- [ ] **Step 3: Create `src/docs/antora.yml`**

```yaml
name: repswim
title: repSwim
version: '0.0.0'
nav:
  - modules/ROOT/nav.adoc
```

- [ ] **Step 4: Create `src/docs/modules/ROOT/nav.adoc`** (index only for now)

```adoc
* xref:index.adoc[Overview]
```

- [ ] **Step 5: Create `src/docs/modules/ROOT/pages/index.adoc`** (placeholder)

```adoc
= repSwim documentation

Documentation for the repSwim swimming training app.
```

- [ ] **Step 6: Create placeholder-keeper files**

Create `src/docs/modules/ROOT/images/.gitkeep` and
`src/docs/modules/ROOT/partials/.gitkeep` as empty files so the directories
are tracked.

- [ ] **Step 7: Add `node_modules/` to `.gitignore`**

Append to `.gitignore` (the `build/` directory is already ignored at line 43,
which covers `build/docs/site`):

```
# Antora documentation build
node_modules/
```

- [ ] **Step 8: Install the Antora toolchain**

Run: `npm install`
Expected: `node_modules/` populated, `package-lock.json` created, exit 0.

NOTE: Node.js 26 is newer than Antora 3.1's officially tested range. If
`npm install` or the build fails on an engine check, pin to the latest
`@antora/cli` and `@antora/site-generator` 3.x that resolve cleanly and
record the chosen versions in `package.json`.

- [ ] **Step 9: Run the build to verify the scaffold**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings; `build/docs/site/index.html` exists.

- [ ] **Step 10: Commit**

```bash
git add package.json package-lock.json antora-playbook.yml src/docs .gitignore
git commit -m "build: scaffold Antora documentation component (#9)"
```

---

## Task 2: Add the shared profile-scoping partial

**Files:**
- Create: `src/docs/modules/ROOT/partials/profile-scoping.adoc`
- Delete: `src/docs/modules/ROOT/partials/.gitkeep`

- [ ] **Step 1: Read the source**

Read `lib/features/profiles/` (domain and data layers) to confirm how records
are associated with a profile.

- [ ] **Step 2: Write `partials/profile-scoping.adoc`**

A reusable admonition explaining that the data on the page belongs to the
currently selected profile and switching profiles changes what is shown. Keep
it to a NOTE admonition of 2–3 sentences. Example shape:

```adoc
[NOTE]
====
This data is scoped to the *active profile*. Switching profiles on the
xref:profiles.adoc[Profiles] page changes which records are shown and where
new entries are saved.
====
```

- [ ] **Step 3: Remove the placeholder**

Run: `git rm src/docs/modules/ROOT/partials/.gitkeep`

- [ ] **Step 4: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings. (An unused partial does not affect the build.)

- [ ] **Step 5: Commit**

```bash
git add src/docs/modules/ROOT/partials
git commit -m "docs: add shared profile-scoping partial (#9)"
```

---

## Task 3: Write the Profiles page

**Files:**
- Create: `src/docs/modules/ROOT/pages/profiles.adoc`

- [ ] **Step 1: Read the source**

Read `profiles_screen.dart` (path in the Conventions table) and the profiles
domain entities.

- [ ] **Step 2: Write `pages/profiles.adoc`**

Follow the standard feature-page skeleton. Document: creating, editing,
selecting, and deleting profiles; what fields a profile holds; that the
selected profile scopes all other data in the app (this page is the origin of
the `profile-scoping.adoc` concept, so explain it fully here rather than
including the partial).

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/profiles.adoc
git commit -m "docs: add Profiles page (#9)"
```

---

## Task 4: Write the Swim sessions page

**Files:**
- Create: `src/docs/modules/ROOT/pages/swim-sessions.adoc`

- [ ] **Step 1: Read the source**

Read `swim_sessions_screen.dart`, `swim_session_detail_screen.dart`, and
`swim_session_screen.dart`.

- [ ] **Step 2: Write `pages/swim-sessions.adoc`**

Follow the standard feature-page skeleton, with `== Common actions`
subsections for the three screens: browsing the session list, viewing a
session's detail, and creating/editing a session. Document the session fields
(date, distance, laps, exercises, etc. as found in the code). Add
`include::partial$profile-scoping.adoc[]` after "Reaching this page".

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/swim-sessions.adoc
git commit -m "docs: add Swim sessions page (#9)"
```

---

## Task 5: Write the Stopwatch page

**Files:**
- Create: `src/docs/modules/ROOT/pages/stopwatch.adoc`

- [ ] **Step 1: Read the source**

Read `stopwatch_screen.dart`.

- [ ] **Step 2: Write `pages/stopwatch.adoc`**

Follow the standard feature-page skeleton. Document starting/stopping,
recording laps, and what the captured times represent.

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/stopwatch.adoc
git commit -m "docs: add Stopwatch page (#9)"
```

---

## Task 6: Write the Interval timer page

**Files:**
- Create: `src/docs/modules/ROOT/pages/interval-timer.adoc`

- [ ] **Step 1: Read the source**

Read `interval_timer_screen.dart`.

- [ ] **Step 2: Write `pages/interval-timer.adoc`**

Follow the standard feature-page skeleton. Document configuring intervals
(work/rest, repeats), starting a timer, and the audio/visual cues.

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/interval-timer.adoc
git commit -m "docs: add Interval timer page (#9)"
```

---

## Task 7: Write the Dryland training page

**Files:**
- Create: `src/docs/modules/ROOT/pages/dryland.adoc`

- [ ] **Step 1: Read the source**

Read `dryland_screen.dart`.

- [ ] **Step 2: Write `pages/dryland.adoc`**

Follow the standard feature-page skeleton. Document logging dryland workouts
and the fields each entry holds. Add
`include::partial$profile-scoping.adoc[]` after "Reaching this page" if
dryland entries are per-profile.

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/dryland.adoc
git commit -m "docs: add Dryland training page (#9)"
```

---

## Task 8: Write the Analytics page

**Files:**
- Create: `src/docs/modules/ROOT/pages/analytics.adoc`

- [ ] **Step 1: Read the source**

Read `analytics_screen.dart`.

- [ ] **Step 2: Write `pages/analytics.adoc`**

Follow the standard feature-page skeleton. Document the charts/metrics shown,
any time-range or filter controls, and where the underlying data comes from
(swim sessions). Add `include::partial$profile-scoping.adoc[]` after
"Reaching this page".

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/analytics.adoc
git commit -m "docs: add Analytics page (#9)"
```

---

## Task 9: Write the Personal bests page

**Files:**
- Create: `src/docs/modules/ROOT/pages/personal-bests.adoc`

- [ ] **Step 1: Read the source**

Read `pb_screen.dart` and the personal-bests domain/data layers.

- [ ] **Step 2: Write `pages/personal-bests.adoc`**

Follow the standard feature-page skeleton. Document adding/editing personal
bests, the `(stroke, distance)` fields, and that each `(stroke, distance)`
pair is unique (one best per combination). Add
`include::partial$profile-scoping.adoc[]` after "Reaching this page".

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/personal-bests.adoc
git commit -m "docs: add Personal bests page (#9)"
```

---

## Task 10: Write the Race times page

**Files:**
- Create: `src/docs/modules/ROOT/pages/race-times.adoc`

- [ ] **Step 1: Read the source**

Read `race_times_screen.dart` and the race domain/data layers.

- [ ] **Step 2: Write `pages/race-times.adoc`**

Follow the standard feature-page skeleton. The `== Important fields` section
**must** cover every field, since this is an explicit acceptance criterion:
race name / meet, person / profile, distance, time, and short-course /
long-course selection. Add `include::partial$profile-scoping.adoc[]` after
"Reaching this page".

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/race-times.adoc
git commit -m "docs: add Race times page (#9)"
```

---

## Task 11: Write the Sync settings page

**Files:**
- Create: `src/docs/modules/ROOT/pages/sync-settings.adoc`

- [ ] **Step 1: Read the source**

Read `sync_settings_screen.dart` and `lib/core/sync/` (the sync client,
`sync_queue_item.dart`, `sync_queue_dao.dart`).

- [ ] **Step 2: Write `pages/sync-settings.adoc`**

Follow the standard feature-page skeleton. The page **must** explain, since
these are explicit acceptance criteria:

- repSwim is offline-first — all data lives locally and the app is fully
  usable with no network.
- Sync is optional and there is currently no live remote backend; mutations
  are queued for a future service.
- Queue status — how the user sees pending/queued items.
- Failure handling — what happens when a sync attempt cannot complete.

Use a NOTE admonition for the "no live backend yet" point.

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/pages/sync-settings.adoc
git commit -m "docs: add Sync settings page (#9)"
```

---

## Task 12: Migrate the Tempo trainer page from Markdown

**Files:**
- Create: `src/docs/modules/ROOT/pages/tempo-trainer.adoc`
- Delete: `docs/tempo-trainer.md`

- [ ] **Step 1: Read the existing doc and source**

Read `docs/tempo-trainer.md` (261 lines) and the screens
`tempo_trainer_screen.dart` and `tempo_results_screen.dart`.

- [ ] **Step 2: Write `pages/tempo-trainer.adoc`**

Convert `docs/tempo-trainer.md` to AsciiDoc:

- Markdown `#`/`##`/`###` headings become AsciiDoc `=`/`==`/`===`.
- Fenced code blocks become `[source,<lang>]` + `----` delimited blocks.
- Markdown links become `xref:` for internal targets or `link:` for external.
- Preserve the existing content and ordering.

Then reconcile against the current screens: ensure the page also covers the
tempo results history (`tempo_results_screen.dart`) and the presets — USRPT
race pace and the stroke-rate ramp. Update any wording that no longer matches
the current UI. Add `include::partial$profile-scoping.adoc[]` after the
opening section if tempo results are per-profile.

- [ ] **Step 3: Delete the old Markdown file**

Run: `git rm docs/tempo-trainer.md`

- [ ] **Step 4: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 5: Commit**

```bash
git add src/docs/modules/ROOT/pages/tempo-trainer.adoc docs/tempo-trainer.md
git commit -m "docs: migrate Tempo trainer docs to Antora (#9)"
```

---

## Task 13: Migrate the Qualification standards page from Markdown

**Files:**
- Create: `src/docs/modules/ROOT/pages/qualification-standards.adoc`
- Delete: `docs/race-qualification-standards.md`

- [ ] **Step 1: Read the existing doc and source**

Read `docs/race-qualification-standards.md` (52 lines) and
`qualification_standards_screen.dart`.

- [ ] **Step 2: Write `pages/qualification-standards.adoc`**

Convert `docs/race-qualification-standards.md` to AsciiDoc using the same
Markdown→AsciiDoc rules as Task 12. Reconcile against
`qualification_standards_screen.dart` so the page describes the current
age-based medal standards view. Follow the standard feature-page skeleton
headings where the migrated content does not already provide them.

- [ ] **Step 3: Delete the old Markdown file**

Run: `git rm docs/race-qualification-standards.md`

- [ ] **Step 4: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 5: Commit**

```bash
git add src/docs/modules/ROOT/pages/qualification-standards.adoc docs/race-qualification-standards.md
git commit -m "docs: migrate Qualification standards docs to Antora (#9)"
```

---

## Task 14: Write the Contributing page

**Files:**
- Create: `src/docs/modules/ROOT/pages/contributing.adoc`

- [ ] **Step 1: Write `pages/contributing.adoc`**

A short contributor guide covering how to add documentation for a new app
page or feature:

1. Create a new `.adoc` file under `src/docs/modules/ROOT/pages/`.
2. Follow the standard page structure (purpose, reaching it, common actions,
   important fields, expected behaviour).
3. Add an `xref:` entry to `src/docs/modules/ROOT/nav.adoc` in the correct
   section.
4. Reuse `partials/profile-scoping.adoc` for pages with per-profile data.
5. Build and validate with `npm run docs:build` (or
   `npx antora antora-playbook.yml`) — the build must be warning-free.

Include the build command in a `[source,bash]` block.

- [ ] **Step 2: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings.

- [ ] **Step 3: Commit**

```bash
git add src/docs/modules/ROOT/pages/contributing.adoc
git commit -m "docs: add contributor guide page (#9)"
```

---

## Task 15: Build the grouped navigation and final landing page

**Files:**
- Modify: `src/docs/modules/ROOT/nav.adoc`
- Modify: `src/docs/modules/ROOT/pages/index.adoc`

- [ ] **Step 1: Replace `nav.adoc` with the full grouped navigation**

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

- [ ] **Step 2: Replace `index.adoc` with the full landing page**

Rewrite `index.adoc` so it:

- Introduces repSwim as an offline-first swimming training app.
- Describes the Home dashboard (from `home_screen.dart`) as the app's entry
  point.
- Briefly explains the offline-first data model (local SQLite, no required
  backend).
- Links to each documentation section with `xref:` to the section's primary
  pages (e.g. `xref:profiles.adoc[Profiles]`,
  `xref:swim-sessions.adoc[Swim sessions]`, etc.).

Every `xref:` target must be a page created in Tasks 3–14.

- [ ] **Step 3: Build**

Run: `npx antora antora-playbook.yml`
Expected: exit 0, no warnings. All 13 nav entries resolve.

- [ ] **Step 4: Commit**

```bash
git add src/docs/modules/ROOT/nav.adoc src/docs/modules/ROOT/pages/index.adoc
git commit -m "docs: add grouped navigation and landing page (#9)"
```

---

## Task 16: Final validation

**Files:** none (verification only)

- [ ] **Step 1: Clean build from scratch**

```bash
rm -rf build/docs/site
npx antora antora-playbook.yml
```

Expected: exit 0, **zero** warnings. Confirm `build/docs/site/index.html` and
one HTML file per page exist.

- [ ] **Step 2: Verify navigation completeness**

Confirm `nav.adoc` references all 13 pages and that no `pages/*.adoc` file is
missing from `nav.adoc`.

Run: `ls src/docs/modules/ROOT/pages`
Expected: `analytics.adoc contributing.adoc dryland.adoc index.adoc
interval-timer.adoc personal-bests.adoc profiles.adoc
qualification-standards.adoc race-times.adoc stopwatch.adoc
swim-sessions.adoc sync-settings.adoc tempo-trainer.adoc` (13 files).

- [ ] **Step 3: British-spelling pass**

Run: `grep -rniE 'behavior|color|organize|optimize|analyze|recognize|customize' src/docs/modules/ROOT/pages src/docs/modules/ROOT/partials`
Expected: no matches in prose. (If a match is a code identifier or command
name such as `flutter analyze`, leave it; otherwise correct to British
spelling.)

- [ ] **Step 4: Confirm old Markdown docs are gone**

Run: `ls docs/tempo-trainer.md docs/race-qualification-standards.md`
Expected: both report "No such file or directory" — they were removed in
Tasks 12 and 13.

- [ ] **Step 5: Commit any fixes**

If Steps 1–4 required corrections, commit them:

```bash
git add -A
git commit -m "docs: final validation fixes for Antora docs (#9)"
```

If no corrections were needed, no commit is necessary.

---

## Self-review notes

- **Spec coverage:** Antora structure (Task 1), `nav.adoc` linking all pages
  (Tasks 1, 15), per-page content (Tasks 3–14), profile scoping (Task 2 +
  includes), sync local-first/queue/failure (Task 11), race-time fields
  (Task 10), contributor note (Task 14), build validation (every task +
  Task 16), Markdown migration with deletion (Tasks 12, 13). All spec
  sections map to a task.
- **Out of scope, as designed:** screenshots (empty `images/` dir created in
  Task 1), Gradle integration, and `docs/design|plans|ideas/` planning docs
  (untouched).
- **Open design point carried into implementation:** `antora.yml` uses
  `version: '0.0.0'`; switch to unversioned `~` only if requested.
