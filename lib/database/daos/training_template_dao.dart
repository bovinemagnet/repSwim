import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../features/tempo/domain/entities/tempo_mode.dart';
import '../../features/tempo/domain/entities/tempo_session_result.dart';
import '../../features/tempo/domain/entities/tempo_template.dart';
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

  Future<List<TempoTemplate>> getTempoTemplates(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'tempo_templates',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_tempoTemplateFromRow).toList();
  }

  Future<void> insertTempoTemplate(TempoTemplate template) async {
    final db = await _db.database;
    await db.insert(
      'tempo_templates',
      {
        'id': template.id,
        'profile_id': template.profileId,
        'name': template.name,
        'mode': template.mode.name,
        'pool_length_meters': template.poolLengthMeters,
        'target_distance_meters': template.targetDistanceMeters,
        'target_time_milliseconds': template.targetTime.inMilliseconds,
        'stroke_rate': template.strokeRate,
        'breath_every_strokes': template.breathEveryStrokes,
        'audible_enabled': template.cueSettings.audible ? 1 : 0,
        'vibration_enabled': template.cueSettings.vibration ? 1 : 0,
        'visual_flash_enabled': template.cueSettings.visualFlash ? 1 : 0,
        'spoken_enabled': template.cueSettings.spoken ? 1 : 0,
        'accent_every': template.cueSettings.accentEvery,
        'safety_warning_acknowledged':
            template.safetyWarningAcknowledged ? 1 : 0,
        'created_at': template.createdAt.millisecondsSinceEpoch,
        'updated_at': template.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTempoTemplate(String id, String profileId) async {
    final db = await _db.database;
    await db.delete(
      'tempo_templates',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }

  Future<void> insertTempoSessionResult(TempoSessionResult result) async {
    final db = await _db.database;
    await db.insert(
      'tempo_session_results',
      {
        'id': result.id,
        'profile_id': result.profileId,
        'template_id': result.templateId,
        'mode': result.mode.name,
        'started_at': result.startedAt.millisecondsSinceEpoch,
        'completed_at': result.completedAt?.millisecondsSinceEpoch,
        'target_distance_meters': result.targetDistanceMeters,
        'pool_length_meters': result.poolLengthMeters,
        'target_time_milliseconds': result.targetTime.inMilliseconds,
        'target_stroke_rate': result.targetStrokeRate,
        'actual_splits_milliseconds_json': jsonEncode(
          result.actualSplits.map((split) => split.inMilliseconds).toList(),
        ),
        'stroke_counts_json': jsonEncode(result.strokeCounts),
        'rpe': result.rpe,
        'notes': result.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TempoSessionResult>> getTempoSessionResults(
    String profileId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'tempo_session_results',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'started_at DESC',
    );
    return rows.map(_tempoSessionResultFromRow).toList();
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

  TempoTemplate _tempoTemplateFromRow(Map<String, Object?> row) {
    return TempoTemplate(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      name: row['name'] as String,
      mode: tempoModeFromName(row['mode'] as String),
      poolLengthMeters: row['pool_length_meters'] as int,
      targetDistanceMeters: row['target_distance_meters'] as int,
      targetTime: Duration(
        milliseconds: row['target_time_milliseconds'] as int,
      ),
      strokeRate: (row['stroke_rate'] as num).toDouble(),
      breathEveryStrokes: row['breath_every_strokes'] as int,
      cueSettings: TempoCueSettings(
        audible: row['audible_enabled'] == 1,
        vibration: row['vibration_enabled'] == 1,
        visualFlash: row['visual_flash_enabled'] == 1,
        spoken: row['spoken_enabled'] == 1,
        accentEvery: row['accent_every'] as int,
      ),
      safetyWarningAcknowledged: row['safety_warning_acknowledged'] == 1,
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

  TempoSessionResult _tempoSessionResultFromRow(Map<String, Object?> row) {
    final splitValues =
        (jsonDecode(row['actual_splits_milliseconds_json'] as String) as List)
            .cast<int>();
    final strokeCounts =
        (jsonDecode(row['stroke_counts_json'] as String) as List).cast<int>();

    return TempoSessionResult(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      templateId: row['template_id'] as String?,
      mode: tempoModeFromName(row['mode'] as String),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        row['started_at'] as int,
        isUtc: true,
      ),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row['completed_at'] as int,
              isUtc: true,
            ),
      targetDistanceMeters: row['target_distance_meters'] as int,
      poolLengthMeters: row['pool_length_meters'] as int,
      targetTime: Duration(
        milliseconds: row['target_time_milliseconds'] as int,
      ),
      targetStrokeRate: (row['target_stroke_rate'] as num).toDouble(),
      actualSplits: [
        for (final milliseconds in splitValues)
          Duration(milliseconds: milliseconds),
      ],
      strokeCounts: strokeCounts,
      rpe: row['rpe'] as int?,
      notes: row['notes'] as String?,
    );
  }
}
