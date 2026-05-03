import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/database/daos/training_template_dao.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_mode.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_session_result.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_template.dart';
import 'package:rep_swim/features/tempo/domain/services/usrpt_calculator.dart';
import 'package:rep_swim/features/tempo/presentation/providers/tempo_template_providers.dart';
import 'package:rep_swim/features/tempo/presentation/providers/tempo_trainer_provider.dart';

class _MockTrainingTemplateDao extends Mock implements TrainingTemplateDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

TempoTemplate _tempoTemplate() {
  return TempoTemplate(
    id: 'tempo-template-1',
    profileId: 'profile-1',
    name: 'Tempo 50s',
    mode: TempoMode.strokeRate,
    poolLengthMeters: 25,
    targetDistanceMeters: 100,
    targetTime: const Duration(seconds: 88),
    strokeRate: 72,
    breathEveryStrokes: 3,
    cueSettings: const TempoCueSettings(vibration: true),
    safetyWarningAcknowledged: false,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

TempoSessionResult _tempoResult() {
  return TempoSessionResult(
    id: 'tempo-result-1',
    profileId: 'profile-1',
    mode: TempoMode.lapPace,
    startedAt: DateTime.utc(2024),
    targetDistanceMeters: 100,
    poolLengthMeters: 25,
    targetTime: const Duration(seconds: 88),
    targetStrokeRate: 72,
    actualSplits: const [Duration(seconds: 22)],
    strokeCounts: const [18],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_tempoTemplate());
    registerFallbackValue(_tempoResult());
    registerFallbackValue(SyncOperation.create);
    registerFallbackValue(<String, Object?>{});
  });

  group('TempoTemplatesNotifier', () {
    test('saves trainer state as a reusable template and queues sync',
        () async {
      final dao = _MockTrainingTemplateDao();
      final queue = _MockSyncQueueDao();
      when(() => dao.getTempoTemplates(any()))
          .thenAnswer((_) async => [_tempoTemplate()]);
      when(() => dao.insertTempoTemplate(any())).thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = TempoTemplatesNotifier(
        dao,
        'profile-1',
        syncQueueDao: queue,
      );
      await Future<void>.delayed(Duration.zero);

      final saved = await notifier.saveFromState(
        '  CSS tempo  ',
        const TempoTrainerState(
          mode: TempoMode.lapPace,
          poolLengthMeters: 25,
          targetDistanceMeters: 100,
          targetTime: Duration(seconds: 88),
          strokeRate: 72,
          cueSettings: TempoCueSettings(vibration: true),
        ),
      );

      expect(saved.name, 'CSS tempo');
      expect(saved.mode, TempoMode.lapPace);
      expect(saved.cueSettings.vibration, isTrue);
      verify(() => dao.insertTempoTemplate(any())).called(1);
      verify(
        () => queue.enqueue(
          profileId: 'profile-1',
          entityType: 'tempo_template',
          entityId: saved.id,
          operation: SyncOperation.create,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(() => dao.getTempoTemplates('profile-1'))
          .called(greaterThanOrEqualTo(2));
    });

    test('deletes templates by profile and queues deletion', () async {
      final dao = _MockTrainingTemplateDao();
      final queue = _MockSyncQueueDao();
      when(() => dao.getTempoTemplates(any())).thenAnswer((_) async => []);
      when(() => dao.deleteTempoTemplate(any(), any()))
          .thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = TempoTemplatesNotifier(
        dao,
        'profile-1',
        syncQueueDao: queue,
      );
      await Future<void>.delayed(Duration.zero);

      await notifier.deleteTemplate('tempo-template-1');

      verify(() => dao.deleteTempoTemplate('tempo-template-1', 'profile-1'))
          .called(1);
      verify(
        () => queue.enqueue(
          profileId: 'profile-1',
          entityType: 'tempo_template',
          entityId: 'tempo-template-1',
          operation: SyncOperation.delete,
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('TempoSessionResultsNotifier', () {
    test('saves session result with splits, notes, and sync payload', () async {
      final dao = _MockTrainingTemplateDao();
      final queue = _MockSyncQueueDao();
      when(() => dao.getTempoSessionResults(any()))
          .thenAnswer((_) async => [_tempoResult()]);
      when(() => dao.insertTempoSessionResult(any())).thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = TempoSessionResultsNotifier(
        dao,
        'profile-1',
        syncQueueDao: queue,
      );
      await Future<void>.delayed(Duration.zero);

      final saved = await notifier.saveResult(
        trainer: const TempoTrainerState(
          mode: TempoMode.lapPace,
          poolLengthMeters: 25,
          targetDistanceMeters: 100,
          targetTime: Duration(seconds: 88),
          strokeRate: 72,
        ),
        actualSplits: const [
          Duration(milliseconds: 22000),
          Duration(milliseconds: 22400),
        ],
        strokeCounts: const [18, 19],
        rpe: 7,
        notes: ' Held rhythm ',
      );

      expect(saved.notes, 'Held rhythm');
      expect(saved.actualSplits, hasLength(2));
      expect(saved.strokeCounts, [18, 19]);
      verify(() => dao.insertTempoSessionResult(any())).called(1);
      verify(
        () => queue.enqueue(
          profileId: 'profile-1',
          entityType: 'tempo_session_result',
          entityId: saved.id,
          operation: SyncOperation.create,
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('saves USRPT result with pass fail outcomes and sync payload',
        () async {
      final dao = _MockTrainingTemplateDao();
      final queue = _MockSyncQueueDao();
      when(() => dao.getTempoSessionResults(any()))
          .thenAnswer((_) async => [_tempoResult()]);
      when(() => dao.insertTempoSessionResult(any())).thenAnswer((_) async {});
      when(
        () => queue.enqueue(
          profileId: any(named: 'profileId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          operation: any(named: 'operation'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final notifier = TempoSessionResultsNotifier(
        dao,
        'profile-1',
        syncQueueDao: queue,
      );
      await Future<void>.delayed(Duration.zero);

      final preset = const UsrptRacePaceCalculator().calculate(
        eventDistanceMeters: 100,
        eventTargetTime: const Duration(seconds: 60),
        repetitionDistanceMeters: 25,
        restDuration: const Duration(seconds: 20),
        failLimit: 2,
      );
      final saved = await notifier.saveUsrptResult(
        preset: preset,
        outcomes: const [
          UsrptRepOutcome(index: 1, passed: true),
          UsrptRepOutcome(index: 2, passed: false),
        ],
        notes: 'Faded late',
      );

      expect(saved.mode, TempoMode.lapPace);
      expect(saved.targetDistanceMeters, 25);
      expect(saved.targetTime, const Duration(seconds: 15));
      expect(saved.strokeCounts, [1, 0]);
      expect(saved.notes, contains('outcomes 1:P,2:F'));
      expect(saved.notes, contains('Faded late'));
      expect(saved.metadata['type'], 'usrpt');
      verify(() => dao.insertTempoSessionResult(any())).called(1);
      verify(
        () => queue.enqueue(
          profileId: 'profile-1',
          entityType: 'tempo_session_result',
          entityId: saved.id,
          operation: SyncOperation.create,
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });
}
