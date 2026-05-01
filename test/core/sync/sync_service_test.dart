import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_backend_client.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/core/sync/sync_queue_item.dart';
import 'package:rep_swim/core/sync/sync_service.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

class _MockSyncBackendClient extends Mock implements SyncBackendClient {}

SyncQueueItem _item(String id) {
  return SyncQueueItem(
    id: id,
    profileId: 'profile-1',
    entityType: 'swim_session',
    entityId: 'session-$id',
    operation: SyncOperation.create,
    payloadJson: '{}',
    status: SyncQueueStatus.pending,
    retryCount: 0,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<SyncQueueItem>[]);
  });

  test('marks acknowledged sync items complete', () async {
    final queue = _MockSyncQueueDao();
    final client = _MockSyncBackendClient();
    final pending = [_item('one'), _item('two')];
    when(() => queue.getPending(profileId: 'profile-1'))
        .thenAnswer((_) async => pending);
    when(() => client.pushChanges(pending)).thenAnswer(
      (_) async => const [
        SyncPushResult.accepted('one'),
        SyncPushResult.accepted('two'),
      ],
    );
    when(() => client.pullChanges(profileId: 'profile-1'))
        .thenAnswer((_) async => []);
    when(() => queue.markComplete(any())).thenAnswer((_) async {});

    await SyncService(
      mode: SyncMode.manual,
      queueDao: queue,
      client: client,
    ).syncNow(profileId: 'profile-1');

    verify(() => queue.markComplete('one')).called(1);
    verify(() => queue.markComplete('two')).called(1);
  });

  test('keeps rejected sync items retryable', () async {
    final queue = _MockSyncQueueDao();
    final client = _MockSyncBackendClient();
    final pending = [_item('one'), _item('two')];
    when(() => queue.getPending(profileId: 'profile-1'))
        .thenAnswer((_) async => pending);
    when(() => client.pushChanges(pending)).thenAnswer(
      (_) async => const [
        SyncPushResult.accepted('one'),
        SyncPushResult.rejected('two', 'conflict'),
      ],
    );
    when(() => client.pullChanges(profileId: 'profile-1'))
        .thenAnswer((_) async => []);
    when(() => queue.markComplete(any())).thenAnswer((_) async {});
    when(() => queue.markFailed(any(), any())).thenAnswer((_) async {});

    await SyncService(
      mode: SyncMode.manual,
      queueDao: queue,
      client: client,
    ).syncNow(profileId: 'profile-1');

    verify(() => queue.markComplete('one')).called(1);
    verify(() => queue.markFailed('two', 'conflict')).called(1);
  });

  test('marks every pending item failed when push throws', () async {
    final queue = _MockSyncQueueDao();
    final client = _MockSyncBackendClient();
    final pending = [_item('one'), _item('two')];
    final error = Exception('offline');
    when(() => queue.getPending(profileId: 'profile-1'))
        .thenAnswer((_) async => pending);
    when(() => client.pushChanges(pending)).thenThrow(error);
    when(() => queue.markFailed(any(), any())).thenAnswer((_) async {});

    await expectLater(
      SyncService(
        mode: SyncMode.manual,
        queueDao: queue,
        client: client,
      ).syncNow(profileId: 'profile-1'),
      throwsA(error),
    );

    verify(() => queue.markFailed('one', error)).called(1);
    verify(() => queue.markFailed('two', error)).called(1);
  });
}
