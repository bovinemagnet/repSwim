import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_payloads.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/meet_qualification_standard_dao.dart';
import '../../../../database/daos/qualification_standard_dao.dart';
import '../../../../database/daos/sync_queue_dao.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../data/qualification_sources/victorian_metro_sc_2026.dart';
import '../../domain/entities/meet_qualification_standard.dart';
import '../../domain/entities/qualification_standard.dart';
import '../../domain/entities/race_time.dart';

const _uuid = Uuid();

final qualificationStandardDaoProvider =
    Provider<QualificationStandardDao>((ref) {
  return QualificationStandardDao(AppDatabase.instance);
});

final meetQualificationStandardDaoProvider =
    Provider<MeetQualificationStandardDao>((ref) {
  return MeetQualificationStandardDao(AppDatabase.instance);
});

class MeetQualificationStandardsNotifier
    extends StateNotifier<AsyncValue<List<MeetQualificationStandard>>> {
  MeetQualificationStandardsNotifier(this._dao)
      : super(const AsyncValue.loading()) {
    load();
  }

  final MeetQualificationStandardDao _dao;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _dao.getAll());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> importVictorianMetroSc2026() async {
    final standards = victorianMetroSc2026QualifyingStandards();
    try {
      await _dao.replaceSource(victorianMetroSc2026SourceName, standards);
      await load();
      return standards.length;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final meetQualificationStandardsProvider = StateNotifierProvider<
    MeetQualificationStandardsNotifier,
    AsyncValue<List<MeetQualificationStandard>>>(
  (ref) => MeetQualificationStandardsNotifier(
    ref.read(meetQualificationStandardDaoProvider),
  ),
);

class QualificationStandardsNotifier
    extends StateNotifier<AsyncValue<List<QualificationStandard>>> {
  QualificationStandardsNotifier(
    this._dao,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
    void Function(Object error)? onQueueFailure,
  })  : _syncQueueDao = syncQueueDao,
        _onQueueFailure = onQueueFailure,
        super(const AsyncValue.loading()) {
    load();
  }

  final QualificationStandardDao _dao;
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

  Future<QualificationStandard> addStandard({
    required int age,
    required int distance,
    required String stroke,
    required RaceCourse course,
    required Duration goldTime,
    required Duration silverTime,
    required Duration bronzeTime,
  }) async {
    final now = DateTime.now().toUtc();
    final standard = QualificationStandard(
      id: _uuid.v4(),
      profileId: _profileId,
      age: age,
      distance: distance,
      stroke: stroke,
      course: course,
      goldTime: goldTime,
      silverTime: silverTime,
      bronzeTime: bronzeTime,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insertOrUpdate(standard);
    await _queueStandard(standard, operation: SyncOperation.create);
    await load();
    return standard;
  }

  Future<void> updateStandard(QualificationStandard standard) async {
    final updated = standard.copyWith(updatedAt: DateTime.now().toUtc());
    await _dao.insertOrUpdate(updated);
    await _queueStandard(updated, operation: SyncOperation.update);
    await load();
  }

  Future<void> deleteStandard(String id) async {
    await _dao.delete(id, _profileId);
    await _queueChange(
      entityId: id,
      operation: SyncOperation.delete,
      payload: deletedEntityPayload(id: id, profileId: _profileId),
    );
    await load();
  }

  Future<void> _queueStandard(
    QualificationStandard standard, {
    required SyncOperation operation,
  }) async {
    await _queueChange(
      entityId: standard.id,
      operation: operation,
      payload: qualificationStandardPayload(standard),
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
        entityType: 'qualification_standard',
        entityId: entityId,
        operation: operation,
        payload: payload,
      );
    } catch (error) {
      _onQueueFailure?.call(error);
    }
  }
}

final qualificationStandardsProvider = StateNotifierProvider<
    QualificationStandardsNotifier, AsyncValue<List<QualificationStandard>>>(
  (ref) => QualificationStandardsNotifier(
    ref.read(qualificationStandardDaoProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
    onQueueFailure: (error) {
      ref.read(syncQueueFailureProvider.notifier).state = error.toString();
    },
  ),
);
