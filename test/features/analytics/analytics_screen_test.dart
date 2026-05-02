import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:rep_swim/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:rep_swim/features/pb/domain/entities/personal_best.dart';

AnalyticsData _analyticsData() {
  return AnalyticsData(
    totalSessions: 4,
    totalDistanceMeters: 2600,
    weeklyDistances: const [0, 400, 0, 800, 0, 600, 800],
    averagePacePerHundred: const Duration(seconds: 95),
    consistencyScore: 100,
    paceTrend: [
      PaceTrendPoint(
        date: DateTime(2024, 5, 1),
        pacePerHundred: const Duration(seconds: 100),
      ),
      PaceTrendPoint(
        date: DateTime(2024, 5, 2),
        pacePerHundred: const Duration(seconds: 95),
      ),
    ],
    pbHighlights: [
      PersonalBest(
        id: 'pb-1',
        stroke: 'Freestyle',
        distance: 100,
        bestTime: const Duration(seconds: 62),
        achievedAt: DateTime(2024, 5, 2),
      ),
    ],
  );
}

Future<void> _pumpAnalytics(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analyticsProvider.overrideWithValue(_analyticsData()),
      ],
      child: const MaterialApp(home: AnalyticsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  group('AnalyticsScreen', () {
    testWidgets('renders summary stats, charts, and PB highlights',
        (tester) async {
      await _pumpAnalytics(tester);

      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Total Distance'), findsOneWidget);
      expect(find.text('2.6km'), findsOneWidget);
      expect(find.text('Avg Pace'), findsOneWidget);
      expect(find.text('1:35'), findsWidgets);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Pace Trend'), findsOneWidget);
      expect(find.text('PB Highlights'), findsOneWidget);
      expect(find.text('Freestyle 100m'), findsOneWidget);
    });

    testWidgets('uses four-column stats on desktop widths', (tester) async {
      await _pumpAnalytics(tester, size: const Size(1200, 800));

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 4);
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Pace Trend'), findsOneWidget);
    });

    testWidgets('does not overflow stats at the desktop breakpoint',
        (tester) async {
      await _pumpAnalytics(tester, size: const Size(1000, 800));

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 4);
      expect(find.text('Consistency'), findsOneWidget);
    });
  });
}
