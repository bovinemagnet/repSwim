import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/swim/domain/repositories/swim_repository.dart';
import 'package:rep_swim/features/swim/presentation/providers/swim_providers.dart';
import 'package:rep_swim/features/swim/presentation/screens/swim_sessions_screen.dart';

class _FakeSwimRepository implements SwimRepository {
  const _FakeSwimRepository();

  @override
  Future<void> deleteSession(String id, String profileId) async {}

  @override
  Future<List<SwimSession>> getAllSessions(String profileId) async => [];

  @override
  Future<List<SwimSession>> getRecentSessions(
    String profileId, {
    int limit = 10,
  }) async =>
      [];

  @override
  Future<void> saveSession(SwimSession session) async {}
}

class _StaticSwimSessionsNotifier extends SwimSessionsNotifier {
  _StaticSwimSessionsNotifier(List<SwimSession> sessions)
      : super(const _FakeSwimRepository(), 'profile-1') {
    state = AsyncValue.data(sessions);
  }

  @override
  Future<void> load() async {}
}

SwimSession _session({
  required String id,
  required String stroke,
  required int distance,
  required String notes,
}) {
  return SwimSession(
    id: id,
    profileId: 'profile-1',
    date: DateTime.utc(2024, 1, id == 'session-1' ? 2 : 3),
    totalDistance: distance,
    totalTime: const Duration(seconds: 90),
    stroke: stroke,
    notes: notes,
    laps: const [],
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<SwimSession> sessions,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        swimSessionsProvider.overrideWith(
          (ref) => _StaticSwimSessionsNotifier(sessions),
        ),
      ],
      child: const MaterialApp(
        home: SwimSessionsScreen(),
      ),
    ),
  );
}

void main() {
  group('session history helpers', () {
    test('filters sessions by stroke, notes, and date range', () {
      final sessions = [
        _session(
          id: 'session-1',
          stroke: 'Freestyle',
          distance: 100,
          notes: 'Threshold set',
        ),
        _session(
          id: 'session-2',
          stroke: 'Backstroke',
          distance: 200,
          notes: 'Recovery',
        ),
      ];

      final filtered = filterSessions(
        sessions,
        query: 'threshold',
        stroke: 'Freestyle',
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 2),
        ),
      );

      expect(filtered.single.id, 'session-1');
    });

    test('exports CSV with escaped notes', () {
      final csv = sessionsToCsv([
        _session(
          id: 'session-1',
          stroke: 'Freestyle',
          distance: 100,
          notes: 'Fast, "clean" turns',
        ),
      ]);

      expect(csv, contains('"Fast, ""clean"" turns"'));
      expect(csv, startsWith('date,stroke,total_distance_meters'));
    });
  });

  group('SwimSessionsScreen', () {
    testWidgets('filters mobile list from the search field', (tester) async {
      await _pumpScreen(tester, [
        _session(
          id: 'session-1',
          stroke: 'Freestyle',
          distance: 100,
          notes: 'Threshold set',
        ),
        _session(
          id: 'session-2',
          stroke: 'Backstroke',
          distance: 200,
          notes: 'Recovery',
        ),
      ]);

      expect(find.text('100m Freestyle'), findsOneWidget);
      expect(find.text('200m Backstroke'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'threshold');
      await tester.pump();

      expect(find.text('100m Freestyle'), findsOneWidget);
      expect(find.text('200m Backstroke'), findsNothing);
    });

    testWidgets('uses a table layout on wide screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpScreen(tester, [
        _session(
          id: 'session-1',
          stroke: 'Freestyle',
          distance: 100,
          notes: 'Threshold set',
        ),
      ]);

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Threshold set'), findsOneWidget);
    });
  });
}
