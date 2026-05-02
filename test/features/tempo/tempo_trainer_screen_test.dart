import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rep_swim/database/daos/training_template_dao.dart';
import 'package:rep_swim/features/templates/presentation/providers/training_template_providers.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_mode.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_session_result.dart';
import 'package:rep_swim/features/tempo/domain/entities/tempo_template.dart';
import 'package:rep_swim/features/tempo/presentation/providers/tempo_cue_player.dart';
import 'package:rep_swim/features/tempo/presentation/screens/tempo_trainer_screen.dart';

class _MockTrainingTemplateDao extends Mock implements TrainingTemplateDao {}

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

Future<_FakeTempoCuePlayer> _pumpTempoTrainer(WidgetTester tester) async {
  final dao = _MockTrainingTemplateDao();
  when(() => dao.getTempoTemplates(any())).thenAnswer((_) async => []);
  when(() => dao.getTempoSessionResults(any())).thenAnswer((_) async => []);
  when(() => dao.insertTempoSessionResult(any())).thenAnswer((_) async {});
  final cuePlayer = _FakeTempoCuePlayer();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trainingTemplateDaoProvider.overrideWithValue(dao),
        tempoCuePlayerProvider.overrideWithValue(cuePlayer),
      ],
      child: const MaterialApp(home: TempoTrainerScreen()),
    ),
  );
  await tester.pump();
  return cuePlayer;
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
  });

  group('TempoTrainerScreen', () {
    testWidgets('shows tempo controls and cue outputs', (tester) async {
      final cuePlayer = await _pumpTempoTrainer(tester);

      expect(find.text('Tempo Trainer'), findsOneWidget);
      expect(find.text('Stroke Rate'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);
      expect(find.text('Visual flash'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start'));
      await tester.pump();

      expect(cuePlayer.playCount, 1);
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
  });
}
