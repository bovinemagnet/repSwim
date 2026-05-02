import 'package:sqflite/sqflite.dart';

import '../../features/race/domain/entities/race_time.dart';
import '../app_database.dart';

class RaceTimeDao {
  const RaceTimeDao(this._db);

  final AppDatabase _db;

  Future<List<RaceTime>> getAll(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'race_times',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'event_date DESC, race_name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> insertOrUpdate(RaceTime raceTime) async {
    final db = await _db.database;
    await db.insert(
      'race_times',
      _toRow(raceTime),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id, String profileId) async {
    final db = await _db.database;
    await db.delete(
      'race_times',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Map<String, Object?> _toRow(RaceTime raceTime) {
    return {
      'id': raceTime.id,
      'profile_id': raceTime.profileId,
      'race_name': raceTime.raceName,
      'event_date': raceTime.eventDate.toUtc().millisecondsSinceEpoch,
      'distance': raceTime.distance,
      'stroke': raceTime.stroke,
      'course_type': raceTime.course.name,
      'time_centiseconds': raceTime.timeCentiseconds,
      'notes': raceTime.notes,
      'placement': raceTime.placement,
      'location': raceTime.location,
      'created_at': raceTime.createdAt.toUtc().millisecondsSinceEpoch,
      'updated_at': raceTime.updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  RaceTime _fromRow(Map<String, Object?> row) {
    return RaceTime(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      raceName: row['race_name'] as String,
      eventDate: DateTime.fromMillisecondsSinceEpoch(
        row['event_date'] as int,
        isUtc: true,
      ),
      distance: row['distance'] as int,
      stroke: row['stroke'] as String,
      course: RaceCourse.values.byName(row['course_type'] as String),
      time: Duration(milliseconds: (row['time_centiseconds'] as int) * 10),
      notes: row['notes'] as String?,
      placement: row['placement'] as int?,
      location: row['location'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }
}
