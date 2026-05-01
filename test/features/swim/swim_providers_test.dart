import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/swim/domain/repositories/swim_repository.dart';
import 'package:rep_swim/features/swim/presentation/providers/swim_providers.dart';

class _MockSwimRepository extends Mock implements SwimRepository {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

SwimSession _session() {
  return SwimSession(
    id: 'session-1',
    profileId: 'profile-1',
    date: DateTime.utc(2024),
    totalDistance: 100,
    totalTime: const Duration(seconds: 90),
    stroke: 'Freestyle',
    laps: const [
      Lap(
        id: 'lap-1',
        sessionId: 'session-1',
        profileId: 'profile-1',
        distance: 100,
        time: Duration(seconds: 90),
        lapNumber: 1,
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_session());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(SyncOperation.create);
  });

  test('addSession saves locally and queues a sync create', () async {
    final repository = _MockSwimRepository();
    final queue = _MockSyncQueueDao();
    final session = _session();

    when(() => repository.getAllSessions(any())).thenAnswer((_) async => []);
    when(() => repository.saveSession(any())).thenAnswer((_) async {});
    when(
      () => queue.enqueue(
        profileId: any(named: 'profileId'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        operation: any(named: 'operation'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    final notifier = SwimSessionsNotifier(
      repository,
      'profile-1',
      syncQueueDao: queue,
    );
    await Future<void>.delayed(Duration.zero);

    await notifier.addSession(session);

    verify(() => repository.saveSession(session)).called(1);
    final verification = verify(
      () => queue.enqueue(
        profileId: captureAny(named: 'profileId'),
        entityType: captureAny(named: 'entityType'),
        entityId: captureAny(named: 'entityId'),
        operation: captureAny(named: 'operation'),
        payload: captureAny(named: 'payload'),
      ),
    );
    expect(verification.captured[0], 'profile-1');
    expect(verification.captured[1], 'swim_session');
    expect(verification.captured[2], 'session-1');
    expect(verification.captured[3], SyncOperation.create);
    expect(verification.captured[4], containsPair('totalDistance', 100));
  });

  test('deleteSession queues a sync delete without blocking reload', () async {
    final repository = _MockSwimRepository();
    final queue = _MockSyncQueueDao();

    when(() => repository.getAllSessions(any())).thenAnswer((_) async => []);
    when(() => repository.deleteSession(any(), any())).thenAnswer((_) async {});
    when(
      () => queue.enqueue(
        profileId: any(named: 'profileId'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        operation: any(named: 'operation'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(Exception('queue unavailable'));

    final notifier = SwimSessionsNotifier(
      repository,
      'profile-1',
      syncQueueDao: queue,
    );
    await Future<void>.delayed(Duration.zero);

    await notifier.deleteSession('session-1');

    verify(() => repository.deleteSession('session-1', 'profile-1')).called(1);
    verify(() => repository.getAllSessions('profile-1'))
        .called(greaterThanOrEqualTo(2));
  });
}
