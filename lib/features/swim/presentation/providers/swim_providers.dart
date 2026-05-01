import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/swim_session_dao.dart';
import '../../../../database/daos/pb_dao.dart';
import '../../../../database/daos/dryland_dao.dart';
import '../../../../database/daos/sync_queue_dao.dart';
import '../../../../core/sync/sync_mode.dart';
import '../../../../core/sync/sync_payloads.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../domain/entities/swim_session.dart';
import '../../domain/repositories/swim_repository.dart';
import '../../data/repositories/swim_repository_impl.dart';
import '../../../profiles/presentation/providers/profile_providers.dart';

// ─── Infrastructure providers ────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final swimSessionDaoProvider = Provider<SwimSessionDao>((ref) {
  return SwimSessionDao(ref.read(databaseProvider));
});

final pbDaoProvider = Provider<PbDao>((ref) {
  return PbDao(ref.read(databaseProvider));
});

final drylandDaoProvider = Provider<DrylandDao>((ref) {
  return DrylandDao(ref.read(databaseProvider));
});

// ─── Repository provider ─────────────────────────────────────────────────────

final swimRepositoryProvider = Provider<SwimRepository>((ref) {
  return SwimRepositoryImpl(ref.read(swimSessionDaoProvider));
});

// ─── Swim sessions notifier ───────────────────────────────────────────────────

class SwimSessionsNotifier
    extends StateNotifier<AsyncValue<List<SwimSession>>> {
  SwimSessionsNotifier(
    this._repository,
    this._profileId, {
    SyncQueueDao? syncQueueDao,
  })  : _syncQueueDao = syncQueueDao,
        super(const AsyncValue.loading()) {
    load();
  }

  final SwimRepository _repository;
  final String _profileId;
  final SyncQueueDao? _syncQueueDao;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _repository.getAllSessions(_profileId);
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSession(SwimSession session) async {
    await _repository.saveSession(session);
    await _queueChange(
      entityType: 'swim_session',
      entityId: session.id,
      profileId: session.profileId,
      operation: SyncOperation.create,
      payload: swimSessionPayload(session),
    );
    await load();
  }

  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(id, _profileId);
    await _queueChange(
      entityType: 'swim_session',
      entityId: id,
      profileId: _profileId,
      operation: SyncOperation.delete,
      payload: deletedEntityPayload(id: id, profileId: _profileId),
    );
    await load();
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
    } catch (_) {
      // Sync queue failures must not block local-first writes.
    }
  }
}

final swimSessionsProvider =
    StateNotifierProvider<SwimSessionsNotifier, AsyncValue<List<SwimSession>>>(
  (ref) => SwimSessionsNotifier(
    ref.read(swimRepositoryProvider),
    ref.watch(currentProfileIdProvider),
    syncQueueDao: ref.read(syncQueueDaoProvider),
  ),
);
