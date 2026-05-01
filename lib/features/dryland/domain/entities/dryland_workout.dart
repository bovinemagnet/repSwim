import '../../../../core/constants/app_constants.dart';
import 'exercise.dart';

class DrylandWorkout {
  const DrylandWorkout({
    required this.id,
    required this.date,
    required this.exercises,
    this.profileId = kDefaultProfileId,
    this.notes,
  });

  final String id;
  final String profileId;
  final DateTime date;
  final List<Exercise> exercises;
  final String? notes;

  DrylandWorkout copyWith({
    String? id,
    String? profileId,
    DateTime? date,
    List<Exercise>? exercises,
    String? notes,
  }) {
    return DrylandWorkout(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      date: date ?? this.date,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }
}
