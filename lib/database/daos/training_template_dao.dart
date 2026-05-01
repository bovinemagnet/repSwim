import 'package:sqflite/sqflite.dart';

import '../../features/templates/domain/entities/dryland_routine_template.dart';
import '../../features/templates/domain/entities/interval_template.dart';
import '../app_database.dart';

class TrainingTemplateDao {
  const TrainingTemplateDao(this._db);

  final AppDatabase _db;

  Future<List<IntervalTemplate>> getIntervalTemplates(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'interval_templates',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_intervalFromRow).toList();
  }

  Future<void> insertIntervalTemplate(IntervalTemplate template) async {
    final db = await _db.database;
    await db.insert(
      'interval_templates',
      {
        'id': template.id,
        'profile_id': template.profileId,
        'name': template.name,
        'sets': template.sets,
        'reps': template.reps,
        'work_seconds': template.workDuration.inSeconds,
        'rest_seconds': template.restDuration.inSeconds,
        'created_at': template.createdAt.millisecondsSinceEpoch,
        'updated_at': template.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteIntervalTemplate(String id, String profileId) async {
    final db = await _db.database;
    await db.delete(
      'interval_templates',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Future<List<DrylandRoutineTemplate>> getDrylandRoutineTemplates(
    String profileId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'dryland_routine_templates',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final templates = <DrylandRoutineTemplate>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final exercises = await getDrylandRoutineExercises(id, profileId);
      templates.add(_drylandFromRow(row, exercises));
    }
    return templates;
  }

  Future<void> insertDrylandRoutineTemplate(
    DrylandRoutineTemplate template,
  ) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
        'dryland_routine_templates',
        {
          'id': template.id,
          'profile_id': template.profileId,
          'name': template.name,
          'notes': template.notes,
          'created_at': template.createdAt.millisecondsSinceEpoch,
          'updated_at': template.updatedAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'dryland_routine_template_exercises',
        where: 'template_id = ?',
        whereArgs: [template.id],
      );
      for (final exercise in template.exercises) {
        await txn.insert(
          'dryland_routine_template_exercises',
          {
            'id': exercise.id,
            'template_id': exercise.templateId,
            'profile_id': exercise.profileId,
            'name': exercise.name,
            'sets': exercise.sets,
            'reps': exercise.reps,
            'weight': exercise.weight,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteDrylandRoutineTemplate(
    String id,
    String profileId,
  ) async {
    final db = await _db.database;
    await db.delete(
      'dryland_routine_templates',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Future<List<DrylandRoutineExerciseTemplate>> getDrylandRoutineExercises(
    String templateId,
    String profileId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'dryland_routine_template_exercises',
      where: 'template_id = ? AND profile_id = ?',
      whereArgs: [templateId, profileId],
      orderBy: 'rowid ASC',
    );
    return rows.map(_drylandExerciseFromRow).toList();
  }

  IntervalTemplate _intervalFromRow(Map<String, Object?> row) {
    return IntervalTemplate(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      name: row['name'] as String,
      sets: row['sets'] as int,
      reps: row['reps'] as int,
      workDuration: Duration(seconds: row['work_seconds'] as int),
      restDuration: Duration(seconds: row['rest_seconds'] as int),
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

  DrylandRoutineTemplate _drylandFromRow(
    Map<String, Object?> row,
    List<DrylandRoutineExerciseTemplate> exercises,
  ) {
    return DrylandRoutineTemplate(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      name: row['name'] as String,
      notes: row['notes'] as String?,
      exercises: exercises,
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

  DrylandRoutineExerciseTemplate _drylandExerciseFromRow(
    Map<String, Object?> row,
  ) {
    return DrylandRoutineExerciseTemplate(
      id: row['id'] as String,
      templateId: row['template_id'] as String,
      profileId: row['profile_id'] as String,
      name: row['name'] as String,
      sets: row['sets'] as int,
      reps: row['reps'] as int,
      weight: row['weight'] as double?,
    );
  }
}
