import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../features/swim/domain/entities/lap.dart';
import '../../features/swim/domain/entities/swim_session.dart';

class SwimSessionDao {
  const SwimSessionDao(this._db);

  final AppDatabase _db;

  Future<void> insertSession(SwimSession session) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
        'swim_sessions',
        {
          'id': session.id,
          'profile_id': session.profileId,
          'date': session.date.millisecondsSinceEpoch,
          'total_distance': session.totalDistance,
          'total_time_seconds': session.totalTime.inSeconds,
          'stroke': session.stroke,
          'notes': session.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'laps',
        where: 'session_id = ? AND profile_id = ?',
        whereArgs: [session.id, session.profileId],
      );

      for (final lap in session.laps) {
        await txn.insert(
          'laps',
          {
            'id': lap.id,
            'session_id': lap.sessionId,
            'profile_id': lap.profileId,
            'distance': lap.distance,
            'time_seconds': lap.time.inSeconds,
            'lap_number': lap.lapNumber,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> insertLap(Lap lap) async {
    final db = await _db.database;
    await db.insert(
      'laps',
      {
        'id': lap.id,
        'session_id': lap.sessionId,
        'profile_id': lap.profileId,
        'distance': lap.distance,
        'time_seconds': lap.time.inSeconds,
        'lap_number': lap.lapNumber,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SwimSession>> getAllSessions(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'swim_sessions',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'date DESC',
    );

    final sessions = <SwimSession>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final laps = await getLapsForSession(id, profileId);
      sessions.add(SwimSession(
        id: id,
        profileId: row['profile_id'] as String,
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

  Future<List<SwimSession>> getRecentSessions(
    String profileId, {
    int limit = 10,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'swim_sessions',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'date DESC',
      limit: limit,
    );

    final sessions = <SwimSession>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final laps = await getLapsForSession(id, profileId);
      sessions.add(SwimSession(
        id: id,
        profileId: row['profile_id'] as String,
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

  Future<List<Lap>> getLapsForSession(
      String sessionId, String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'laps',
      where: 'session_id = ? AND profile_id = ?',
      whereArgs: [sessionId, profileId],
      orderBy: 'lap_number ASC',
    );
    return rows
        .map((r) => Lap(
              id: r['id'] as String,
              sessionId: r['session_id'] as String,
              profileId: r['profile_id'] as String,
              distance: r['distance'] as int,
              time: Duration(seconds: r['time_seconds'] as int),
              lapNumber: r['lap_number'] as int,
            ))
        .toList();
  }

  Future<void> deleteSession(String id, String profileId) async {
    final db = await _db.database;
    // Laps are deleted via ON DELETE CASCADE
    await db.delete(
      'swim_sessions',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }
}
