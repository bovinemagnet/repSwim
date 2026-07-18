# Coach Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a coach mode to repSwim that lets a swimmer share selected profiles and data categories with a coach through a sealed on-device read-only view and a PDF export.

**Architecture:** A new `lib/features/coach/` module (domain/data/presentation) backed by a new `coach_shares` SQLite table. A single `CoachReportBuilder` assembles the shared data once; both the on-device coach view and the `CoachPdfBuilder` consume that report so they cannot diverge.

**Tech Stack:** Flutter, Dart, Riverpod, sqflite, go_router; new dependencies `pdf` and `printing`.

---

## Conventions (read once before starting)

### Testing

The project uses `flutter_test`. `test/` mirrors `lib/` one-for-one. Run the
whole suite with `flutter test`; a single file with
`flutter test test/path/to/file.dart`. The pre-PR gate is
`flutter analyze && flutter test`.

DAO/database tests use the in-memory database: `AppDatabase.test()` (see
`lib/database/app_database.dart`) — each test constructs a fresh instance.
See `test/database/dao_integration_test.dart` for the established pattern.

### Codebase patterns

- **DAOs** live in `lib/database/daos/`, take an `AppDatabase` in a `const`
  constructor, and obtain the `Database` via `await _db.database`.
- **Entities** are immutable, in `domain/entities/`, `PascalCase` types,
  `snake_case.dart` files. British spelling in code and comments.
- **Providers** live in a feature's `presentation/providers/`, named
  `<noun>Provider`. DAO providers do `Provider((ref) => Dao(AppDatabase.instance))`.
- **Lint:** `prefer_const_constructors` and `prefer_const_literals` are
  enforced — the build fails otherwise. Run `dart format lib test` before
  committing.
- **Commits:** conventional (`feat:`, `test:`, `docs:`). No mention of AI
  tooling; no co-author trailers.

### Category set

`CoachShareCategory` has exactly eight values throughout this plan:
`profileDetails`, `goals`, `notes`, `swimSessions`, `raceTimes`,
`personalBests`, `analytics`, `dryland`.

---

## Task 1: Add PDF dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add `pdf` and `printing` to dependencies**

In `pubspec.yaml`, under `dependencies:`, add after `path: ^1.9.0`:

```yaml
  pdf: ^3.11.0
  printing: ^5.13.0
```

- [ ] **Step 2: Fetch packages**

Run: `dart pub get`
Expected: exit 0, both packages resolved.

NOTE: If a version does not resolve against the Dart 3 / Flutter SDK in this
environment, pick the latest `pdf` 3.x and `printing` 5.x that resolve and
record the chosen versions.

- [ ] **Step 3: Verify the project still analyses**

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add pdf and printing dependencies for coach mode (#10)"
```

---

## Task 2: CoachShareCategory enum

**Files:**
- Create: `lib/features/coach/domain/entities/coach_share_category.dart`
- Test: `test/features/coach/domain/coach_share_category_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';

void main() {
  group('CoachShareCategory', () {
    test('exposes eight categories', () {
      expect(CoachShareCategory.values.length, 8);
    });

    test('every category has a unique non-empty key and label', () {
      final keys = CoachShareCategory.values.map((c) => c.key).toSet();
      expect(keys.length, 8);
      for (final c in CoachShareCategory.values) {
        expect(c.key, isNotEmpty);
        expect(c.label, isNotEmpty);
      }
    });

    test('fromKey round-trips every category', () {
      for (final c in CoachShareCategory.values) {
        expect(CoachShareCategory.fromKey(c.key), c);
      }
    });

    test('fromKey returns null for an unknown key', () {
      expect(CoachShareCategory.fromKey('not_a_category'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/domain/coach_share_category_test.dart`
Expected: FAIL — file/type does not exist.

- [ ] **Step 3: Implement the enum**

```dart
/// A category of swimmer data that can be shared with a coach.
///
/// [key] is the stable identifier persisted in the database; [label] is the
/// human-readable name shown in the UI.
enum CoachShareCategory {
  profileDetails('profile_details', 'Profile details'),
  goals('goals', 'Goals'),
  notes('notes', 'Notes'),
  swimSessions('swim_sessions', 'Swim sessions'),
  raceTimes('race_times', 'Race times'),
  personalBests('personal_bests', 'Personal bests'),
  analytics('analytics', 'Analytics'),
  dryland('dryland', 'Dryland training');

  const CoachShareCategory(this.key, this.label);

  final String key;
  final String label;

  /// Returns the category with the given [key], or null if none matches.
  static CoachShareCategory? fromKey(String key) {
    for (final category in values) {
      if (category.key == key) return category;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/domain/coach_share_category_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/domain/entities/coach_share_category.dart test/features/coach/domain/coach_share_category_test.dart
git commit -m "feat: add CoachShareCategory enum (#10)"
```

---

## Task 3: CoachShare entity

**Files:**
- Create: `lib/features/coach/domain/entities/coach_share.dart`
- Test: `test/features/coach/domain/coach_share_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';

void main() {
  group('CoachShare', () {
    test('a profile with no row is not sharing anything', () {
      const share = CoachShare(profileId: 'p1');
      expect(share.enabled, isFalse);
      expect(share.hasActiveSharing, isFalse);
      expect(share.isShared(CoachShareCategory.goals), isFalse);
    });

    test('isShared requires both the master flag and the category', () {
      const disabled = CoachShare(
        profileId: 'p1',
        sharedCategories: {CoachShareCategory.goals},
      );
      expect(disabled.isShared(CoachShareCategory.goals), isFalse,
          reason: 'master flag off means nothing is shared');

      const enabled = CoachShare(
        profileId: 'p1',
        enabled: true,
        sharedCategories: {CoachShareCategory.goals},
      );
      expect(enabled.isShared(CoachShareCategory.goals), isTrue);
      expect(enabled.isShared(CoachShareCategory.notes), isFalse);
    });

    test('withCategory and withoutCategory return updated copies', () {
      const base = CoachShare(profileId: 'p1', enabled: true);
      final added = base.withCategory(CoachShareCategory.notes);
      expect(added.sharedCategories, {CoachShareCategory.notes});
      expect(base.sharedCategories, isEmpty, reason: 'original unchanged');

      final removed = added.withoutCategory(CoachShareCategory.notes);
      expect(removed.sharedCategories, isEmpty);
    });

    test('activeCategories is empty when the master flag is off', () {
      const share = CoachShare(
        profileId: 'p1',
        sharedCategories: {CoachShareCategory.goals},
      );
      expect(share.activeCategories, isEmpty);
    });

    test('hasActiveSharing is true only when enabled with a category', () {
      const enabledNoCategories = CoachShare(profileId: 'p1', enabled: true);
      expect(enabledNoCategories.hasActiveSharing, isFalse);

      const enabledWithCategory = CoachShare(
        profileId: 'p1',
        enabled: true,
        sharedCategories: {CoachShareCategory.dryland},
      );
      expect(enabledWithCategory.hasActiveSharing, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/domain/coach_share_test.dart`
Expected: FAIL — file/type does not exist.

- [ ] **Step 3: Implement the entity**

```dart
import 'coach_share_category.dart';

/// The coach-sharing configuration for a single swimmer profile.
///
/// Sharing is opt-in: nothing is shared unless [enabled] is true *and* the
/// category is present in [sharedCategories].
class CoachShare {
  const CoachShare({
    required this.profileId,
    this.enabled = false,
    this.sharedCategories = const {},
  });

  final String profileId;
  final bool enabled;
  final Set<CoachShareCategory> sharedCategories;

  /// Whether [category] is actually shared (master flag on and ticked).
  bool isShared(CoachShareCategory category) =>
      enabled && sharedCategories.contains(category);

  /// The categories actually shared right now — empty when [enabled] is false.
  Set<CoachShareCategory> get activeCategories =>
      enabled ? Set.unmodifiable(sharedCategories) : const {};

  /// True when this profile shares at least one category with a coach.
  bool get hasActiveSharing => enabled && sharedCategories.isNotEmpty;

  CoachShare withCategory(CoachShareCategory category) => copyWith(
        sharedCategories: {...sharedCategories, category},
      );

  CoachShare withoutCategory(CoachShareCategory category) => copyWith(
        sharedCategories: {...sharedCategories}..remove(category),
      );

  CoachShare copyWith({
    bool? enabled,
    Set<CoachShareCategory>? sharedCategories,
  }) {
    return CoachShare(
      profileId: profileId,
      enabled: enabled ?? this.enabled,
      sharedCategories: sharedCategories ?? this.sharedCategories,
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/domain/coach_share_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/domain/entities/coach_share.dart test/features/coach/domain/coach_share_test.dart
git commit -m "feat: add CoachShare entity (#10)"
```

---

## Task 4: Database migration to v13 (coach_shares table)

**Files:**
- Modify: `lib/core/constants/app_constants.dart` (line 13: `kDbVersion`)
- Modify: `lib/database/app_database.dart`
- Test: `test/database/coach_shares_migration_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';

void main() {
  test('coach_shares table exists with the expected columns', () async {
    final db = AppDatabase.test();
    final database = await db.database;

    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='coach_shares'",
    );
    expect(tables, hasLength(1), reason: 'coach_shares table must exist');

    final columns = await database.rawQuery('PRAGMA table_info(coach_shares)');
    final names = columns.map((row) => row['name'] as String).toSet();
    expect(names, containsAll(<String>[
      'profile_id',
      'enabled',
      'shared_categories_json',
      'updated_at',
    ]));

    await db.close();
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/database/coach_shares_migration_test.dart`
Expected: FAIL — no `coach_shares` table.

- [ ] **Step 3: Bump the schema version**

In `lib/core/constants/app_constants.dart`, change line 13 from
`const int kDbVersion = 12;` to `const int kDbVersion = 13;`.

- [ ] **Step 4: Add the table creator and wire it into create/upgrade**

In `lib/database/app_database.dart`, add this method alongside the other
`_createXTable` methods:

```dart
  Future<void> _createCoachSharesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS coach_shares (
        profile_id TEXT PRIMARY KEY,
        enabled INTEGER NOT NULL DEFAULT 0,
        shared_categories_json TEXT NOT NULL DEFAULT '[]',
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (profile_id)
          REFERENCES swimmer_profiles(id) ON DELETE CASCADE
      )
    ''');
  }
```

In `_onCreate`, add a call after `_createMeetQualificationStandardsTable(db);`:

```dart
    await _createCoachSharesTable(db);
```

In `_onUpgrade`, add a new branch after the `if (oldVersion < 12)` block:

```dart
    if (oldVersion < 13) {
      await _createCoachSharesTable(db);
    }
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/database/coach_shares_migration_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full database test suite for regressions**

Run: `flutter test test/database/`
Expected: PASS — the version bump must not break existing migration tests.

- [ ] **Step 7: Commit**

```bash
git add lib/core/constants/app_constants.dart lib/database/app_database.dart test/database/coach_shares_migration_test.dart
git commit -m "feat: add coach_shares table in schema v13 (#10)"
```

---

## Task 5: CoachShareDao

**Files:**
- Create: `lib/database/daos/coach_share_dao.dart`
- Test: `test/database/coach_share_dao_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/coach_share_dao.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';

void main() {
  late AppDatabase db;
  late CoachShareDao dao;

  setUp(() {
    db = AppDatabase.test();
    dao = CoachShareDao(db);
  });

  tearDown(() => db.close());

  test('getForProfile returns a disabled default when no row exists', () async {
    final share = await dao.getForProfile('local-default-profile');
    expect(share.profileId, 'local-default-profile');
    expect(share.enabled, isFalse);
    expect(share.sharedCategories, isEmpty);
  });

  test('save then getForProfile round-trips enabled state and categories',
      () async {
    const share = CoachShare(
      profileId: 'local-default-profile',
      enabled: true,
      sharedCategories: {
        CoachShareCategory.goals,
        CoachShareCategory.swimSessions,
      },
    );
    await dao.save(share);

    final loaded = await dao.getForProfile('local-default-profile');
    expect(loaded.enabled, isTrue);
    expect(loaded.sharedCategories, {
      CoachShareCategory.goals,
      CoachShareCategory.swimSessions,
    });
  });

  test('save overwrites a previous configuration', () async {
    await dao.save(const CoachShare(
      profileId: 'local-default-profile',
      enabled: true,
      sharedCategories: {CoachShareCategory.notes},
    ));
    await dao.save(const CoachShare(
      profileId: 'local-default-profile',
      enabled: false,
    ));
    final loaded = await dao.getForProfile('local-default-profile');
    expect(loaded.enabled, isFalse);
    expect(loaded.sharedCategories, isEmpty);
  });

  test('getSharedProfileIds lists only profiles with active sharing',
      () async {
    await dao.save(const CoachShare(
      profileId: 'local-default-profile',
      enabled: true,
      sharedCategories: {CoachShareCategory.goals},
    ));
    final ids = await dao.getSharedProfileIds();
    expect(ids, contains('local-default-profile'));
  });

  test('unknown category keys in storage are ignored on read', () async {
    final database = await db.database;
    await database.insert('coach_shares', {
      'profile_id': 'local-default-profile',
      'enabled': 1,
      'shared_categories_json': '["goals","bogus_category"]',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    final loaded = await dao.getForProfile('local-default-profile');
    expect(loaded.sharedCategories, {CoachShareCategory.goals});
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/database/coach_share_dao_test.dart`
Expected: FAIL — `CoachShareDao` does not exist.

- [ ] **Step 3: Implement the DAO**

```dart
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../features/coach/domain/entities/coach_share.dart';
import '../../features/coach/domain/entities/coach_share_category.dart';
import '../app_database.dart';

/// Persistence for per-profile coach-sharing configuration.
class CoachShareDao {
  const CoachShareDao(this._db);

  final AppDatabase _db;

  /// Returns the sharing configuration for [profileId]. A profile with no
  /// stored row yields a disabled [CoachShare] with no categories.
  Future<CoachShare> getForProfile(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'coach_shares',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (rows.isEmpty) return CoachShare(profileId: profileId);
    return _fromRow(rows.first);
  }

  /// Inserts or replaces the configuration for the share's profile.
  Future<void> save(CoachShare share) async {
    final db = await _db.database;
    await db.insert(
      'coach_shares',
      {
        'profile_id': share.profileId,
        'enabled': share.enabled ? 1 : 0,
        'shared_categories_json': jsonEncode(
          share.sharedCategories.map((c) => c.key).toList(),
        ),
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes any stored configuration for [profileId].
  Future<void> delete(String profileId) async {
    final db = await _db.database;
    await db.delete(
      'coach_shares',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }

  /// IDs of profiles that currently share at least one category.
  Future<List<String>> getSharedProfileIds() async {
    final db = await _db.database;
    final rows = await db.query('coach_shares', where: 'enabled = 1');
    return rows
        .map(_fromRow)
        .where((share) => share.hasActiveSharing)
        .map((share) => share.profileId)
        .toList();
  }

  CoachShare _fromRow(Map<String, Object?> row) {
    return CoachShare(
      profileId: row['profile_id'] as String,
      enabled: (row['enabled'] as int) == 1,
      sharedCategories: _decodeCategories(
        row['shared_categories_json'] as String?,
      ),
    );
  }

  Set<CoachShareCategory> _decodeCategories(String? value) {
    if (value == null || value.isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const {};
      return decoded
          .whereType<String>()
          .map(CoachShareCategory.fromKey)
          .whereType<CoachShareCategory>()
          .toSet();
    } on FormatException {
      return const {};
    }
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/database/coach_share_dao_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/database/daos/coach_share_dao.dart test/database/coach_share_dao_test.dart
git commit -m "feat: add CoachShareDao (#10)"
```

---

## Task 6: Coach providers

**Files:**
- Create: `lib/features/coach/presentation/providers/coach_providers.dart`
- Test: `test/features/coach/presentation/coach_providers_test.dart`

The DAO is used directly by providers — there is no separate repository class,
matching how `profile_providers.dart` consumes `ProfileDao` directly.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/coach_share_dao.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/presentation/providers/coach_providers.dart';

void main() {
  test('CoachShareController loads, toggles, and persists a profile share',
      () async {
    final db = AppDatabase.test();
    addTearDown(db.close);
    final dao = CoachShareDao(db);

    final container = ProviderContainer(overrides: [
      coachShareDaoProvider.overrideWithValue(dao),
    ]);
    addTearDown(container.dispose);

    final controller =
        container.read(coachShareControllerProvider('p1').notifier);
    await controller.future;

    await controller.setEnabled(true);
    await controller.setCategory(CoachShareCategory.goals, true);

    final reloaded = await dao.getForProfile('p1');
    expect(reloaded.enabled, isTrue);
    expect(reloaded.isShared(CoachShareCategory.goals), isTrue);
  });

  test('stopSharing disables sharing for the profile', () async {
    final db = AppDatabase.test();
    addTearDown(db.close);
    final dao = CoachShareDao(db);
    await dao.save(const CoachShare(
      profileId: 'p1',
      enabled: true,
      sharedCategories: {CoachShareCategory.notes},
    ));

    final container = ProviderContainer(overrides: [
      coachShareDaoProvider.overrideWithValue(dao),
    ]);
    addTearDown(container.dispose);

    final controller =
        container.read(coachShareControllerProvider('p1').notifier);
    await controller.future;
    await controller.stopSharing();

    expect((await dao.getForProfile('p1')).enabled, isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/presentation/coach_providers_test.dart`
Expected: FAIL — providers do not exist.

- [ ] **Step 3: Implement the providers**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../database/daos/coach_share_dao.dart';
import '../../domain/entities/coach_share.dart';
import '../../domain/entities/coach_share_category.dart';

/// DAO for coach-sharing configuration.
final coachShareDaoProvider = Provider<CoachShareDao>((ref) {
  return CoachShareDao(AppDatabase.instance);
});

/// IDs of profiles that currently share data with a coach.
final sharedProfileIdsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(coachShareDaoProvider).getSharedProfileIds();
});

/// Editable coach-sharing state for a single profile, keyed by profile id.
final coachShareControllerProvider = AsyncNotifierProvider.family<
    CoachShareController, CoachShare, String>(CoachShareController.new);

class CoachShareController extends FamilyAsyncNotifier<CoachShare, String> {
  @override
  Future<CoachShare> build(String profileId) {
    return ref.read(coachShareDaoProvider).getForProfile(profileId);
  }

  Future<void> _persist(CoachShare share) async {
    await ref.read(coachShareDaoProvider).save(share);
    state = AsyncData(share);
    ref.invalidate(sharedProfileIdsProvider);
  }

  /// Turns the master "share with coach" flag on or off.
  Future<void> setEnabled(bool enabled) async {
    final current = state.value ?? CoachShare(profileId: arg);
    await _persist(current.copyWith(enabled: enabled));
  }

  /// Adds or removes a single shared category.
  Future<void> setCategory(CoachShareCategory category, bool shared) async {
    final current = state.value ?? CoachShare(profileId: arg);
    await _persist(
      shared ? current.withCategory(category) : current.withoutCategory(category),
    );
  }

  /// Disables all sharing for this profile.
  Future<void> stopSharing() async {
    final current = state.value ?? CoachShare(profileId: arg);
    await _persist(current.copyWith(enabled: false));
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/presentation/coach_providers_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/presentation/providers/coach_providers.dart test/features/coach/presentation/coach_providers_test.dart
git commit -m "feat: add coach-sharing providers (#10)"
```

---

## Task 7: CoachReport model

**Files:**
- Create: `lib/features/coach/domain/entities/coach_report.dart`
- Test: `test/features/coach/domain/coach_report_test.dart`

First read the entity types this model aggregates, so the field types are
exact: `lib/features/swim/domain/entities/swim_session.dart`,
`lib/features/race/domain/entities/race_time.dart`,
`lib/features/pb/domain/entities/` (the personal-best entity),
`lib/features/dryland/domain/entities/dryland_workout.dart`, and the analytics
result type produced by `computeAnalytics` in
`lib/features/analytics/presentation/providers/analytics_providers.dart`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_report.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';

void main() {
  test('a report exposes exactly the categories it was built with', () {
    final report = CoachReport(
      profile: SwimmerProfile.defaultProfile,
      includedCategories: const {
        CoachShareCategory.goals,
        CoachShareCategory.swimSessions,
      },
      swimSessions: const [],
    );
    expect(report.includes(CoachShareCategory.goals), isTrue);
    expect(report.includes(CoachShareCategory.notes), isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/domain/coach_report_test.dart`
Expected: FAIL — `CoachReport` does not exist.

- [ ] **Step 3: Implement the model**

Create an immutable `CoachReport` that holds the `SwimmerProfile`, a
`Set<CoachShareCategory> includedCategories`, and one nullable field per
data category, typed to the entities read above:

```dart
import '../../../profiles/domain/entities/swimmer_profile.dart';
// ... import the swim session, race time, personal best, dryland workout,
// and analytics result types using their real paths and names.
import 'coach_share_category.dart';

/// A read-only snapshot of one profile's shared data, assembled once and
/// consumed by both the coach view and the PDF builder.
class CoachReport {
  const CoachReport({
    required this.profile,
    required this.includedCategories,
    this.swimSessions,
    this.raceTimes,
    this.personalBests,
    this.dryland,
    this.analytics,
  });

  final SwimmerProfile profile;
  final Set<CoachShareCategory> includedCategories;

  // Each is non-null only when its category is in [includedCategories].
  // Use the real entity types from the files read in this task.
  final List<Object>? swimSessions;
  final List<Object>? raceTimes;
  final List<Object>? personalBests;
  final List<Object>? dryland;
  final Object? analytics;

  bool includes(CoachShareCategory category) =>
      includedCategories.contains(category);
}
```

Replace the `Object`/`Object?` placeholders with the concrete entity types
(for example `List<SwimSession>?`). `profileDetails`, `goals`, and `notes`
draw from fields already on `profile`, so they need no extra field — they are
tracked only through `includedCategories`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/domain/coach_report_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/domain/entities/coach_report.dart test/features/coach/domain/coach_report_test.dart
git commit -m "feat: add CoachReport model (#10)"
```

---

## Task 8: CoachReportBuilder

**Files:**
- Create: `lib/features/coach/domain/services/coach_report_builder.dart`
- Test: `test/features/coach/domain/coach_report_builder_test.dart`

The builder takes the DAOs it needs (swim session, race time, PB, dryland) and
a profile lookup. For each category in the share's `activeCategories` it loads
that category's data scoped to the profile id; categories not shared are left
null. For `analytics` it runs the existing `computeAnalytics` over the
profile's sessions and personal bests. `profileDetails`/`goals`/`notes` need no
data load — they are flags only.

- [ ] **Step 1: Write the failing test**

The test must prove two things — **only shared categories appear**, and
**only the target profile's data appears**. Read the DAO constructors and
methods (`SwimSessionDao`, `RaceTimeDao`, `PbDao`, `DrylandDao` in
`lib/database/daos/`) and seed the in-memory database with data for two
profiles.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/domain/services/coach_report_builder.dart';
// import the DAOs and entity types needed to seed data.

void main() {
  test('builds a report containing only shared categories', () async {
    final db = AppDatabase.test();
    addTearDown(db.close);
    // Seed profile 'p1' with at least one swim session and one race time.
    // Build a CoachReportBuilder wired to the DAOs.

    const share = CoachShare(
      profileId: 'p1',
      enabled: true,
      sharedCategories: {CoachShareCategory.swimSessions},
    );
    final report = await builder.build('p1', share);

    expect(report.includes(CoachShareCategory.swimSessions), isTrue);
    expect(report.swimSessions, isNotNull);
    expect(report.includes(CoachShareCategory.raceTimes), isFalse);
    expect(report.raceTimes, isNull,
        reason: 'an unshared category must not be loaded');
  });

  test('a report for p1 never contains p2 data (profile scoping)', () async {
    final db = AppDatabase.test();
    addTearDown(db.close);
    // Seed swim sessions for both 'p1' and 'p2'.

    const share = CoachShare(
      profileId: 'p1',
      enabled: true,
      sharedCategories: {CoachShareCategory.swimSessions},
    );
    final report = await builder.build('p1', share);

    // Every loaded session must belong to p1.
    for (final session in report.swimSessions!) {
      expect((session as dynamic).profileId, 'p1');
    }
  });
}
```

Fill in the DAO wiring and seeding using the real DAO APIs.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/domain/coach_report_builder_test.dart`
Expected: FAIL — `CoachReportBuilder` does not exist.

- [ ] **Step 3: Implement the builder**

Create `CoachReportBuilder` with a constructor taking the DAOs and a way to
resolve a `SwimmerProfile` by id. Implement
`Future<CoachReport> build(String profileId, CoachShare share)`:

1. Resolve the `SwimmerProfile` for `profileId`.
2. Start from `share.activeCategories` (empty when the share is disabled).
3. For each data-backed category in that set, load via the matching DAO
   scoped to `profileId`; leave others null.
4. For `analytics`, call `computeAnalytics` with the profile's sessions and
   personal bests.
5. Return a `CoachReport` whose `includedCategories` is exactly
   `share.activeCategories`.

The builder must never read data for a category absent from
`share.activeCategories`, and every DAO call must be scoped by `profileId`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/domain/coach_report_builder_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/domain/services/coach_report_builder.dart test/features/coach/domain/coach_report_builder_test.dart
git commit -m "feat: add CoachReportBuilder (#10)"
```

---

## Task 9: CoachPdfBuilder

**Files:**
- Create: `lib/features/coach/domain/services/coach_pdf_builder.dart`
- Test: `test/features/coach/domain/coach_pdf_builder_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_report.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/domain/services/coach_pdf_builder.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';

void main() {
  test('builds a non-empty PDF for a report', () async {
    final report = CoachReport(
      profile: SwimmerProfile.defaultProfile,
      includedCategories: const {CoachShareCategory.profileDetails},
    );
    final bytes = await const CoachPdfBuilder().build(report);
    expect(bytes, isNotEmpty);
    // A PDF file starts with the "%PDF" magic bytes.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/domain/coach_pdf_builder_test.dart`
Expected: FAIL — `CoachPdfBuilder` does not exist.

- [ ] **Step 3: Implement the builder**

Create `CoachPdfBuilder` with `Future<Uint8List> build(CoachReport report)`.
Use the `pdf` package (`pw.Document`). Render a header with the swimmer's
display name and the included category labels, then one section per included
category. Only iterate `report.includedCategories`. Return `document.save()`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/domain/coach_pdf_builder_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/domain/services/coach_pdf_builder.dart test/features/coach/domain/coach_pdf_builder_test.dart
git commit -m "feat: add CoachPdfBuilder (#10)"
```

---

## Task 10: Coach sharing settings screen

**Files:**
- Create: `lib/features/coach/presentation/screens/coach_sharing_settings_screen.dart`
- Test: `test/features/coach/presentation/coach_sharing_settings_screen_test.dart`

Read an existing screen (for example
`lib/features/settings/presentation/screens/sync_settings_screen.dart`) for
the `ConsumerWidget`/`Scaffold` house style.

`CoachSharingSettingsScreen` takes a `profileId`. It watches
`coachShareControllerProvider(profileId)` and renders:

- A master `SwitchListTile` — *Share with coach* — bound to `setEnabled`.
- When enabled, a `SwitchListTile` per `CoachShareCategory` (label from
  `category.label`), each bound to `setCategory`.
- A caution note that notes and personal details are shared only when
  switched on.
- A summary line listing the currently shared category labels.
- A *Stop sharing* button bound to `stopSharing`.

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/coach_share_dao.dart';
import 'package:rep_swim/features/coach/presentation/providers/coach_providers.dart';
import 'package:rep_swim/features/coach/presentation/screens/coach_sharing_settings_screen.dart';

void main() {
  testWidgets('enabling sharing reveals the category toggles', (tester) async {
    final db = AppDatabase.test();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        coachShareDaoProvider.overrideWithValue(CoachShareDao(db)),
      ],
      child: const MaterialApp(
        home: CoachSharingSettingsScreen(profileId: 'p1'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Goals'), findsNothing,
        reason: 'category toggles hidden while sharing is off');

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Goals'), findsOneWidget);
  });

  testWidgets('Stop sharing turns the master switch off', (tester) async {
    final db = AppDatabase.test();
    addTearDown(db.close);
    await CoachShareDao(db).save(/* an enabled CoachShare for 'p1' */);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        coachShareDaoProvider.overrideWithValue(CoachShareDao(db)),
      ],
      child: const MaterialApp(
        home: CoachSharingSettingsScreen(profileId: 'p1'),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stop sharing'));
    await tester.pumpAndSettle();

    expect((await CoachShareDao(db).getForProfile('p1')).enabled, isFalse);
  });
}
```

Fill the `save(...)` argument with an enabled `CoachShare` (see Task 5's test
for the constructor).

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/presentation/coach_sharing_settings_screen_test.dart`
Expected: FAIL — screen does not exist.

- [ ] **Step 3: Implement the screen**

Build `CoachSharingSettingsScreen` as described above. Hide the category
toggles, summary, and *Stop sharing* button while the master switch is off.
Keep widgets `const` where the lint requires it.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/presentation/coach_sharing_settings_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/presentation/screens/coach_sharing_settings_screen.dart test/features/coach/presentation/coach_sharing_settings_screen_test.dart
git commit -m "feat: add coach sharing settings screen (#10)"
```

---

## Task 11: Coach view screen

**Files:**
- Create: `lib/features/coach/presentation/screens/coach_view_screen.dart`
- Create: `lib/features/coach/presentation/providers/coach_report_providers.dart`
- Test: `test/features/coach/presentation/coach_view_screen_test.dart`

`coach_report_providers.dart` exposes a provider that wires a
`CoachReportBuilder` to the real DAOs and a provider family
`coachReportProvider(profileId)` returning the built `CoachReport`.

`CoachViewScreen` is a sealed read-only screen:

- It is NOT placed inside the adaptive shell — no bottom nav, no rail.
- If more than one profile is shared, show a picker of shared profiles
  (from `sharedProfileIdsProvider`); otherwise go straight to the single
  shared profile.
- For the selected profile, render one read-only panel per category in the
  report's `includedCategories` — no edit, add, or delete controls.
- An *Export PDF* action: build the PDF via `CoachPdfBuilder` and hand the
  bytes to the `printing` package's share/layout API.
- An *Exit coach view* action (app-bar close button) that pops the route.

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// imports for AppDatabase, DAOs, providers, and CoachViewScreen.

void main() {
  testWidgets('coach view shows only shared categories and no edit controls',
      (tester) async {
    // Seed a profile 'p1' with swim sessions and race times.
    // Save a CoachShare for 'p1' enabled with ONLY swimSessions shared.
    // Pump CoachViewScreen for 'p1' inside ProviderScope + MaterialApp.
    await tester.pumpAndSettle();

    expect(find.text('Swim sessions'), findsOneWidget);
    expect(find.text('Race times'), findsNothing,
        reason: 'race times were not shared');
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  });
}
```

Fill in the seeding and pump using the real DAO/provider APIs.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/coach/presentation/coach_view_screen_test.dart`
Expected: FAIL — screen does not exist.

- [ ] **Step 3: Implement the providers and screen**

Implement `coach_report_providers.dart` and `CoachViewScreen` as described.
Read-only panels may be small private widgets in the same file. No widget in
this screen may expose an edit/add/delete affordance.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/coach/presentation/coach_view_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/coach/presentation/screens/coach_view_screen.dart lib/features/coach/presentation/providers/coach_report_providers.dart test/features/coach/presentation/coach_view_screen_test.dart
git commit -m "feat: add sealed read-only coach view screen (#10)"
```

---

## Task 12: Routes

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Add imports**

In `lib/app.dart`, add with the other feature-screen imports:

```dart
import 'features/coach/presentation/screens/coach_sharing_settings_screen.dart';
import 'features/coach/presentation/screens/coach_view_screen.dart';
```

- [ ] **Step 2: Add top-level routes**

Both coach routes are sealed screens, so they go OUTSIDE the `ShellRoute`,
alongside `/tempo` and `/stopwatch`. Add inside the top-level `routes:` list
of `_router`, after the `/settings/sync` route:

```dart
    GoRoute(
      path: '/coach',
      builder: (context, state) => const CoachViewScreen(),
    ),
    GoRoute(
      path: '/coach/sharing/:profileId',
      builder: (context, state) => CoachSharingSettingsScreen(
        profileId: state.pathParameters['profileId']!,
      ),
    ),
```

If `CoachViewScreen` requires a profile id rather than choosing one itself,
pass it the same way as `CoachSharingSettingsScreen`.

- [ ] **Step 3: Verify analysis**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat: register coach mode routes (#10)"
```

---

## Task 13: Profiles screen integration

**Files:**
- Modify: `lib/features/profiles/presentation/screens/profiles_screen.dart`
- Test: `test/features/profiles/profiles_screen_coach_test.dart`

Read `profiles_screen.dart` first to match its card layout and action style.

Add three things:

1. A *Coach sharing* action on each profile card that navigates to
   `/coach/sharing/<profileId>`.
2. A *Shared with coach* badge/icon on cards whose profile has active sharing
   (watch `sharedProfileIdsProvider`).
3. A *Coach view* entry (app-bar action) that navigates to `/coach`, shown
   only when `sharedProfileIdsProvider` is non-empty.

- [ ] **Step 1: Write the failing widget test**

```dart
// Pump ProfilesScreen inside ProviderScope + MaterialApp with a router or a
// mocked navigator. Seed one profile with active coach sharing via an
// overridden CoachShareDao.
// Assert a "Shared with coach" indicator is shown for that profile.
```

Write a concrete test that seeds a shared profile and asserts the indicator
appears, and that an unshared profile shows none. Use the override pattern
from Task 10's test.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/profiles/profiles_screen_coach_test.dart`
Expected: FAIL — indicator not implemented.

- [ ] **Step 3: Implement the integration**

Add the action, badge, and app-bar entry. Keep edits minimal and follow the
existing card structure.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/profiles/profiles_screen_coach_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the profiles test suite for regressions**

Run: `flutter test test/features/profiles/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/profiles/presentation/screens/profiles_screen.dart test/features/profiles/profiles_screen_coach_test.dart
git commit -m "feat: surface coach sharing and coach view on the Profiles screen (#10)"
```

---

## Task 14: Final validation

**Files:** none (verification only)

- [ ] **Step 1: Format**

Run: `dart format lib test`
Expected: files formatted; commit any reformatting if needed.

- [ ] **Step 2: Static analysis**

Run: `flutter analyze`
Expected: exit 0, no issues.

- [ ] **Step 3: Full test suite**

Run: `flutter test`
Expected: all tests pass, including the pre-existing suite and every coach
mode test added by this plan.

- [ ] **Step 4: Commit any fixes**

If Steps 1–3 required corrections:

```bash
git add -A
git commit -m "chore: final validation fixes for coach mode (#10)"
```

If nothing needed fixing, no commit is necessary.

---

## Self-review notes

- **Spec coverage:** dependencies (Task 1); `CoachShareCategory` (Task 2);
  `CoachShare` rules (Task 3); `coach_shares` table + v13 migration (Task 4);
  `CoachShareDao` persistence (Task 5); providers incl. enable/toggle/revoke
  (Task 6); `CoachReport` (Task 7); `CoachReportBuilder` with category and
  profile scoping (Task 8); `CoachPdfBuilder` (Task 9); sharing settings UI
  (Task 10); sealed coach view + PDF export (Task 11); routes (Task 12);
  Profiles-screen entry points, badge, review (Task 13); validation (Task 14).
  Unit/widget/integration tests are embedded throughout per issue #10's
  acceptance criteria.
- **Type consistency:** `CoachShare`, `CoachShareCategory`, `CoachReport`,
  `CoachShareDao`, `CoachReportBuilder`, `CoachPdfBuilder`,
  `coachShareDaoProvider`, `coachShareControllerProvider`,
  `sharedProfileIdsProvider` are used consistently across tasks.
- **Open implementation detail:** Tasks 7 and 8 deliberately defer the exact
  entity/DAO type names to the implementer, who must read the named source
  files — those types are existing code, not defined by this plan.
- **Out of scope, as designed:** remote/cloud delivery, coach write-back, a
  PIN lock, and multiple named coaches.
