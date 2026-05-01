import 'exercise.dart';

class DrylandWorkout {
  const DrylandWorkout({
    required this.id,
    required this.date,
    required this.exercises,
    this.notes,
  });

  final String id;
  final DateTime date;
  final List<Exercise> exercises;
  final String? notes;

  DrylandWorkout copyWith({
    String? id,
    DateTime? date,
    List<Exercise>? exercises,
    String? notes,
  }) {
    return DrylandWorkout(
      id: id ?? this.id,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }
}
