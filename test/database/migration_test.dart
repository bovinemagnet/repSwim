import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rep_swim/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('database migrations', () {
    for (final oldVersion in [1, 3, 4, 5, 7]) {
      test('upgrades version $oldVersion to current schema', () async {
        final path = p.join(
          Directory.systemTemp.path,
          'rep_swim_migration_${oldVersion}_${DateTime.now().microsecondsSinceEpoch}.db',
        );
        final oldDb = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: oldVersion,
            onCreate: (db, _) => _createOldSchema(db, oldVersion),
          ),
        );
        await _seedOldData(oldDb, oldVersion);
        await oldDb.close();

        final appDb = AppDatabase.test(path: path);
        final db = await appDb.database;

        expect(await _hasColumn(db, 'sync_queue', 'profile_id'), isTrue);
        expect(await _hasColumn(db, 'sync_queue', 'sequence'), isTrue);
        expect(await _hasTable(db, 'interval_templates'), isTrue);
        expect(await _hasTable(db, 'dryland_routine_templates'), isTrue);
        expect(await _hasTable(db, 'app_settings'), isTrue);
        expect(await _hasTable(db, 'race_times'), isTrue);

        final sessions = await db.query('swim_sessions');
        final pbs = await db.query('personal_bests');
        final profiles = await db.query('swimmer_profiles');
        expect(sessions.single['id'], 'session-old');
        expect(pbs.single['id'], 'pb-old');
        expect(profiles, isNotEmpty);

        await appDb.close();
        await databaseFactoryFfi.deleteDatabase(path);
      });
    }
  });
}

Future<void> _createOldSchema(Database db, int version) async {
  if (version >= 3) {
    await db.execute('''
      CREATE TABLE swimmer_profiles (
        id TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        preferred_pool_length_meters INTEGER NOT NULL DEFAULT 25,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
  }

  final profileColumn = version >= 3
      ? "profile_id TEXT NOT NULL DEFAULT 'local-default-profile',"
      : '';

  await db.execute('''
    CREATE TABLE swim_sessions (
      id TEXT PRIMARY KEY,
      $profileColumn
      date INTEGER NOT NULL,
      total_distance INTEGER NOT NULL,
      total_time_seconds INTEGER NOT NULL,
      stroke TEXT NOT NULL,
      notes TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE laps (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL,
      $profileColumn
      distance INTEGER NOT NULL,
      time_seconds INTEGER NOT NULL,
      lap_number INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE personal_bests (
      id TEXT PRIMARY KEY,
      $profileColumn
      stroke TEXT NOT NULL,
      distance INTEGER NOT NULL,
      best_time_seconds INTEGER NOT NULL,
      achieved_at INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE dryland_workouts (
      id TEXT PRIMARY KEY,
      $profileColumn
      date INTEGER NOT NULL,
      notes TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE exercises (
      id TEXT PRIMARY KEY,
      workout_id TEXT NOT NULL,
      $profileColumn
      name TEXT NOT NULL,
      sets INTEGER NOT NULL,
      reps INTEGER NOT NULL,
      weight REAL
    )
  ''');

  if (version >= 3) {
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }
  if (version >= 4) {
    await db.execute(
      "ALTER TABLE sync_queue ADD COLUMN profile_id TEXT NOT NULL DEFAULT 'local-default-profile'",
    );
  }
  if (version >= 5) {
    await db.execute('''
      CREATE TABLE interval_templates (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        work_seconds INTEGER NOT NULL,
        rest_seconds INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE dryland_routine_templates (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE dryland_routine_template_exercises (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL
      )
    ''');
  }
  if (version >= 6) {
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }
  if (version >= 7) {
    await db.execute(
      'ALTER TABLE sync_queue ADD COLUMN sequence INTEGER NOT NULL DEFAULT 0',
    );
  }
}

Future<void> _seedOldData(Database db, int version) async {
  final now = DateTime.utc(2024).millisecondsSinceEpoch;
  if (version >= 3) {
    await db.insert('swimmer_profiles', {
      'id': 'profile-old',
      'display_name': 'Old Profile',
      'preferred_pool_length_meters': 25,
      'notes': null,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  final profileValues = version >= 3 ? {'profile_id': 'profile-old'} : {};
  await db.insert('swim_sessions', {
    'id': 'session-old',
    ...profileValues,
    'date': now,
    'total_distance': 50,
    'total_time_seconds': 40,
    'stroke': 'Freestyle',
    'notes': null,
  });
  await db.insert('personal_bests', {
    'id': 'pb-old',
    ...profileValues,
    'stroke': 'Freestyle',
    'distance': 50,
    'best_time_seconds': 40,
    'achieved_at': now,
  });
}

Future<bool> _hasTable(Database db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    [table],
  );
  return rows.isNotEmpty;
}

Future<bool> _hasColumn(Database db, String table, String column) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.any((row) => row['name'] == column);
}
