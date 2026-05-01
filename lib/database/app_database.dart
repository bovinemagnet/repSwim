import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rep_swim.db');
    return openDatabase(
      path,
      version: kDbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE swim_sessions (
        id TEXT PRIMARY KEY,
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
        distance INTEGER NOT NULL,
        time_seconds INTEGER NOT NULL,
        lap_number INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES swim_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE personal_bests (
        id TEXT PRIMARY KEY,
        stroke TEXT NOT NULL,
        distance INTEGER NOT NULL,
        best_time_seconds INTEGER NOT NULL,
        achieved_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dryland_workouts (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        workout_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL,
        FOREIGN KEY (workout_id) REFERENCES dryland_workouts(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
