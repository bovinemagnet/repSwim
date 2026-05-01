import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/daos/dryland_dao.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/features/dryland/domain/entities/dryland_workout.dart';
import 'package:rep_swim/features/dryland/domain/entities/exercise.dart';
import 'package:rep_swim/features/dryland/presentation/providers/dryland_providers.dart';

class _MockDrylandDao extends Mock implements DrylandDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

DrylandWorkout _workout(String id) {
  return DrylandWorkout(
    id: id,
    profileId: 'profile-1',
    date: DateTime(2024, 1, 1),
    notes: 'Core session',
    exercises: [
      Exercise(
        id: 'exercise-$id',
        workoutId: id,
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
    registerFallbackValue(_workout('fallback'));
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(SyncOperation.create);
  });

  group('DrylandWorkoutsNotifier', () {
    test('updateWorkout persists workout and reloads list', () async {
      final dao = _MockDrylandDao();
      final queue = _MockSyncQueueDao();
      final workout = _workout('workout-1');

      when(() => dao.getAll(any())).thenAnswer((_) async => [workout]);
      when(() => dao.insertWorkout(any())).thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = DrylandWorkoutsNotifier(
        dao,
        'profile-1',
        syncQueueDao: queue,
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.updateWorkout(workout);

      verify(() => dao.insertWorkout(workout)).called(1);
      verify(
        () => queue.enqueue(
          profileId: 'profile-1',
          entityType: 'dryland_workout',
          entityId: 'workout-1',
          operation: SyncOperation.update,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(() => dao.getAll('profile-1')).called(greaterThanOrEqualTo(2));
      expect(notifier.state.valueOrNull, [workout]);
    });
  });
}
