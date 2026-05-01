# Code Review Implementation Plan

This plan converts the latest code review findings into implementable work. The order is intentional: fix data-loss and crash risks first, then harden sync and migrations, then fill product gaps.

## Phase 1: Correctness Fixes

### 1. Validate Swim Lap Time Before Save

Problem: a new lap is prefilled with distance only, so tapping Save can force-unwrap a null duration and crash.

Implementation:
- Require each lap to have a duration greater than zero.
- Add validators for minute/second fields or a form-level validation pass before constructing `Lap`.
- Keep preferred pool length as the default distance.

Acceptance criteria:
- Add Lap then Save shows a validation error instead of crashing.
- Existing manual entry behavior still updates totals.
- Widget test covers “distance-only lap cannot save”.

### 2. Make Swim Session Persistence Atomic

Problem: `SwimSessionDao.insertSession` writes the session and laps separately. A lap insert failure can leave partial data.

Implementation:
- Wrap session insert and lap inserts in a single SQLite transaction.
- Use the transaction object for both parent and child writes.
- Preserve current conflict behavior.

Acceptance criteria:
- A failed lap write rolls back the session.
- DAO test covers rollback behavior.

## Phase 2: Sync Queue Hardening

### 3. Make Queue Replay Ordering Deterministic

Problem: queue ordering uses `created_at` only; records created in the same millisecond can replay out of order.

Implementation:
- Add a monotonic `sequence` column or order by `created_at ASC, rowid ASC`.
- Prefer schema-backed `sequence` if backend replay order will matter.

Acceptance criteria:
- Queue records replay in insertion order.
- Test covers multiple records with identical timestamps.

### 4. Replace Batch Success With Per-Item Sync Results

Problem: `pushChanges(pending)` marks all items complete when the call returns, even if a future backend partially accepts a batch.

Implementation:
- Change `SyncBackendClient.pushChanges` to return per-item results.
- Mark only acknowledged items complete.
- Mark rejected/failed items failed with error details.

Acceptance criteria:
- Partial success leaves failed items retryable.
- Sync service test covers success, partial failure, and thrown error.

### 5. Surface Queue Write Failures

Problem: queue write exceptions are swallowed, so data can become unsyncable without visibility.

Implementation:
- Keep local writes non-blocking.
- Record queue-write failures in a local status provider, log, or app setting.
- Show a warning in Sync Settings when queueing has failed.

Acceptance criteria:
- Local writes still succeed when queue enqueue fails.
- Sync Settings exposes the failure state.

## Phase 3: Startup and Settings Reliability

### 6. Remove Active Profile Startup Race

Problem: saved profile selection loads asynchronously while profile-scoped providers may fall back to the first profile.

Implementation:
- Introduce an app bootstrap state that waits for saved profile selection and profile list before enabling profile-scoped writes.
- Show a lightweight loading state during bootstrap.
- Ensure archived/missing saved profile falls back deterministically.

Acceptance criteria:
- New session cannot be saved under the wrong profile during startup.
- Provider test covers saved, missing, and archived selected profiles.

### 7. Persist Sync Mode

Problem: `syncModeProvider` resets to `localOnly` on app restart.

Implementation:
- Store selected sync mode in `app_settings`.
- Bootstrap mode on app startup.
- Keep `localOnly` as the default.

Acceptance criteria:
- Changing sync mode survives app restart.
- Widget/provider tests cover mode persistence.

## Phase 4: Migration and Integration Coverage

### 8. Add SQLite Migration Tests

Problem: database version `6` has several upgrade paths with no migration tests.

Implementation:
- Use sqflite FFI test databases.
- Create representative older schemas for versions 1, 3, 4, and 5.
- Open with current `AppDatabase` migration logic and assert current schema/data.

Acceptance criteria:
- `sync_queue.profile_id` exists after upgrade.
- Template tables exist after upgrade.
- `app_settings` exists after upgrade.
- Existing session/PB/profile data survives.

### 9. Add DAO Integration Tests

Implementation:
- Test swim session insert/delete with laps.
- Test dryland workout update replaces exercises.
- Test template insert/delete cascades.
- Test sync queue summary and retry count.

Acceptance criteria:
- DAO behavior is verified against real SQLite, not only mocks.

## Phase 5: Product Completion Gaps

### 10. Add Swim Session Editing

Implementation:
- Reuse or adapt `SwimSessionScreen` for editing existing sessions.
- Update session/laps transactionally.
- Rebuild PBs after edits.
- Queue update mutation.

Acceptance criteria:
- User can edit date/stroke/notes/laps.
- PBs remain correct after edit.
- Widget tests cover edit flow.

### 11. Desktop Polish

Implementation:
- Add analytics wide layout with multi-column sections.
- Consider session table/detail split view for desktop widths.
- Verify Windows and macOS builds on those platforms.

Acceptance criteria:
- Analytics does not feel like a stretched mobile screen on desktop.
- Session history supports efficient review on wide displays.

### 12. Backend Sync Foundation

Implementation:
- Define remote API DTOs.
- Implement auth/account placeholders only when backend contract exists.
- Implement push/pull client and conflict handling.

Acceptance criteria:
- App remains fully usable offline.
- Backend sync is opt-in.
- Conflicts have deterministic resolution rules.

## Suggested Implementation Order

1. Lap validation crash fix.
2. Swim session transaction.
3. Migration and DAO tests.
4. Sync queue ordering and per-item results.
5. Profile bootstrap and sync mode persistence.
6. Swim session editing.
7. Desktop polish.
8. Backend sync client.
