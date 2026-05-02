import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/core/sync/sync_mode.dart';
import 'package:rep_swim/core/sync/sync_providers.dart';
import 'package:rep_swim/database/daos/sync_queue_dao.dart';
import 'package:rep_swim/database/daos/training_template_dao.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';
import 'package:rep_swim/features/templates/presentation/providers/training_template_providers.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_mode.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_session_result.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_template.dart';
import 'package:rep_swim/features/tempo/presentation/providers/tempo_cue_player.dart';
import 'package:rep_swim/features/tempo/presentation/screens/tempo_trainer_screen.dart';

class _MockTrainingTemplateDao extends Mock implements TrainingTemplateDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

class _FakeTempoCuePlayer implements TempoCuePlayer {
  int playCount = 0;

  @override
  Future<void> playCue({
    required TempoCueSettings settings,
    required bool accent,
  }) async {
    playCount++;
  }
}

class _TempoScreenHarness {
  const _TempoScreenHarness({
    required this.dao,
    required this.queue,
    required this.cuePlayer,
  });

  final _MockTrainingTemplateDao dao;
  final _MockSyncQueueDao queue;
  final _FakeTempoCuePlayer cuePlayer;
}

Future<_TempoScreenHarness> _pumpTempoTrainer(WidgetTester tester) async {
  final dao = _MockTrainingTemplateDao();
  final queue = _MockSyncQueueDao();
  final cuePlayer = _FakeTempoCuePlayer();
  when(() => dao.getTempoTemplates(any())).thenAnswer((_) async => []);
  when(() => dao.getTempoSessionResults(any())).thenAnswer((_) async => []);
  when(() => dao.insertTempoTemplate(any())).thenAnswer((_) async {});
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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trainingTemplateDaoProvider.overrideWithValue(dao),
        syncQueueDaoProvider.overrideWithValue(queue),
        currentProfileIdProvider.overrideWithValue('profile-1'),
        tempoCuePlayerProvider.overrideWithValue(cuePlayer),
      ],
      child: const MaterialApp(home: TempoTrainerScreen()),
    ),
  );
  await tester.pump();
  return _TempoScreenHarness(
    dao: dao,
    queue: queue,
    cuePlayer: cuePlayer,
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TempoTemplate(
        id: 'template-1',
        name: 'Race pace',
        mode: TempoMode.strokeRate,
        poolLengthMeters: 25,
        targetDistanceMeters: 100,
        targetTime: const Duration(seconds: 90),
        strokeRate: 60,
        breathEveryStrokes: 3,
        cueSettings: const TempoCueSettings(),
        safetyWarningAcknowledged: false,
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      ),
    );
    registerFallbackValue(
      TempoSessionResult(
        id: 'result-1',
        mode: TempoMode.strokeRate,
        startedAt: DateTime.utc(2024),
        targetDistanceMeters: 100,
        poolLengthMeters: 25,
        targetTime: const Duration(seconds: 90),
        targetStrokeRate: 60,
        actualSplits: const [Duration(seconds: 22)],
        strokeCounts: const [18],
      ),
    );
    registerFallbackValue(SyncOperation.create);
    registerFallbackValue(<String, Object?>{});
  });

  group('TempoTrainerScreen', () {
    testWidgets('shows tempo controls and cue outputs', (tester) async {
      final harness = await _pumpTempoTrainer(tester);

      expect(find.text('Tempo Trainer'), findsOneWidget);
      expect(find.text('Stroke Rate'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);
      expect(find.text('Visual flash'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start'));
      await tester.pump();

      expect(harness.cuePlayer.playCount, 1);
      expect(find.text('Stroke cue'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('requires acknowledgement for high breath rhythm cues',
        (tester) async {
      await _pumpTempoTrainer(tester);

      await tester.tap(find.text('Breath Pattern'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Breathe every'),
        '5',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pump();

      expect(find.text('Breath safety acknowledged'), findsOneWidget);
      final startButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start'),
      );
      expect(startButton.onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      final enabledStart = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start'),
      );
      expect(enabledStart.onPressed, isNotNull);
    });

    testWidgets('validates configuration before applying', (tester) async {
      await _pumpTempoTrainer(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Pool m'), '0');
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pump();

      expect(find.text('Enter valid tempo values.'), findsOneWidget);
    });

    testWidgets('saves the current setup as a tempo template', (tester) async {
      final harness = await _pumpTempoTrainer(tester);

      await _scrollTo(tester, find.widgetWithText(FilledButton, 'Save'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Template name'),
        'Threshold tempo',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Save'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => harness.dao.insertTempoTemplate(any())).called(1);
      expect(find.text('Saved Threshold tempo.'), findsOneWidget);
    });

    testWidgets('saves a tempo result with actual splits', (tester) async {
      final harness = await _pumpTempoTrainer(tester);

      await _scrollTo(
        tester,
        find.widgetWithText(TextField, 'Actual splits sec'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Actual splits sec'),
        '22.0, 22.4',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stroke counts'),
        '18, 19',
      );
      await tester.enterText(find.widgetWithText(TextField, 'RPE 1-10'), '7');
      await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'Held');
      await tester.tap(find.widgetWithText(FilledButton, 'Save Result'));
      await tester.pumpAndSettle();

      verify(() => harness.dao.insertTempoSessionResult(any())).called(1);
      expect(find.text('Saved tempo result with 2 splits.'), findsOneWidget);
    });

    testWidgets('copies tempo result CSV from entered splits', (tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });
      await _pumpTempoTrainer(tester);

      await _scrollTo(
        tester,
        find.widgetWithText(TextField, 'Actual splits sec'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Actual splits sec'),
        '22.0, 22.5',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Stroke counts'),
        '18, 19',
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'CSV'));
      await tester.pumpAndSettle();

      expect(copiedText, contains('session_id,mode,split_index'));
      expect(copiedText, contains('preview,strokeRate,1,22500,22000,-500,18'));
      expect(find.text('Copied tempo CSV.'), findsOneWidget);
    });
  });
}
