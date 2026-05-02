import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/sync/sync_payloads.dart';
import 'package:rep_swim/features/dryland/domain/entities/dryland_workout.dart';
import 'package:rep_swim/features/dryland/domain/entities/exercise.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/race/domain/entities/qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
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
        photoUri: 'https://example.com/ethan.jpg',
        preferredStrokes: const ['Freestyle', 'Backstroke'],
        primaryEvents: '50m free',
        clubName: 'Metro Swim',
        goals: 'State finals',
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
        'photoUri': 'https://example.com/ethan.jpg',
        'preferredStrokes': ['Freestyle', 'Backstroke'],
        'primaryEvents': '50m free',
        'clubName': 'Metro Swim',
        'goals': 'State finals',
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

    test('serializes race times with course and centiseconds', () {
      final raceTime = RaceTime(
        id: 'race-time-1',
        profileId: 'profile-1',
        raceName: 'State Sprint',
        eventDate: DateTime.utc(2024, 5, 1),
        distance: 100,
        stroke: 'Freestyle',
        course: RaceCourse.longCourseMeters,
        time: const Duration(minutes: 1, seconds: 2, milliseconds: 340),
        notes: 'Final',
        placement: 2,
        location: 'MSAC',
        createdAt: DateTime.utc(2024, 5, 1, 1),
        updatedAt: DateTime.utc(2024, 5, 1, 2),
      );

      expect(raceTimePayload(raceTime), {
        'id': 'race-time-1',
        'profileId': 'profile-1',
        'raceName': 'State Sprint',
        'eventDate': 1714521600000,
        'distance': 100,
        'stroke': 'Freestyle',
        'courseType': 'longCourseMeters',
        'timeCentiseconds': 6234,
        'notes': 'Final',
        'placement': 2,
        'location': 'MSAC',
        'createdAt': 1714525200000,
        'updatedAt': 1714528800000,
      });
    });

    test('serializes qualification standards by age and medal tier', () {
      final standard = QualificationStandard(
        id: 'standard-1',
        profileId: 'profile-1',
        age: 12,
        distance: 50,
        stroke: 'Freestyle',
        course: RaceCourse.shortCourseMeters,
        goldTime: const Duration(seconds: 30),
        silverTime: const Duration(seconds: 32),
        bronzeTime: const Duration(seconds: 35),
        createdAt: DateTime.utc(2024, 5, 1, 1),
        updatedAt: DateTime.utc(2024, 5, 1, 2),
      );

      expect(qualificationStandardPayload(standard), {
        'id': 'standard-1',
        'profileId': 'profile-1',
        'age': 12,
        'distance': 50,
        'stroke': 'Freestyle',
        'courseType': 'shortCourseMeters',
        'goldCentiseconds': 3000,
        'silverCentiseconds': 3200,
        'bronzeCentiseconds': 3500,
        'createdAt': 1714525200000,
        'updatedAt': 1714528800000,
      });
    });
  });
}
