enum SyncMode {
  localOnly,
  manual,
  automatic,
}

enum SyncQueueStatus {
  pending,
  processing,
  failed,
  complete,
}

enum SyncOperation {
  create,
  update,
  delete,
}
