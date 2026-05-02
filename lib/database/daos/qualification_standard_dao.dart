import 'package:sqflite/sqflite.dart';

import '../../features/race/domain/entities/qualification_standard.dart';
import '../../features/race/domain/entities/race_time.dart';
import '../app_database.dart';

class QualificationStandardDao {
  const QualificationStandardDao(this._db);

  final AppDatabase _db;

  Future<List<QualificationStandard>> getAll(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'qualification_standards',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'age ASC, distance ASC, stroke COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> insertOrUpdate(QualificationStandard standard) async {
    final db = await _db.database;
    await db.insert(
      'qualification_standards',
      _toRow(standard),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id, String profileId) async {
    final db = await _db.database;
    await db.delete(
      'qualification_standards',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Map<String, Object?> _toRow(QualificationStandard standard) {
    return {
      'id': standard.id,
      'profile_id': standard.profileId,
      'age': standard.age,
      'distance': standard.distance,
      'stroke': standard.stroke,
      'course_type': standard.course.name,
      'gold_centiseconds': standard.goldCentiseconds,
      'silver_centiseconds': standard.silverCentiseconds,
      'bronze_centiseconds': standard.bronzeCentiseconds,
      'created_at': standard.createdAt.toUtc().millisecondsSinceEpoch,
      'updated_at': standard.updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  QualificationStandard _fromRow(Map<String, Object?> row) {
    return QualificationStandard(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      age: row['age'] as int,
      distance: row['distance'] as int,
      stroke: row['stroke'] as String,
      course: RaceCourse.values.byName(row['course_type'] as String),
      goldTime: Duration(milliseconds: (row['gold_centiseconds'] as int) * 10),
      silverTime:
          Duration(milliseconds: (row['silver_centiseconds'] as int) * 10),
      bronzeTime:
          Duration(milliseconds: (row['bronze_centiseconds'] as int) * 10),
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
