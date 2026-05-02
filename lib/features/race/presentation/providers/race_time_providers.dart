import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_payloads.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/race_time_dao.dart';
import '../../../../database/daos/sync_queue_dao.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../domain/entities/race_time.dart';

const _uuid = Uuid();

final raceTimeDaoProvider = Provider<RaceTimeDao>((ref) {
  return RaceTimeDao(AppDatabase.instance);
});

class RaceTimesNotifier extends StateNotifier<AsyncValue<List<RaceTime>>> {
  RaceTimesNotifier(
    this._dao,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
    void Function(Object error)? onQueueFailure,
  })  : _syncQueueDao = syncQueueDao,
        _onQueueFailure = onQueueFailure,
        super(const AsyncValue.loading()) {
    load();
  }

  final RaceTimeDao _dao;
  final String _profileId;
  final SyncQueueDao? _syncQueueDao;
  final void Function(Object error)? _onQueueFailure;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _dao.getAll(_profileId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<RaceTime> addRaceTime({
    required String raceName,
    required DateTime eventDate,
    required int distance,
    required String stroke,
    required RaceCourse course,
    required Duration time,
    String? notes,
    int? placement,
    String? location,
  }) async {
    final now = DateTime.now().toUtc();
    final raceTime = RaceTime(
      id: _uuid.v4(),
      profileId: _profileId,
      raceName: raceName.trim(),
      eventDate: eventDate,
      distance: distance,
      stroke: stroke,
      course: course,
      time: time,
      notes: _cleanText(notes),
      placement: placement,
      location: _cleanText(location),
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertOrUpdate(raceTime);
    await _queueRaceTime(raceTime, operation: SyncOperation.create);
    await load();
    return raceTime;
  }

  Future<void> updateRaceTime(RaceTime raceTime) async {
    final updated = raceTime.copyWith(
      raceName: raceTime.raceName.trim(),
      notes: _cleanText(raceTime.notes),
      clearNotes: _cleanText(raceTime.notes) == null,
      location: _cleanText(raceTime.location),
      clearLocation: _cleanText(raceTime.location) == null,
      updatedAt: DateTime.now().toUtc(),
    );
    await _dao.insertOrUpdate(updated);
    await _queueRaceTime(updated, operation: SyncOperation.update);
    await load();
  }

  Future<void> deleteRaceTime(String id) async {
    await _dao.delete(id, _profileId);
    await _queueChange(
      entityId: id,
      operation: SyncOperation.delete,
      payload: deletedEntityPayload(id: id, profileId: _profileId),
    );
    await load();
  }

  Future<void> _queueRaceTime(
    RaceTime raceTime, {
    required SyncOperation operation,
  }) async {
    await _queueChange(
      entityId: raceTime.id,
      operation: operation,
      payload: raceTimePayload(raceTime),
    );
  }

  Future<void> _queueChange({
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) async {
    try {
      await _syncQueueDao?.enqueue(
        profileId: _profileId,
        entityType: 'race_time',
        entityId: entityId,
        operation: operation,
        payload: payload,
      );
    } catch (error) {
      _onQueueFailure?.call(error);
    }
  }
}

String? _cleanText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

final raceTimesProvider =
    StateNotifierProvider<RaceTimesNotifier, AsyncValue<List<RaceTime>>>(
  (ref) => RaceTimesNotifier(
    ref.read(raceTimeDaoProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
    onQueueFailure: (error) {
      ref.read(syncQueueFailureProvider.notifier).state = error.toString();
    },
  ),
);
