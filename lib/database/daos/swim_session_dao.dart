import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../features/swim/domain/entities/lap.dart';
import '../../features/swim/domain/entities/swim_session.dart';

class SwimSessionDao {
  const SwimSessionDao(this._db);

  final AppDatabase _db;

  Future<void> insertSession(SwimSession session) async {
    final db = await _db.database;
    await db.insert(
      'swim_sessions',
      {
        'id': session.id,
        'date': session.date.millisecondsSinceEpoch,
        'total_distance': session.totalDistance,
        'total_time_seconds': session.totalTime.inSeconds,
        'stroke': session.stroke,
        'notes': session.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (final lap in session.laps) {
      await insertLap(lap);
    }
  }

  Future<void> insertLap(Lap lap) async {
    final db = await _db.database;
    await db.insert(
      'laps',
      {
        'id': lap.id,
        'session_id': lap.sessionId,
        'distance': lap.distance,
        'time_seconds': lap.time.inSeconds,
        'lap_number': lap.lapNumber,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SwimSession>> getAllSessions() async {
    final db = await _db.database;
    final rows = await db.query('swim_sessions', orderBy: 'date DESC');

    final sessions = <SwimSession>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final laps = await getLapsForSession(id);
      sessions.add(SwimSession(
        id: id,
        date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
        totalDistance: row['total_distance'] as int,
        totalTime: Duration(seconds: row['total_time_seconds'] as int),
        stroke: row['stroke'] as String,
        laps: laps,
        notes: row['notes'] as String?,
      ));
    }
    return sessions;
  }

  Future<List<SwimSession>> getRecentSessions({int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.query(
      'swim_sessions',
      orderBy: 'date DESC',
      limit: limit,
    );

    final sessions = <SwimSession>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final laps = await getLapsForSession(id);
      sessions.add(SwimSession(
        id: id,
        date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
        totalDistance: row['total_distance'] as int,
        totalTime: Duration(seconds: row['total_time_seconds'] as int),
        stroke: row['stroke'] as String,
        laps: laps,
        notes: row['notes'] as String?,
      ));
    }
    return sessions;
  }

  Future<List<Lap>> getLapsForSession(String sessionId) async {
    final db = await _db.database;
    final rows = await db.query(
      'laps',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'lap_number ASC',
    );
    return rows
        .map((r) => Lap(
              id: r['id'] as String,
              sessionId: r['session_id'] as String,
              distance: r['distance'] as int,
              time: Duration(seconds: r['time_seconds'] as int),
              lapNumber: r['lap_number'] as int,
            ))
        .toList();
  }

  Future<void> deleteSession(String id) async {
    final db = await _db.database;
    // Laps are deleted via ON DELETE CASCADE
    await db.delete('swim_sessions', where: 'id = ?', whereArgs: [id]);
  }
}
