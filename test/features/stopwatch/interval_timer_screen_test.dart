import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/stopwatch/presentation/screens/interval_timer_screen.dart';

Future<void> _pumpIntervalTimer(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: IntervalTimerScreen(),
      ),
    ),
  );
}

void main() {
  group('IntervalTimerScreen', () {
    testWidgets('shows default workout configuration', (tester) async {
      await _pumpIntervalTimer(tester);

      expect(find.text('Interval Timer'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('0:45'), findsOneWidget);
      expect(find.text('Set 1/3  Rep 1/4'), findsOneWidget);
    });

    testWidgets('applies custom interval values and starts timer',
        (tester) async {
      await _pumpIntervalTimer(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Sets'), '1');
      await tester.enterText(find.widgetWithText(TextField, 'Reps'), '2');
      await tester.enterText(find.widgetWithText(TextField, 'Swim sec'), '3');
      await tester.enterText(find.widgetWithText(TextField, 'Rest sec'), '1');
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pump();

      expect(find.text('0:03'), findsOneWidget);
      expect(find.text('Set 1/1  Rep 1/2'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Start'));
      await tester.pump();

      expect(find.text('Swim'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
    });
  });
}
