import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/constants/app_constants.dart';

class AppDatabase {
  AppDatabase._({String? path, DatabaseFactory? factory})
      : _path = path,
        _factory = factory;

  static final AppDatabase instance = AppDatabase._();

  AppDatabase.test({String path = inMemoryDatabasePath})
      : _path = path,
        _factory = databaseFactoryFfi;

  final String? _path;
  final DatabaseFactory? _factory;
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final factory = _factory;
    if (factory != null) {
      sqfliteFfiInit();
      return factory.openDatabase(
        _path!,
        options: OpenDatabaseOptions(
          version: kDbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );
    }

    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rep_swim.db');
    return openDatabase(
      path,
      version: kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createProfilesTable(db);
    await _ensureDefaultProfile(db);

    await db.execute('''
      CREATE TABLE swim_sessions (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
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
        profile_id TEXT NOT NULL,
        distance INTEGER NOT NULL,
        time_seconds INTEGER NOT NULL,
        lap_number INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES swim_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE personal_bests (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        stroke TEXT NOT NULL,
        distance INTEGER NOT NULL,
        best_time_seconds INTEGER NOT NULL,
        achieved_at INTEGER NOT NULL
      )
    ''');
    await _createIndexes(db);

    await db.execute('''
      CREATE TABLE dryland_workouts (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        FOREIGN KEY (workout_id) REFERENCES dryland_workouts(id) ON DELETE CASCADE
      )
    ''');

    await _createSyncQueueTable(db);
    await _createTrainingTemplateTables(db);
    await _createAppSettingsTable(db);
    await _createRaceTimesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _deduplicatePersonalBests(db);
    }
    if (oldVersion < 3) {
      await _createProfilesTable(db);
      await _ensureDefaultProfile(db);
      await _addProfileColumn(db, 'swim_sessions');
      await _addProfileColumn(db, 'laps');
      await _addProfileColumn(db, 'personal_bests');
      await _addProfileColumn(db, 'dryland_workouts');
      await _addProfileColumn(db, 'exercises');
      await db
          .execute('DROP INDEX IF EXISTS idx_personal_bests_stroke_distance');
      await _createIndexes(db);
      await _createSyncQueueTable(db);
    }
    if (oldVersion < 4) {
      await _createSyncQueueTable(db);
      await _addColumnIfMissing(
        db,
        table: 'sync_queue',
        column: 'profile_id',
        definition: "TEXT NOT NULL DEFAULT '$kDefaultProfileId'",
      );
    }
    if (oldVersion < 5) {
      await _createTrainingTemplateTables(db);
    }
    if (oldVersion < 6) {
      await _createAppSettingsTable(db);
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(
        db,
        table: 'sync_queue',
        column: 'sequence',
        definition: 'INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('UPDATE sync_queue SET sequence = rowid');
    }
    if (oldVersion < 8) {
      await _createRaceTimesTable(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_personal_bests_profile_stroke_distance
      ON personal_bests(profile_id, stroke, distance)
    ''');
  }

  Future<void> _createProfilesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS swimmer_profiles (
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

  Future<void> _ensureDefaultProfile(Database db) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.insert(
      'swimmer_profiles',
      {
        'id': kDefaultProfileId,
        'display_name': kDefaultProfileName,
        'preferred_pool_length_meters': 25,
        'notes': null,
        'created_at': now,
        'updated_at': now,
        'deleted_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _addProfileColumn(Database db, String table) async {
    await db.execute(
      "ALTER TABLE $table ADD COLUMN profile_id TEXT NOT NULL DEFAULT '$kDefaultProfileId'",
    );
  }

  Future<void> _createSyncQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL DEFAULT '$kDefaultProfileId',
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        sequence INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createTrainingTemplateTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS interval_templates (
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
      CREATE TABLE IF NOT EXISTS dryland_routine_templates (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dryland_routine_template_exercises (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        FOREIGN KEY (template_id) REFERENCES dryland_routine_templates(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createRaceTimesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS race_times (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        race_name TEXT NOT NULL,
        event_date INTEGER NOT NULL,
        distance INTEGER NOT NULL,
        stroke TEXT NOT NULL,
        course_type TEXT NOT NULL,
        time_centiseconds INTEGER NOT NULL,
        notes TEXT,
        placement INTEGER,
        location TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_race_times_profile_event
      ON race_times(profile_id, event_date DESC)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_race_times_profile_course_event
      ON race_times(profile_id, stroke, distance, course_type)
    ''');
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _deduplicatePersonalBests(Database db) async {
    final rows = await db.query(
      'personal_bests',
      orderBy: 'stroke ASC, distance ASC, best_time_seconds ASC',
    );

    final seen = <String>{};
    for (final row in rows) {
      final key = '${row['stroke']}|${row['distance']}';
      if (seen.add(key)) continue;
      await db.delete(
        'personal_bests',
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
