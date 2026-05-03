import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:rep_swim/features/tempo/presentation/screens/tempo_results_screen.dart';

class _MockTrainingTemplateDao extends Mock implements TrainingTemplateDao {}

class _MockSyncQueueDao extends Mock implements SyncQueueDao {}

TempoSessionResult _tempoResult() {
  return TempoSessionResult(
    id: 'result-1',
    profileId: 'profile-1',
    mode: TempoMode.lapPace,
    startedAt: DateTime(2024, 5, 1, 7, 30),
    completedAt: DateTime(2024, 5, 1, 7, 35),
    targetDistanceMeters: 100,
    poolLengthMeters: 25,
    targetTime: const Duration(seconds: 90),
    targetStrokeRate: 72,
    actualSplits: const [
      Duration(seconds: 22),
      Duration(milliseconds: 23700),
    ],
    strokeCounts: const [18, 20],
    rpe: 7,
    notes: 'Held rhythm',
  );
}

Future<_MockTrainingTemplateDao> _pumpResultsApp(
  WidgetTester tester, {
  required List<TempoSessionResult> results,
  String initialLocation = '/tempo/results',
}) async {
  final dao = _MockTrainingTemplateDao();
  final queue = _MockSyncQueueDao();
  when(() => dao.getTempoSessionResults(any()))
      .thenAnswer((_) async => results);
  when(() => dao.deleteTempoSessionResult(any(), any()))
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

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/tempo/results',
        builder: (context, state) => const TempoResultsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => TempoResultDetailScreen(
              resultId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trainingTemplateDaoProvider.overrideWithValue(dao),
        syncQueueDaoProvider.overrideWithValue(queue),
        currentProfileIdProvider.overrideWithValue('profile-1'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return dao;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      TempoSessionResult(
        id: 'fallback-result',
        mode: TempoMode.strokeRate,
        startedAt: DateTime(2024),
        targetDistanceMeters: 100,
        poolLengthMeters: 25,
        targetTime: const Duration(seconds: 90),
        targetStrokeRate: 60,
        actualSplits: const [Duration(seconds: 22)],
        strokeCounts: const [18],
      ),
    );
    registerFallbackValue(
      TempoTemplate(
        id: 'fallback-template',
        name: 'Template',
        mode: TempoMode.strokeRate,
        poolLengthMeters: 25,
        targetDistanceMeters: 100,
        targetTime: const Duration(seconds: 90),
        strokeRate: 60,
        breathEveryStrokes: 3,
        cueSettings: const TempoCueSettings(),
        safetyWarningAcknowledged: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
    registerFallbackValue(SyncOperation.create);
    registerFallbackValue(<String, Object?>{});
  });

  group('TempoResultsScreen', () {
    testWidgets('shows empty state when no tempo results exist',
        (tester) async {
      await _pumpResultsApp(tester, results: const []);

      expect(find.text('Tempo History'), findsOneWidget);
      expect(find.text('No tempo sessions yet'), findsOneWidget);
    });

    testWidgets('lists saved tempo results and opens detail', (tester) async {
      await _pumpResultsApp(tester, results: [_tempoResult()]);

      expect(find.text('Lap Pace - 100m'), findsOneWidget);
      expect(find.textContaining('2 splits'), findsOneWidget);
      expect(find.textContaining('1:30/100m'), findsOneWidget);
      expect(find.textContaining('RPE 7'), findsOneWidget);

      await tester.tap(find.text('Lap Pace - 100m'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tempo Result'), findsOneWidget);
      expect(find.text('Lap Pace'), findsWidgets);
      expect(find.text('100m'), findsOneWidget);
      expect(find.text('25m pool'), findsOneWidget);
      expect(find.text('72.0 spm'), findsOneWidget);
      expect(find.text('Held rhythm'), findsOneWidget);
      expect(find.textContaining('Error -00:00.50'), findsOneWidget);
      expect(find.textContaining('Strokes 18'), findsOneWidget);
      expect(find.text('On pace'), findsOneWidget);
      expect(find.text('Off pace'), findsOneWidget);
    });

    testWidgets('shows not found state for missing result', (tester) async {
      await _pumpResultsApp(
        tester,
        results: [_tempoResult()],
        initialLocation: '/tempo/results/missing',
      );

      expect(find.text('Tempo result not found'), findsOneWidget);
    });

    testWidgets('deletes a saved tempo result after confirmation',
        (tester) async {
      final dao = await _pumpResultsApp(tester, results: [_tempoResult()]);

      await tester.tap(find.text('Lap Pace - 100m'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Delete tempo result'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Delete tempo result?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => dao.deleteTempoSessionResult('result-1', 'profile-1'))
          .called(1);
      expect(find.text('Tempo result deleted.'), findsOneWidget);
      expect(find.text('Tempo History'), findsOneWidget);
    });
  });
}
