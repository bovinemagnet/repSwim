import '../../database/daos/sync_queue_dao.dart';
import 'sync_backend_client.dart';
import 'sync_mode.dart';

class SyncService {
  const SyncService({
    required this.mode,
    this.queueDao,
    this.client,
  });

  final SyncMode mode;
  final SyncQueueDao? queueDao;
  final SyncBackendClient? client;

  bool get isEnabled => mode != SyncMode.localOnly && client != null;

  Future<void> syncNow({required String profileId}) async {
    if (!isEnabled) return;

    final pending = await queueDao?.getPending(profileId: profileId) ?? [];
    if (pending.isNotEmpty) {
      try {
        final results = await client!.pushChanges(pending);
        final resultsById = {
          for (final result in results) result.itemId: result
        };
        for (final item in pending) {
          final result = resultsById[item.id];
          if (result == null) {
            await queueDao?.markFailed(item.id, 'Missing sync result');
          } else if (result.accepted) {
            await queueDao?.markComplete(item.id);
          } else {
            await queueDao?.markFailed(
              item.id,
              result.error ?? 'Sync item rejected',
            );
          }
        }
      } catch (error) {
        for (final item in pending) {
          await queueDao?.markFailed(item.id, error);
        }
        rethrow;
      }
    }

    // Pull/apply is intentionally still a placeholder until the backend
    // contract and conflict rules are defined.
    // Local-first app behavior should never depend on this completing.
    await client!.pullChanges(profileId: profileId);
  }
}
