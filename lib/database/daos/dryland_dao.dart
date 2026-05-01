import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../features/dryland/domain/entities/dryland_workout.dart';
import '../../features/dryland/domain/entities/exercise.dart';

class DrylandDao {
  const DrylandDao(this._db);

  final AppDatabase _db;

  Future<void> insertWorkout(DrylandWorkout workout) async {
    final db = await _db.database;
    await db.insert(
      'dryland_workouts',
      {
        'id': workout.id,
        'date': workout.date.millisecondsSinceEpoch,
        'notes': workout.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (final exercise in workout.exercises) {
      await insertExercise(exercise);
    }
  }

  Future<void> insertExercise(Exercise exercise) async {
    final db = await _db.database;
    await db.insert(
      'exercises',
      {
        'id': exercise.id,
        'workout_id': exercise.workoutId,
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'weight': exercise.weight,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DrylandWorkout>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('dryland_workouts', orderBy: 'date DESC');

    final workouts = <DrylandWorkout>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final exercises = await getExercisesForWorkout(id);
      workouts.add(DrylandWorkout(
        id: id,
        date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
        exercises: exercises,
        notes: row['notes'] as String?,
      ));
    }
    return workouts;
  }

  Future<List<Exercise>> getExercisesForWorkout(String workoutId) async {
    final db = await _db.database;
    final rows = await db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
    return rows
        .map((r) => Exercise(
              id: r['id'] as String,
              workoutId: r['workout_id'] as String,
              name: r['name'] as String,
              sets: r['sets'] as int,
              reps: r['reps'] as int,
              weight: r['weight'] as double?,
            ))
        .toList();
  }

  Future<void> deleteWorkout(String id) async {
    final db = await _db.database;
    // Exercises deleted via ON DELETE CASCADE
    await db.delete('dryland_workouts', where: 'id = ?', whereArgs: [id]);
  }
}
