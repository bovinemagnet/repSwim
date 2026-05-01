import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/profiles/domain/entities/swimmer_profile.dart';
import 'package:rep_swim/features/profiles/presentation/providers/profile_providers.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/swim/domain/repositories/swim_repository.dart';
import 'package:rep_swim/features/swim/presentation/providers/swim_providers.dart';
import 'package:rep_swim/features/swim/presentation/screens/swim_session_screen.dart';

class _FakeSwimRepository implements SwimRepository {
  const _FakeSwimRepository(this.sessions);

  final List<SwimSession> sessions;

  @override
  Future<void> deleteSession(String id, String profileId) async {}

  @override
  Future<List<SwimSession>> getAllSessions(String profileId) async =>
      sessions.where((session) => session.profileId == profileId).toList();

  @override
  Future<List<SwimSession>> getRecentSessions(
    String profileId, {
    int limit = 10,
  }) async =>
      sessions
          .where((session) => session.profileId == profileId)
          .take(limit)
          .toList();

  @override
  Future<void> saveSession(SwimSession session) async {}
}

class _StaticSwimSessionsNotifier extends SwimSessionsNotifier {
  _StaticSwimSessionsNotifier(List<SwimSession> sessions)
      : super(_FakeSwimRepository(sessions), 'profile-1') {
    state = AsyncValue.data(sessions);
  }

  @override
  Future<void> load() async {}
}

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

SwimSession _existingSession() {
  return SwimSession(
    id: 'session-1',
    profileId: 'profile-1',
    date: DateTime(2024, 5, 1, 7, 30),
    totalDistance: 100,
    totalTime: const Duration(seconds: 90),
    stroke: 'Backstroke',
    notes: 'Technique focus',
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

    testWidgets('distance-only lap cannot save', (tester) async {
      await _pumpSwimSession(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add Lap'));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pump();

      expect(find.text('Enter time'), findsOneWidget);
    });

    testWidgets('editor screen preloads an existing session', (tester) async {
      final session = _existingSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            swimSessionsProvider.overrideWith(
              (ref) => _StaticSwimSessionsNotifier([session]),
            ),
          ],
          child: const MaterialApp(
            home: SwimSessionEditorScreen(sessionId: 'session-1'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Edit Swim Session'), findsOneWidget);
      expect(find.text('Technique focus'), findsOneWidget);
      expect(find.text('100m'), findsOneWidget);
      expect(find.text('1:30'), findsWidgets);

      final distanceField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Distance (m)'),
      );
      final minuteField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Min'),
      );
      final secondField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Sec'),
      );
      expect(distanceField.controller?.text, '100');
      expect(minuteField.controller?.text, '1');
      expect(secondField.controller?.text, '30');
    });

    testWidgets('editor screen reports a missing session', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            swimSessionsProvider.overrideWith(
              (ref) => _StaticSwimSessionsNotifier([_existingSession()]),
            ),
          ],
          child: const MaterialApp(
            home: SwimSessionEditorScreen(sessionId: 'missing'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Session not found'), findsOneWidget);
    });
  });
}
