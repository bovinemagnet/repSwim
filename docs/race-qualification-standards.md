# Race Qualification Standards

Race qualification standards live under the Race Times feature. From the Race
Times screen, use the qualification standards action in the app bar to open the
Qualification Standards screen.

## Manual Medal Standards

Manual standards are swimmer-profile scoped. Each standard stores:

- age
- distance
- stroke
- course
- gold time
- silver time
- bronze time

Gold must be the fastest threshold, followed by silver and then bronze. The app
stores times as centiseconds and shows them in the same `mm:ss.cc` format used
by race times.

The screen includes a Medal standards by age panel when manual standards exist.
Use the age selector to view the gold, silver, and bronze thresholds for that
age in an event table. The table is sorted by age, distance, stroke, and course.

## Race Matching

Qualification matching uses the active swimmer profile, age, distance, stroke,
and course. A race time earns the best qualifying tier it meets:

- Gold when the race time is at or below the gold threshold.
- Silver when it misses gold but is at or below the silver threshold.
- Bronze when it misses silver but is at or below the bronze threshold.

The matching service ignores standards with invalid medal ordering.

## Imported Meet Standards

Imported meet standards are separate from manual medal standards. The current
import source is `2026/27 Uncloud Victorian Metro SC Championships`, extracted
from `docs/qualify/qualify_time.pdf`.

Imported standards can include sex, age bands, single qualifying times, MC point
thresholds, and relay standards. They are stored in their own table and are not
converted into manual gold/silver/bronze thresholds.

## Sync

Manual standards queue create, update, and delete mutations in the local sync
queue as `qualification_standard` payloads. Imported meet standards are local
reference data and are not currently queued for remote sync.
