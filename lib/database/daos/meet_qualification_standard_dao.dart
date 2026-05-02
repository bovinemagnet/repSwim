import 'package:sqflite/sqflite.dart';

import '../../features/race/domain/entities/meet_qualification_standard.dart';
import '../../features/race/domain/entities/race_time.dart';
import '../app_database.dart';

class MeetQualificationStandardDao {
  const MeetQualificationStandardDao(this._db);

  final AppDatabase _db;

  Future<List<MeetQualificationStandard>> getAll({String? sourceName}) async {
    final db = await _db.database;
    final rows = await db.query(
      'meet_qualification_standards',
      where: sourceName == null ? null : 'source_name = ?',
      whereArgs: sourceName == null ? null : [sourceName],
      orderBy: '''
        source_name COLLATE NOCASE ASC,
        is_relay ASC,
        sex COLLATE NOCASE ASC,
        stroke COLLATE NOCASE ASC,
        distance ASC,
        min_age ASC
      ''',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> replaceSource(
    String sourceName,
    List<MeetQualificationStandard> standards,
  ) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        'meet_qualification_standards',
        where: 'source_name = ?',
        whereArgs: [sourceName],
      );
      final batch = txn.batch();
      for (final standard in standards) {
        batch.insert(
          'meet_qualification_standards',
          _toRow(standard),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteSource(String sourceName) async {
    final db = await _db.database;
    await db.delete(
      'meet_qualification_standards',
      where: 'source_name = ?',
      whereArgs: [sourceName],
    );
  }

  Map<String, Object?> _toRow(MeetQualificationStandard standard) {
    return {
      'id': standard.id,
      'source_name': standard.sourceName,
      'sex': standard.sex?.name,
      'age_group_label': standard.ageGroupLabel,
      'min_age': standard.minAge,
      'max_age': standard.maxAge,
      'is_open': standard.isOpen ? 1 : 0,
      'distance': standard.distance,
      'stroke': standard.stroke,
      'course_type': standard.course.name,
      'qualifying_centiseconds': standard.qualifyingCentiseconds,
      'mc_points': standard.mcPoints,
      'is_relay': standard.isRelay ? 1 : 0,
      'relay_event': standard.relayEvent,
      'valid_from': standard.validFrom.toUtc().millisecondsSinceEpoch,
      'competition_start':
          standard.competitionStart.toUtc().millisecondsSinceEpoch,
      'competition_end': standard.competitionEnd.toUtc().millisecondsSinceEpoch,
    };
  }

  MeetQualificationStandard _fromRow(Map<String, Object?> row) {
    final centiseconds = row['qualifying_centiseconds'] as int?;
    final sexName = row['sex'] as String?;
    return MeetQualificationStandard(
      id: row['id'] as String,
      sourceName: row['source_name'] as String,
      sex: sexName == null ? null : QualificationSex.values.byName(sexName),
      ageGroupLabel: row['age_group_label'] as String,
      minAge: row['min_age'] as int?,
      maxAge: row['max_age'] as int?,
      isOpen: row['is_open'] == 1,
      distance: row['distance'] as int?,
      stroke: row['stroke'] as String?,
      course: RaceCourse.values.byName(row['course_type'] as String),
      qualifyingTime: centiseconds == null
          ? null
          : Duration(milliseconds: centiseconds * 10),
      mcPoints: row['mc_points'] as int?,
      isRelay: row['is_relay'] == 1,
      relayEvent: row['relay_event'] as String?,
      validFrom: DateTime.fromMillisecondsSinceEpoch(
        row['valid_from'] as int,
        isUtc: true,
      ),
      competitionStart: DateTime.fromMillisecondsSinceEpoch(
        row['competition_start'] as int,
        isUtc: true,
      ),
      competitionEnd: DateTime.fromMillisecondsSinceEpoch(
        row['competition_end'] as int,
        isUtc: true,
      ),
    );
  }
}
