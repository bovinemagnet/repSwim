import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';
import 'package:rep_swim/features/swim/presentation/screens/swim_session_screen.dart';

Future<void> _pumpSwimSession(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: SwimSessionScreen(),
      ),
    ),
  );
}

void main() {
  group('SwimSessionScreen', () {
    testWidgets('requires at least one lap before saving', (tester) async {
      await _pumpSwimSession(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pump();

      expect(find.text('Add at least one lap.'), findsOneWidget);
    });

    testWidgets('updates totals when lap fields change', (tester) async {
      await _pumpSwimSession(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add Lap'));
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Distance (m)'), '100');
      await tester.enterText(find.widgetWithText(TextFormField, 'Min'), '1');
      await tester.enterText(find.widgetWithText(TextFormField, 'Sec'), '30');
      await tester.pump();

      expect(find.text('100m'), findsOneWidget);
      expect(find.text('1:30'), findsOneWidget);
      expect(find.text('1:30/100m'), findsOneWidget);
    });

    testWidgets('prefills new lap distance from current profile pool length',
        (tester) async {
      await _pumpSwimSession(
        tester,
        overrides: [
          currentProfileProvider.overrideWithValue(
            SwimmerProfile(
              id: 'profile-1',
              displayName: 'Sophie',
              preferredPoolLengthMeters: 50,
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
            ),
          ),
        ],
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add Lap'));
      await tester.pump();

      final distanceField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Distance (m)'),
      );
      expect(distanceField.controller?.text, '50');
    });
  });
}
