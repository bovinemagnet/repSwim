import 'sync_queue_item.dart';

abstract class SyncBackendClient {
  Future<void> pushChanges(List<SyncQueueItem> changes);

  Future<List<SyncQueueItem>> pullChanges({
    required String profileId,
    DateTime? since,
  });
}
