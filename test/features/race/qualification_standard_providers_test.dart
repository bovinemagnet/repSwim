import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/daos/meet_qualification_standard_dao.dart';
import 'package:rep_swim/database/daos/qualification_standard_dao.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/features/race/data/qualification_sources/victorian_metro_sc_2026.dart';
import 'package:rep_swim/features/race/domain/entities/meet_qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/race/presentation/providers/qualification_standard_providers.dart';

class _MockQualificationStandardDao extends Mock
    implements QualificationStandardDao {}

class _MockMeetQualificationStandardDao extends Mock
    implements MeetQualificationStandardDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

void main() {
  setUpAll(() {
    registerFallbackValue(_standard());
    registerFallbackValue(<MeetQualificationStandard>[]);
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(SyncOperation.create);
  });

  test('addStandard persists and queues a create mutation', () async {
    final dao = _MockQualificationStandardDao();
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

    final notifier = QualificationStandardsNotifier(
      dao,
      'profile-1',
      syncQueueDao: queue,
    );
    await Future<void>.delayed(Duration.zero);

    final created = await notifier.addStandard(
      age: 12,
      distance: 50,
      stroke: 'Freestyle',
      course: RaceCourse.longCourseMeters,
      goldTime: const Duration(seconds: 30),
      silverTime: const Duration(seconds: 32),
      bronzeTime: const Duration(seconds: 35),
    );

    expect(created.age, 12);
    expect(created.course, RaceCourse.longCourseMeters);
    verify(() => dao.insertOrUpdate(any())).called(1);
    verify(
      () => queue.enqueue(
        profileId: 'profile-1',
        entityType: 'qualification_standard',
        entityId: created.id,
        operation: SyncOperation.create,
        payload: any(named: 'payload'),
      ),
    ).called(1);
  });

  test('deleteStandard does not block local delete when queue fails', () async {
    final dao = _MockQualificationStandardDao();
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

    final notifier = QualificationStandardsNotifier(
      dao,
      'profile-1',
      syncQueueDao: queue,
      onQueueFailure: (error) => reportedError = error,
    );
    await Future<void>.delayed(Duration.zero);

    await notifier.deleteStandard('standard-1');

    verify(() => dao.delete('standard-1', 'profile-1')).called(1);
    expect(reportedError, isA<Exception>());
  });

  test('importVictorianMetroSc2026 replaces the imported source', () async {
    final dao = _MockMeetQualificationStandardDao();
    when(() => dao.getAll()).thenAnswer((_) async => []);
    when(() => dao.replaceSource(any(), any())).thenAnswer((_) async {});

    final notifier = MeetQualificationStandardsNotifier(dao);
    await Future<void>.delayed(Duration.zero);

    final count = await notifier.importVictorianMetroSc2026();

    expect(count, 92);
    final captured = verify(
      () => dao.replaceSource(victorianMetroSc2026SourceName, captureAny()),
    ).captured.single as List<MeetQualificationStandard>;
    expect(captured, hasLength(92));
    verify(() => dao.getAll()).called(2);
  });
}

QualificationStandard _standard() {
  return QualificationStandard(
    id: 'standard-1',
    profileId: 'profile-1',
    age: 12,
    distance: 50,
    stroke: 'Freestyle',
    course: RaceCourse.shortCourseMeters,
    goldTime: const Duration(seconds: 30),
    silverTime: const Duration(seconds: 32),
    bronzeTime: const Duration(seconds: 35),
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}
