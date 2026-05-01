import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/sync/sync_payloads.dart';
import 'package:rep_swim/features/dryland/domain/entities/dryland_workout.dart';
import 'package:rep_swim/features/dryland/domain/entities/exercise.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/templates/domain/entities/dryland_routine_template.dart';
import 'package:rep_swim/features/templates/domain/entities/interval_template.dart';

void main() {
  group('sync payloads', () {
    test('serializes swim sessions with stable keys and lap data', () {
      final session = SwimSession(
        id: 'session-1',
        profileId: 'profile-1',
        date: DateTime.utc(2024, 1, 2),
        totalDistance: 100,
        totalTime: const Duration(seconds: 90),
        stroke: 'Freestyle',
        notes: 'Easy',
        laps: const [
          Lap(
            id: 'lap-1',
            sessionId: 'session-1',
            profileId: 'profile-1',
            distance: 100,
            time: Duration(seconds: 90),
            lapNumber: 1,
          ),
        ],
      );

      expect(
        jsonEncode(swimSessionPayload(session)),
        '{"id":"session-1","profileId":"profile-1","date":1704153600000,'
        '"totalDistance":100,"totalTimeSeconds":90,"stroke":"Freestyle",'
        '"notes":"Easy","laps":[{"id":"lap-1","sessionId":"session-1",'
        '"profileId":"profile-1","distance":100,"timeSeconds":90,'
        '"lapNumber":1}]}',
      );
    });

    test('serializes dryland workouts and profiles', () {
      final workout = DrylandWorkout(
        id: 'workout-1',
        profileId: 'profile-1',
        date: DateTime.utc(2024, 1, 3),
        notes: 'Strength',
        exercises: const [
          Exercise(
            id: 'exercise-1',
            workoutId: 'workout-1',
            profileId: 'profile-1',
            name: 'Squat',
            sets: 3,
            reps: 8,
            weight: 40,
          ),
        ],
      );
      final profile = SwimmerProfile(
        id: 'profile-1',
        displayName: 'Ethan',
        preferredPoolLengthMeters: 50,
        notes: 'Sprint',
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024, 1, 4),
      );

      expect(drylandWorkoutPayload(workout)['profileId'], 'profile-1');
      expect(
        (drylandWorkoutPayload(workout)['exercises'] as List).single,
        containsPair('name', 'Squat'),
      );
      expect(swimmerProfilePayload(profile), {
        'id': 'profile-1',
        'displayName': 'Ethan',
        'preferredPoolLengthMeters': 50,
        'notes': 'Sprint',
        'createdAt': 1704067200000,
        'updatedAt': 1704326400000,
      });
    });

    test('serializes training templates', () {
      final interval = IntervalTemplate(
        id: 'interval-1',
        profileId: 'profile-1',
        name: 'Race pace',
        sets: 3,
        reps: 4,
        workDuration: const Duration(seconds: 45),
        restDuration: const Duration(seconds: 15),
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024, 1, 2),
      );
      final routine = DrylandRoutineTemplate(
        id: 'routine-1',
        profileId: 'profile-1',
        name: 'Core',
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024, 1, 2),
        exercises: const [
          DrylandRoutineExerciseTemplate(
            id: 'exercise-1',
            templateId: 'routine-1',
            profileId: 'profile-1',
            name: 'Plank',
            sets: 3,
            reps: 1,
          ),
        ],
      );

      expect(intervalTemplatePayload(interval), {
        'id': 'interval-1',
        'profileId': 'profile-1',
        'name': 'Race pace',
        'sets': 3,
        'reps': 4,
        'workSeconds': 45,
        'restSeconds': 15,
        'createdAt': 1704067200000,
        'updatedAt': 1704153600000,
      });
      expect(
        (drylandRoutineTemplatePayload(routine)['exercises'] as List).single,
        containsPair('name', 'Plank'),
      );
    });
  });
}
