import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_mode.dart';
import '../../core/sync/sync_queue_item.dart';
import '../app_database.dart';

class SyncQueueSummary {
  const SyncQueueSummary({
    this.pending = 0,
    this.processing = 0,
    this.failed = 0,
    this.complete = 0,
  });

  final int pending;
  final int processing;
  final int failed;
  final int complete;

  int get total => pending + processing + failed + complete;
}

class SyncQueueDao {
  SyncQueueDao(
    this._db, {
    String Function()? idFactory,
    DateTime Function()? clock,
  })  : _idFactory = idFactory ?? const Uuid().v4,
        _clock = clock ?? _utcNow;

  final AppDatabase _db;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  Future<void> enqueue({
    required String profileId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, Object?> payload,
  }) async {
    final db = await _db.database;
    final now = _clock().millisecondsSinceEpoch;
    await db.insert(
      'sync_queue',
      {
        'id': _idFactory(),
        'profile_id': profileId,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation.name,
        'payload_json': jsonEncode(payload),
        'status': SyncQueueStatus.pending.name,
        'retry_count': 0,
        'last_error': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItem>> getPending({
    required String profileId,
    int limit = 100,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'sync_queue',
      where: 'profile_id = ? AND status IN (?, ?)',
      whereArgs: [
        profileId,
        SyncQueueStatus.pending.name,
        SyncQueueStatus.failed.name,
      ],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<SyncQueueSummary> getSummary({required String profileId}) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT status, COUNT(*) AS count
      FROM sync_queue
      WHERE profile_id = ?
      GROUP BY status
      ''',
      [profileId],
    );

    final counts = <String, int>{
      for (final row in rows) row['status'] as String: row['count'] as int,
    };
    return SyncQueueSummary(
      pending: counts[SyncQueueStatus.pending.name] ?? 0,
      processing: counts[SyncQueueStatus.processing.name] ?? 0,
      failed: counts[SyncQueueStatus.failed.name] ?? 0,
      complete: counts[SyncQueueStatus.complete.name] ?? 0,
    );
  }

  Future<void> markComplete(String id) async {
    await _updateStatus(id, SyncQueueStatus.complete);
  }

  Future<void> markFailed(String id, Object error) async {
    await _updateStatus(
      id,
      SyncQueueStatus.failed,
      lastError: error.toString(),
      incrementRetry: true,
    );
  }

  Future<void> _updateStatus(
    String id,
    SyncQueueStatus status, {
    String? lastError,
    bool incrementRetry = false,
  }) async {
    final db = await _db.database;
    if (incrementRetry) {
      await db.rawUpdate(
        '''
        UPDATE sync_queue
        SET status = ?, last_error = ?, updated_at = ?, retry_count = retry_count + 1
        WHERE id = ?
        ''',
        [status.name, lastError, _clock().millisecondsSinceEpoch, id],
      );
      return;
    }
    await db.update(
      'sync_queue',
      {
        'status': status.name,
        'last_error': lastError,
        'updated_at': _clock().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  SyncQueueItem _fromRow(Map<String, Object?> row) {
    return SyncQueueItem(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String,
      operation: SyncOperation.values.byName(row['operation'] as String),
      payloadJson: row['payload_json'] as String,
      status: SyncQueueStatus.values.byName(row['status'] as String),
      retryCount: row['retry_count'] as int,
      lastError: row['last_error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at'] as int,
        isUtc: true,
      ),
    );
  }
}
