import 'sync_mode.dart';

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.profileId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
  });

  final String id;
  final String profileId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final String payloadJson;
  final SyncQueueStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
}
