import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/database/daos/training_template_dao.dart';
import 'package:rep_swim/features/dryland/domain/entities/dryland_workout.dart';
import 'package:rep_swim/features/dryland/domain/entities/exercise.dart';
import 'package:rep_swim/features/stopwatch/presentation/providers/interval_timer_provider.dart';
import 'package:rep_swim/features/templates/domain/entities/dryland_routine_template.dart';
import 'package:rep_swim/features/templates/domain/entities/interval_template.dart';
import 'package:rep_swim/features/templates/presentation/providers/training_template_providers.dart';

class _MockTrainingTemplateDao extends Mock implements TrainingTemplateDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

IntervalTemplate _intervalTemplate() {
  return IntervalTemplate(
    id: 'interval-1',
    profileId: 'profile-1',
    name: 'Sprint set',
    sets: 2,
    reps: 4,
    workDuration: const Duration(seconds: 30),
    restDuration: const Duration(seconds: 15),
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

DrylandRoutineTemplate _routineTemplate() {
  return DrylandRoutineTemplate(
    id: 'routine-1',
    profileId: 'profile-1',
    name: 'Core',
    notes: 'Steady',
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    exercises: const [
      DrylandRoutineExerciseTemplate(
        id: 'routine-exercise-1',
        templateId: 'routine-1',
        profileId: 'profile-1',
        name: 'Plank',
        sets: 3,
        reps: 1,
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_intervalTemplate());
    registerFallbackValue(_routineTemplate());
    registerFallbackValue(SyncOperation.create);
    registerFallbackValue(<String, Object?>{});
  });

  group('IntervalTemplatesNotifier', () {
    test('saves timer state as an interval template and reloads', () async {
      final dao = _MockTrainingTemplateDao();
      final queue = _MockSyncQueueDao();
      when(() => dao.getIntervalTemplates(any()))
          .thenAnswer((_) async => [_intervalTemplate()]);
      when(() => dao.insertIntervalTemplate(any())).thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = IntervalTemplatesNotifier(
        dao,
        'profile-1',
        syncQueueDao: queue,
      );
      await Future<void>.delayed(Duration.zero);

      final saved = await notifier.saveFromState(
        ' Race pace ',
        const IntervalTimerState(
          sets: 3,
          reps: 5,
          workDuration: Duration(seconds: 40),
          restDuration: Duration(seconds: 20),
        ),
      );

      expect(saved.name, 'Race pace');
      expect(saved.sets, 3);
      expect(saved.reps, 5);
      verify(() => dao.insertIntervalTemplate(any())).called(1);
      verify(
        () => queue.enqueue(
          profileId: 'profile-1',
          entityType: 'interval_template',
          entityId: saved.id,
          operation: SyncOperation.create,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(() => dao.getIntervalTemplates('profile-1'))
          .called(greaterThanOrEqualTo(2));
    });
  });

  group('DrylandRoutineTemplatesNotifier', () {
    test('saves workout exercises as a reusable routine', () async {
      final dao = _MockTrainingTemplateDao();
      final queue = _MockSyncQueueDao();
      when(() => dao.getDrylandRoutineTemplates(any()))
          .thenAnswer((_) async => [_routineTemplate()]);
      when(() => dao.insertDrylandRoutineTemplate(any()))
          .thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = DrylandRoutineTemplatesNotifier(
        dao,
        'profile-1',
        syncQueueDao: queue,
      );
      await Future<void>.delayed(Duration.zero);

      final saved = await notifier.saveFromWorkout(
        ' Core routine ',
        DrylandWorkout(
          id: 'workout-1',
          profileId: 'profile-1',
          date: DateTime.utc(2024),
          notes: 'Hold form',
          exercises: const [
            Exercise(
              id: 'exercise-1',
              workoutId: 'workout-1',
              profileId: 'profile-1',
              name: 'Dead bug',
              sets: 3,
              reps: 12,
            ),
          ],
        ),
      );

      expect(saved.name, 'Core routine');
      expect(saved.notes, 'Hold form');
      expect(saved.exercises.single.name, 'Dead bug');
      verify(() => dao.insertDrylandRoutineTemplate(any())).called(1);
      verify(
        () => queue.enqueue(
          profileId: 'profile-1',
          entityType: 'dryland_routine_template',
          entityId: saved.id,
          operation: SyncOperation.create,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(() => dao.getDrylandRoutineTemplates('profile-1'))
          .called(greaterThanOrEqualTo(2));
    });
  });
}
