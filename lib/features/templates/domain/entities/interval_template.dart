import '../../../../core/constants/app_constants.dart';

class IntervalTemplate {
  const IntervalTemplate({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.workDuration,
    required this.restDuration,
    required this.createdAt,
    required this.updatedAt,
    this.profileId = kDefaultProfileId,
  });

  final String id;
  final String profileId;
  final String name;
  final int sets;
  final int reps;
  final Duration workDuration;
  final Duration restDuration;
  final DateTime createdAt;
  final DateTime updatedAt;
}
