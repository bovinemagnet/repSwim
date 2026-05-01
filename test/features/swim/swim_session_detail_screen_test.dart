import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/swim/domain/entities/lap.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';
import 'package:rep_swim/features/swim/domain/repositories/swim_repository.dart';
import 'package:rep_swim/features/swim/presentation/providers/swim_providers.dart';
import 'package:rep_swim/features/swim/presentation/screens/swim_session_detail_screen.dart';

class _FakeSwimRepository implements SwimRepository {
  _FakeSwimRepository(this.sessions);

  final List<SwimSession> sessions;

  @override
  Future<void> deleteSession(String id, String profileId) async {
    sessions.removeWhere(
      (session) => session.id == id && session.profileId == profileId,
    );
  }

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
  Future<void> saveSession(SwimSession session) async {
    sessions.add(session);
  }
}

SwimSession _session() {
  return SwimSession(
    id: 'session-1',
    date: DateTime(2024, 5, 1, 7, 30),
    totalDistance: 150,
    totalTime: const Duration(minutes: 2, seconds: 15),
    stroke: 'Freestyle',
    notes: 'Main set felt smooth.',
    laps: const [
      Lap(
        id: 'lap-1',
        sessionId: 'session-1',
        distance: 50,
        time: Duration(seconds: 40),
        lapNumber: 1,
      ),
      Lap(
        id: 'lap-2',
        sessionId: 'session-1',
        distance: 100,
        time: Duration(seconds: 95),
        lapNumber: 2,
      ),
    ],
  );
}

Future<void> _pumpDetail(WidgetTester tester, SwimSession session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        swimSessionsProvider.overrideWith(
          (ref) => SwimSessionsNotifier(
            _FakeSwimRepository([session]),
            session.profileId,
          ),
        ),
      ],
      child: MaterialApp(
        home: SwimSessionDetailScreen(sessionId: session.id),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('SwimSessionDetailScreen', () {
    testWidgets('renders session summary, notes, and laps', (tester) async {
      await _pumpDetail(tester, _session());

      expect(find.text('Session Details'), findsOneWidget);
      expect(find.text('Freestyle'), findsOneWidget);
      expect(find.text('150m'), findsOneWidget);
      expect(find.text('2:15'), findsOneWidget);
      expect(find.text('1:30/100m'), findsOneWidget);
      expect(find.text('2 laps'), findsOneWidget);
      expect(find.text('Main set felt smooth.'), findsOneWidget);
      expect(find.text('50m'), findsOneWidget);
      expect(find.text('100m'), findsOneWidget);
    });

    testWidgets('shows not found state for missing session', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            swimSessionsProvider.overrideWith(
              (ref) => SwimSessionsNotifier(
                _FakeSwimRepository([_session()]),
                'local-default-profile',
              ),
            ),
          ],
          child: const MaterialApp(
            home: SwimSessionDetailScreen(sessionId: 'missing'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Session not found'), findsOneWidget);
    });
  });
}
