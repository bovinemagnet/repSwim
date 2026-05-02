import '../../features/tempo/domain/entities/tempo_session_result.dart';
import '../../features/tempo/domain/entities/tempo_template.dart';
import '../../features/dryland/domain/entities/dryland_workout.dart';
import '../../features/dryland/domain/entities/exercise.dart';
import '../../features/profiles/domain/entities/swimmer_profile.dart';
import '../../features/race/domain/entities/qualification_standard.dart';
import '../../features/race/domain/entities/race_time.dart';
import '../../features/swim/domain/entities/lap.dart';
import '../../features/swim/domain/entities/swim_session.dart';
import '../../features/templates/domain/entities/dryland_routine_template.dart';
import '../../features/templates/domain/entities/interval_template.dart';

Map<String, Object?> swimSessionPayload(SwimSession session) {
  return {
    'id': session.id,
    'profileId': session.profileId,
    'date': session.date.toUtc().millisecondsSinceEpoch,
    'totalDistance': session.totalDistance,
    'totalTimeSeconds': session.totalTime.inSeconds,
    'stroke': session.stroke,
    'notes': session.notes,
    'laps': session.laps.map(lapPayload).toList(),
  };
}

Map<String, Object?> lapPayload(Lap lap) {
  return {
    'id': lap.id,
    'sessionId': lap.sessionId,
    'profileId': lap.profileId,
    'distance': lap.distance,
    'timeSeconds': lap.time.inSeconds,
    'lapNumber': lap.lapNumber,
  };
}

Map<String, Object?> drylandWorkoutPayload(DrylandWorkout workout) {
  return {
    'id': workout.id,
    'profileId': workout.profileId,
    'date': workout.date.toUtc().millisecondsSinceEpoch,
    'notes': workout.notes,
    'exercises': workout.exercises.map(exercisePayload).toList(),
  };
}

Map<String, Object?> exercisePayload(Exercise exercise) {
  return {
    'id': exercise.id,
    'workoutId': exercise.workoutId,
    'profileId': exercise.profileId,
    'name': exercise.name,
    'sets': exercise.sets,
    'reps': exercise.reps,
    'weight': exercise.weight,
  };
}

Map<String, Object?> swimmerProfilePayload(SwimmerProfile profile) {
  return {
    'id': profile.id,
    'displayName': profile.displayName,
    'preferredPoolLengthMeters': profile.preferredPoolLengthMeters,
    'photoUri': profile.photoUri,
    'preferredStrokes': profile.preferredStrokes,
    'primaryEvents': profile.primaryEvents,
    'clubName': profile.clubName,
    'goals': profile.goals,
    'notes': profile.notes,
    'createdAt': profile.createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': profile.updatedAt.toUtc().millisecondsSinceEpoch,
  };
}

Map<String, Object?> raceTimePayload(RaceTime raceTime) {
  return {
    'id': raceTime.id,
    'profileId': raceTime.profileId,
    'raceName': raceTime.raceName,
    'eventDate': raceTime.eventDate.toUtc().millisecondsSinceEpoch,
    'distance': raceTime.distance,
    'stroke': raceTime.stroke,
    'courseType': raceTime.course.name,
    'timeCentiseconds': raceTime.timeCentiseconds,
    'notes': raceTime.notes,
    'placement': raceTime.placement,
    'location': raceTime.location,
    'createdAt': raceTime.createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': raceTime.updatedAt.toUtc().millisecondsSinceEpoch,
  };
}

Map<String, Object?> qualificationStandardPayload(
  QualificationStandard standard,
) {
  return {
    'id': standard.id,
    'profileId': standard.profileId,
    'age': standard.age,
    'distance': standard.distance,
    'stroke': standard.stroke,
    'courseType': standard.course.name,
    'goldCentiseconds': standard.goldCentiseconds,
    'silverCentiseconds': standard.silverCentiseconds,
    'bronzeCentiseconds': standard.bronzeCentiseconds,
    'createdAt': standard.createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': standard.updatedAt.toUtc().millisecondsSinceEpoch,
  };
}

Map<String, Object?> intervalTemplatePayload(IntervalTemplate template) {
  return {
    'id': template.id,
    'profileId': template.profileId,
    'name': template.name,
    'sets': template.sets,
    'reps': template.reps,
    'workSeconds': template.workDuration.inSeconds,
    'restSeconds': template.restDuration.inSeconds,
    'createdAt': template.createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': template.updatedAt.toUtc().millisecondsSinceEpoch,
  };
}

Map<String, Object?> tempoTemplatePayload(TempoTemplate template) {
  return {
    'id': template.id,
    'profileId': template.profileId,
    'name': template.name,
    'mode': template.mode.name,
    'poolLengthMeters': template.poolLengthMeters,
    'targetDistanceMeters': template.targetDistanceMeters,
    'targetTimeMilliseconds': template.targetTime.inMilliseconds,
    'strokeRate': template.strokeRate,
    'breathEveryStrokes': template.breathEveryStrokes,
    'audibleEnabled': template.cueSettings.audible,
    'vibrationEnabled': template.cueSettings.vibration,
    'visualFlashEnabled': template.cueSettings.visualFlash,
    'spokenEnabled': template.cueSettings.spoken,
    'accentEvery': template.cueSettings.accentEvery,
    'safetyWarningAcknowledged': template.safetyWarningAcknowledged,
    'createdAt': template.createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': template.updatedAt.toUtc().millisecondsSinceEpoch,
  };
}

Map<String, Object?> tempoSessionResultPayload(TempoSessionResult result) {
  return {
    'id': result.id,
    'profileId': result.profileId,
    'templateId': result.templateId,
    'mode': result.mode.name,
    'startedAt': result.startedAt.toUtc().millisecondsSinceEpoch,
    'completedAt': result.completedAt?.toUtc().millisecondsSinceEpoch,
    'targetDistanceMeters': result.targetDistanceMeters,
    'poolLengthMeters': result.poolLengthMeters,
    'targetTimeMilliseconds': result.targetTime.inMilliseconds,
    'targetStrokeRate': result.targetStrokeRate,
    'actualSplitsMilliseconds': [
      for (final split in result.actualSplits) split.inMilliseconds,
    ],
    'strokeCounts': result.strokeCounts,
    'rpe': result.rpe,
    'notes': result.notes,
  };
}

Map<String, Object?> drylandRoutineTemplatePayload(
  DrylandRoutineTemplate template,
) {
  return {
    'id': template.id,
    'profileId': template.profileId,
    'name': template.name,
    'notes': template.notes,
    'createdAt': template.createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': template.updatedAt.toUtc().millisecondsSinceEpoch,
    'exercises': template.exercises.map(drylandRoutineExercisePayload).toList(),
  };
}

Map<String, Object?> drylandRoutineExercisePayload(
  DrylandRoutineExerciseTemplate exercise,
) {
  return {
    'id': exercise.id,
    'templateId': exercise.templateId,
    'profileId': exercise.profileId,
    'name': exercise.name,
    'sets': exercise.sets,
    'reps': exercise.reps,
    'weight': exercise.weight,
  };
}

Map<String, Object?> deletedEntityPayload({
  required String id,
  required String profileId,
}) {
  return {
    'id': id,
    'profileId': profileId,
  };
}
