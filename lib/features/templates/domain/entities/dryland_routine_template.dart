import '../../../../core/constants/app_constants.dart';

class DrylandRoutineTemplate {
  const DrylandRoutineTemplate({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.profileId = kDefaultProfileId,
    this.notes,
  });

  final String id;
  final String profileId;
  final String name;
  final List<DrylandRoutineExerciseTemplate> exercises;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class DrylandRoutineExerciseTemplate {
  const DrylandRoutineExerciseTemplate({
    required this.id,
    required this.templateId,
    required this.name,
    required this.sets,
    required this.reps,
    this.profileId = kDefaultProfileId,
    this.weight,
  });

  final String id;
  final String templateId;
  final String profileId;
  final String name;
  final int sets;
  final int reps;
  final double? weight;
}
