import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/dryland_dao.dart';
import 'package:rep_swim/database/daos/pb_dao.dart';
import 'package:rep_swim/database/daos/swim_session_dao.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/database/daos/training_template_dao.dart';
import 'package:rep_swim/features/dryland/domain/entities/dryland_workout.dart';
import 'package:rep_swim/features/dryland/domain/entities/exercise.dart';
import 'package:rep_swim/features/pb/domain/entities/personal_best.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/templates/domain/entities/dryland_routine_template.dart';

void main() {
  group('DAO integration', () {
    late AppDatabase appDb;

    setUp(() {
      appDb = AppDatabase.test();
    });

    tearDown(() async {
      await appDb.close();
    });

    test('swim session insert replaces laps and delete cascades', () async {
      final dao = SwimSessionDao(appDb);
      final session = SwimSession(
        id: 'session-1',
        profileId: 'profile-1',
        date: DateTime.utc(2024),
        totalDistance: 100,
        totalTime: const Duration(seconds: 90),
        stroke: 'Freestyle',
        laps: const [
          Lap(
            id: 'lap-1',
            sessionId: 'session-1',
            profileId: 'profile-1',
            distance: 50,
            time: Duration(seconds: 45),
            lapNumber: 1,
          ),
          Lap(
            id: 'lap-2',
            sessionId: 'session-1',
            profileId: 'profile-1',
            distance: 50,
            time: Duration(seconds: 45),
            lapNumber: 2,
          ),
        ],
      );

      await dao.insertSession(session);
      await dao.insertSession(
        session.copyWith(
          totalDistance: 50,
          totalTime: const Duration(seconds: 40),
          laps: const [
            Lap(
              id: 'lap-3',
              sessionId: 'session-1',
              profileId: 'profile-1',
              distance: 50,
              time: Duration(seconds: 40),
              lapNumber: 1,
            ),
          ],
        ),
      );

      final sessions = await dao.getAllSessions('profile-1');
      expect(sessions.single.laps, hasLength(1));
      expect(sessions.single.laps.single.id, 'lap-3');

      await dao.deleteSession('session-1', 'profile-1');
      expect(await dao.getLapsForSession('session-1', 'profile-1'), isEmpty);
    });

    test('swim session rolls back when a lap insert fails', () async {
      final dao = SwimSessionDao(appDb);
      final session = SwimSession(
        id: 'session-rollback',
        profileId: 'profile-1',
        date: DateTime.utc(2024),
        totalDistance: 50,
        totalTime: const Duration(seconds: 40),
        stroke: 'Freestyle',
        laps: const [
          Lap(
            id: 'lap-bad',
            sessionId: 'missing-session',
            profileId: 'profile-1',
            distance: 50,
            time: Duration(seconds: 40),
            lapNumber: 1,
          ),
        ],
      );

      await expectLater(dao.insertSession(session), throwsA(isA<Exception>()));
      expect(await dao.getAllSessions('profile-1'), isEmpty);
    });

    test('dryland workout update replaces exercises', () async {
      final dao = DrylandDao(appDb);
      final workout = DrylandWorkout(
        id: 'workout-1',
        profileId: 'profile-1',
        date: DateTime.utc(2024),
        exercises: const [
          Exercise(
            id: 'exercise-1',
            workoutId: 'workout-1',
            profileId: 'profile-1',
            name: 'Plank',
            sets: 3,
            reps: 1,
          ),
        ],
      );

      await dao.insertWorkout(workout);
      await dao.insertWorkout(
        workout.copyWith(
          exercises: const [
            Exercise(
              id: 'exercise-2',
              workoutId: 'workout-1',
              profileId: 'profile-1',
              name: 'Dead bug',
              sets: 2,
              reps: 10,
            ),
          ],
        ),
      );

      final workouts = await dao.getAll('profile-1');
      expect(workouts.single.exercises.single.name, 'Dead bug');
    });

    test('template delete cascades routine exercises', () async {
      final dao = TrainingTemplateDao(appDb);
      final now = DateTime.utc(2024);
      final template = DrylandRoutineTemplate(
        id: 'template-1',
        profileId: 'profile-1',
        name: 'Core',
        createdAt: now,
        updatedAt: now,
        exercises: const [
          DrylandRoutineExerciseTemplate(
            id: 'template-exercise-1',
            templateId: 'template-1',
            profileId: 'profile-1',
            name: 'Plank',
            sets: 3,
            reps: 1,
          ),
        ],
      );

      await dao.insertDrylandRoutineTemplate(template);
      await dao.deleteDrylandRoutineTemplate('template-1', 'profile-1');

      expect(
        await dao.getDrylandRoutineExercises('template-1', 'profile-1'),
        isEmpty,
      );
    });

    test('sync queue preserves insertion order and increments retry count',
        () async {
      var nextId = 0;
      final dao = SyncQueueDao(
        appDb,
        idFactory: () => 'queue-${nextId++}',
        clock: () => DateTime.utc(2024),
      );

      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'one',
        operation: SyncOperation.create,
        payload: const {'id': 'one'},
      );
      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'two',
        operation: SyncOperation.create,
        payload: const {'id': 'two'},
      );

      final pending = await dao.getPending(profileId: 'profile-1');
      expect(pending.map((item) => item.entityId), ['one', 'two']);

      await dao.markFailed(pending.first.id, 'network');
      final summary = await dao.getSummary(profileId: 'profile-1');
      final retryable = await dao.getPending(profileId: 'profile-1');
      expect(summary.failed, 1);
      expect(retryable.first.retryCount, 1);
    });

    test('sync queue excludes completed items from pending replay', () async {
      var nextId = 0;
      final dao = SyncQueueDao(
        appDb,
        idFactory: () => 'queue-${nextId++}',
        clock: () => DateTime.utc(2024),
      );

      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'one',
        operation: SyncOperation.create,
        payload: const {'id': 'one'},
      );
      await dao.enqueue(
        profileId: 'profile-1',
        entityType: 'swim_session',
        entityId: 'two',
        operation: SyncOperation.update,
        payload: const {'id': 'two'},
      );

      final firstPending = await dao.getPending(profileId: 'profile-1');
      await dao.markComplete(firstPending.first.id);

      final remaining = await dao.getPending(profileId: 'profile-1');
      final summary = await dao.getSummary(profileId: 'profile-1');
      expect(remaining.map((item) => item.entityId), ['two']);
      expect(summary.complete, 1);
      expect(summary.pending, 1);
    });

    test('personal best insertOrUpdate keeps one row per stroke and distance',
        () async {
      final dao = PbDao(appDb);
      await dao.insertOrUpdate(
        PersonalBest(
          id: 'pb-slow',
          profileId: 'profile-1',
          stroke: 'Freestyle',
          distance: 100,
          bestTime: const Duration(seconds: 70),
          achievedAt: DateTime.utc(2024, 1, 1),
        ),
      );
      await dao.insertOrUpdate(
        PersonalBest(
          id: 'pb-fast',
          profileId: 'profile-1',
          stroke: 'Freestyle',
          distance: 100,
          bestTime: const Duration(seconds: 62),
          achievedAt: DateTime.utc(2024, 1, 2),
        ),
      );

      final pbs = await dao.getAll('profile-1');
      expect(pbs, hasLength(1));
      expect(pbs.single.id, 'pb-slow');
      expect(pbs.single.bestTime, const Duration(seconds: 62));
    });
  });
}
