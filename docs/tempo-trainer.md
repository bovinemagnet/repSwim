# Tempo Trainer

Tempo Trainer is an offline-first training screen for configuring and running
rhythm cues for swim cadence, wall pacing, and breathing rhythm. It is available
from the Home screen quick actions and directly at the `/tempo` route.

The current implementation is an MVP for issue 13. It provides configurable
cue timing, phone cue outputs, reusable templates, basic result logging, and CSV
export for entered split data.

## Modes

Tempo Trainer supports three modes.

### Stroke Rate

Stroke Rate mode cues a regular beat from the configured strokes per minute.

Example:

- Stroke/min: `60`
- Cue interval: `1.00` second
- Accent every: `4`

This mode is intended for cadence work, such as holding a target hand-entry or
stroke rhythm.

### Lap Pace

Lap Pace mode cues each target wall split from the configured pool length,
target distance, and target time.

Example:

- Pool m: `25`
- Target m: `100`
- Target sec: `88`
- Cue interval: `22.00` seconds

This mode is intended for "stay with the beep" pacing against a wall target.

### Breath Pattern

Breath Pattern mode cues a breathing rhythm from the configured stroke rate and
`Breathe every` value.

Example:

- Stroke/min: `60`
- Breathe every: `3`
- Cue interval: `3.00` seconds

Breath Pattern mode is for rhythm cues only. It is not a breath-hold challenge
or hypoxic set builder.

## Session Setup

The screen exposes these inputs:

- `Pool m`: pool length in meters.
- `Target m`: target session or repeat distance in meters.
- `Target sec`: target time in seconds.
- `Stroke/min`: target stroke rate.
- `Breathe every`: number of strokes between breath cues.
- `Accent every`: beat interval for accent cues.

All numeric configuration values must be positive. Invalid setup values show
`Enter valid tempo values.` and are not applied.

## Cue Outputs

Cue output settings are configured with chips:

- `Sound`: plays a platform system sound on each cue.
- `Vibration`: triggers light haptic feedback for normal cues and heavier
  haptic feedback for accent cues.
- `Visual flash`: briefly changes the run panel background on each cue.
- `Voice alert`: sends a semantic announcement for assistive voice output.

The cue player is implemented behind `TempoCuePlayer` so tests can inject a fake
cue player without calling platform channels.

Current timing uses Flutter timers. This is adequate for the MVP but is not a
specialized low-drift audio scheduler.

## Safety Behavior

Breath Pattern mode requires explicit safety acknowledgement when `Breathe every`
is `5` or higher. Until acknowledged, the Start button is disabled.

The safety copy shown in the app states that breath cues are for rhythm only and
should not be used for max breath holds, underwater distance challenges, or
unsupervised hypoxic sets.

## Running A Session

The run panel shows:

- Current cue label, such as `Stroke cue`, `Wall cue`, `Breathe cue`, or
  `Accent cue`.
- Cue interval.
- Target wall split.
- Target pace per 100m.
- Beat count.
- Elapsed cue time.

Controls:

- `Start`: starts cue playback.
- `Pause`: pauses cue playback.
- `Reset`: stops playback and clears beat count and elapsed cue time.

## Templates

Tempo configurations can be saved as reusable templates. A template stores:

- Name.
- Mode.
- Pool length.
- Target distance.
- Target time.
- Stroke rate.
- Breath interval.
- Cue output settings.
- Accent interval.
- Safety acknowledgement state.

Templates are stored in SQLite in `tempo_templates` and are scoped to the current
swimmer profile. Template changes are also queued for sync using the local sync
queue.

## Session Results

The Session Result panel lets the user enter:

- Actual splits in seconds, comma separated.
- Stroke counts, comma separated.
- RPE from 1 to 10.
- Notes.

At least one actual split is required to save a result. RPE must be blank or in
the range `1..10`.

Saved results are stored in SQLite in `tempo_session_results` and are scoped to
the current swimmer profile. Result creates and deletes are queued for sync.

The `History` action in the Tempo Trainer app bar opens the saved result list.
Tempo History shows saved results newest first, and each row opens a detail view
with target pace, split errors, stroke counts, RPE, and notes. Saved results can
be deleted from the detail view after confirmation.

History and detail views do not play live tempo cues, so they do not introduce
additional audio, vibration, or visual flash behavior.

## CSV Export

The `CSV` button copies CSV for the currently entered split data to the system
clipboard. The CSV includes:

- Session id.
- Mode.
- Split index.
- Target split in milliseconds.
- Actual split in milliseconds.
- Split error in milliseconds.
- Stroke count.

CSV export does not require saving the result first.

## Persistence

Tempo Trainer adds database version `12` with these tables:

- `tempo_templates`
- `tempo_session_results`

The training template DAO owns tempo template and tempo result persistence
alongside the existing interval and dryland template storage.

## Tests

Current coverage includes:

- Unit tests for tempo conversions, split comparison, breath safety thresholds,
  and CSV export.
- Provider tests for cue scheduling, template save/delete, result save, and sync
  queue behavior.
- Widget tests for controls, safety acknowledgement, validation, template save,
  result save, history, detail, delete, and CSV copy.
- DAO integration tests for offline persistence and profile isolation.
- Migration tests for upgrading older database versions to the tempo schema.

## Current Limitations

The MVP intentionally does not include:

- Low-drift audio scheduling.
- CSS pace preset generation.
- Stroke-rate ramp tests.
- USRPT race-pace presets and fail counters.
- Per-rep or per-segment race modelling.
- Wearable, Bluetooth, or external device integration.

Follow-up issues:

- #16 Low-drift audio scheduling.
- #17 CSS pace preset builder.
- #18 USRPT race-pace preset with fail counter.
- #19 Stroke-rate ramp test preset.
