import 'sync_queue_item.dart';

class SyncPushResult {
  const SyncPushResult({
    required this.itemId,
    required this.accepted,
    this.error,
  });

  const SyncPushResult.accepted(String itemId)
      : this(itemId: itemId, accepted: true);

  const SyncPushResult.rejected(String itemId, String error)
      : this(itemId: itemId, accepted: false, error: error);

  final String itemId;
  final bool accepted;
  final String? error;
}

abstract class SyncBackendClient {
  Future<List<SyncPushResult>> pushChanges(List<SyncQueueItem> changes);

  Future<List<SyncQueueItem>> pullChanges({
    required String profileId,
    DateTime? since,
  });
}
