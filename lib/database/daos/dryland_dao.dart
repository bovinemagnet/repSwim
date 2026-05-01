import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../features/dryland/domain/entities/dryland_workout.dart';
import '../../features/dryland/domain/entities/exercise.dart';

class DrylandDao {
  const DrylandDao(this._db);

  final AppDatabase _db;

  Future<void> insertWorkout(DrylandWorkout workout) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
        'dryland_workouts',
        {
          'id': workout.id,
          'profile_id': workout.profileId,
          'date': workout.date.millisecondsSinceEpoch,
          'notes': workout.notes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'exercises',
        where: 'workout_id = ?',
        whereArgs: [workout.id],
      );

      for (final exercise in workout.exercises) {
        await txn.insert(
          'exercises',
          {
            'id': exercise.id,
            'workout_id': exercise.workoutId,
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

  Future<void> insertExercise(Exercise exercise) async {
    final db = await _db.database;
    await db.insert(
      'exercises',
      {
        'id': exercise.id,
        'workout_id': exercise.workoutId,
        'profile_id': exercise.profileId,
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'weight': exercise.weight,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DrylandWorkout>> getAll(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'dryland_workouts',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'date DESC',
    );

    final workouts = <DrylandWorkout>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final exercises = await getExercisesForWorkout(id, profileId);
      workouts.add(DrylandWorkout(
        id: id,
        profileId: row['profile_id'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
        exercises: exercises,
        notes: row['notes'] as String?,
      ));
    }
    return workouts;
  }

  Future<List<Exercise>> getExercisesForWorkout(
    String workoutId,
    String profileId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'exercises',
      where: 'workout_id = ? AND profile_id = ?',
      whereArgs: [workoutId, profileId],
    );
    return rows
        .map((r) => Exercise(
              id: r['id'] as String,
              workoutId: r['workout_id'] as String,
              profileId: r['profile_id'] as String,
              name: r['name'] as String,
              sets: r['sets'] as int,
              reps: r['reps'] as int,
              weight: r['weight'] as double?,
            ))
        .toList();
  }

  Future<void> deleteWorkout(String id, String profileId) async {
    final db = await _db.database;
    // Exercises deleted via ON DELETE CASCADE
    await db.delete(
      'dryland_workouts',
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, profileId],
    );
  }
}
