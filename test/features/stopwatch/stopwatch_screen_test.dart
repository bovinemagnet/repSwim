import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/stopwatch/presentation/screens/stopwatch_screen.dart';

Future<void> _pumpStopwatch(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: StopwatchScreen(),
      ),
    ),
  );
}

void main() {
  group('StopwatchScreen', () {
    testWidgets('records a manual lap split', (tester) async {
      await _pumpStopwatch(tester);

      expect(find.text('00:00.00'), findsOneWidget);
      expect(
          find.text('Press Start, then Lap to record splits'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('Pause'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pump();

      expect(find.text('Laps'), findsOneWidget);
      expect(find.text('1 laps'), findsOneWidget);
      expect(find.textContaining('Split:'), findsOneWidget);
    });

    testWidgets('opens save dialog after stopwatch has elapsed',
        (tester) async {
      await _pumpStopwatch(tester);

      final saveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byIcon(Icons.save_outlined));
      await tester.pump();

      expect(find.text('Save Swim Session'), findsOneWidget);
      expect(find.text('Stroke'), findsOneWidget);
      expect(find.text('Distance per lap (m)'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
    });
  });
}
