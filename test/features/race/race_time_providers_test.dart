import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/daos/race_time_dao.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/race/presentation/providers/race_time_providers.dart';

class _MockRaceTimeDao extends Mock implements RaceTimeDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

void main() {
  setUpAll(() {
    registerFallbackValue(_raceTime());
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(SyncOperation.create);
  });

  test('addRaceTime persists and queues a create mutation', () async {
    final dao = _MockRaceTimeDao();
    final queue = _MockSyncQueueDao();
    when(() => dao.getAll(any())).thenAnswer((_) async => []);
    when(() => dao.insertOrUpdate(any())).thenAnswer((_) async {});
    when(
      () => queue.enqueue(
        profileId: any(named: 'profileId'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        operation: any(named: 'operation'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    final notifier = RaceTimesNotifier(
      dao,
      'profile-1',
      syncQueueDao: queue,
    );
    await Future<void>.delayed(Duration.zero);

    final created = await notifier.addRaceTime(
      raceName: ' State Sprint ',
      eventDate: DateTime.utc(2024, 5, 1),
      distance: 100,
      stroke: 'Freestyle',
      course: RaceCourse.longCourseMeters,
      time: const Duration(seconds: 59),
      notes: ' final ',
    );

    expect(created.raceName, 'State Sprint');
    expect(created.notes, 'final');
    verify(() => dao.insertOrUpdate(any())).called(1);
    verify(
      () => queue.enqueue(
        profileId: 'profile-1',
        entityType: 'race_time',
        entityId: created.id,
        operation: SyncOperation.create,
        payload: any(named: 'payload'),
      ),
    ).called(1);
  });

  test('deleteRaceTime does not block local delete when queue fails', () async {
    final dao = _MockRaceTimeDao();
    final queue = _MockSyncQueueDao();
    Object? reportedError;
    when(() => dao.getAll(any())).thenAnswer((_) async => []);
    when(() => dao.delete(any(), any())).thenAnswer((_) async {});
    when(
      () => queue.enqueue(
        profileId: any(named: 'profileId'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        operation: any(named: 'operation'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(Exception('queue down'));

    final notifier = RaceTimesNotifier(
      dao,
      'profile-1',
      syncQueueDao: queue,
      onQueueFailure: (error) => reportedError = error,
    );
    await Future<void>.delayed(Duration.zero);

    await notifier.deleteRaceTime('race-1');

    verify(() => dao.delete('race-1', 'profile-1')).called(1);
    expect(reportedError, isA<Exception>());
  });
}

RaceTime _raceTime() {
  return RaceTime(
    id: 'race-1',
    profileId: 'profile-1',
    raceName: 'Club Champs',
    eventDate: DateTime.utc(2024, 5, 1),
    distance: 100,
    stroke: 'Freestyle',
    course: RaceCourse.shortCourseMeters,
    time: const Duration(seconds: 60),
    createdAt: DateTime.utc(2024, 5, 1),
    updatedAt: DateTime.utc(2024, 5, 1),
  );
}
