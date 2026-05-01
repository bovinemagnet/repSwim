import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_payloads.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../database/daos/dryland_dao.dart';
import '../../../../database/daos/sync_queue_dao.dart';
import '../../domain/entities/dryland_workout.dart';
import '../../../swim/presentation/providers/swim_providers.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';

class DrylandWorkoutsNotifier
    extends StateNotifier<AsyncValue<List<DrylandWorkout>>> {
  DrylandWorkoutsNotifier(
    this._dao,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
    void Function(Object error)? onQueueFailure,
  })  : _syncQueueDao = syncQueueDao,
        _onQueueFailure = onQueueFailure,
        super(const AsyncValue.loading()) {
    load();
  }

  final DrylandDao _dao;
  final String _profileId;
  final SyncQueueDao? _syncQueueDao;
  final void Function(Object error)? _onQueueFailure;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final workouts = await _dao.getAll(_profileId);
      state = AsyncValue.data(workouts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWorkout(DrylandWorkout workout) async {
    await _dao.insertWorkout(workout);
    await _queueWorkout(workout, operation: SyncOperation.create);
    await load();
  }

  Future<void> updateWorkout(DrylandWorkout workout) async {
    await _dao.insertWorkout(workout);
    await _queueWorkout(workout, operation: SyncOperation.update);
    await load();
  }

  Future<void> deleteWorkout(String id) async {
    await _dao.deleteWorkout(id, _profileId);
    await _queueChange(
      entityType: 'dryland_workout',
      entityId: id,
      profileId: _profileId,
      operation: SyncOperation.delete,
      payload: deletedEntityPayload(id: id, profileId: _profileId),
    );
    await load();
  }

  Future<void> _queueWorkout(
    DrylandWorkout workout, {
    required SyncOperation operation,
  }) async {
    await _queueChange(
      entityType: 'dryland_workout',
      entityId: workout.id,
      profileId: workout.profileId,
      operation: operation,
      payload: drylandWorkoutPayload(workout),
    );
  }

  Future<void> _queueChange({
    required String entityType,
    required String entityId,
    required String profileId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) async {
    try {
      await _syncQueueDao?.enqueue(
        profileId: profileId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payload: payload,
      );
    } catch (error) {
      // Sync queue failures must not block local-first writes.
      _onQueueFailure?.call(error);
    }
  }
}

final drylandWorkoutsProvider = StateNotifierProvider<DrylandWorkoutsNotifier,
    AsyncValue<List<DrylandWorkout>>>(
  (ref) => DrylandWorkoutsNotifier(
    ref.read(drylandDaoProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
    onQueueFailure: (error) {
      ref.read(syncQueueFailureProvider.notifier).state = error.toString();
    },
  ),
);
