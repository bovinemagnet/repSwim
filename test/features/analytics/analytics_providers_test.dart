import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:rep_swim/features/pb/domain/entities/personal_best.dart';
import 'package:rep_swim/features/swim/domain/entities/swim_session.dart';

SwimSession _session({
  required String id,
  required DateTime date,
  required int distance,
  required Duration time,
}) {
  return SwimSession(
    id: id,
    date: date,
    totalDistance: distance,
    totalTime: time,
    stroke: 'Freestyle',
    laps: const [],
  );
}

PersonalBest _pb({
  required String id,
  required DateTime achievedAt,
}) {
  return PersonalBest(
    id: id,
    stroke: 'Freestyle',
    distance: 100,
    bestTime: const Duration(seconds: 60),
    achievedAt: achievedAt,
  );
}

void main() {
  group('computeAnalytics', () {
    test('aggregates weekly distance, average pace, and consistency', () {
      final now = DateTime.now();
      final analytics = computeAnalytics(
        [
          _session(
            id: 'today',
            date: now,
            distance: 100,
            time: const Duration(seconds: 90),
          ),
          _session(
            id: 'yesterday',
            date: now.subtract(const Duration(days: 1)),
            distance: 200,
            time: const Duration(minutes: 4),
          ),
          _session(
            id: 'old',
            date: now.subtract(const Duration(days: 9)),
            distance: 300,
            time: const Duration(minutes: 6),
          ),
        ],
        const [],
      );

      expect(analytics.totalSessions, 3);
      expect(analytics.totalDistanceMeters, 600);
      expect(analytics.weeklyDistances[5], 200);
      expect(analytics.weeklyDistances[6], 100);
      expect(analytics.averagePacePerHundred.inSeconds, 115);
      expect(analytics.consistencyScore, 67);
      expect(analytics.paceTrend, hasLength(3));
    });

    test('returns most recent PB highlights', () {
      final now = DateTime.now();
      final analytics = computeAnalytics(
        const [],
        [
          _pb(id: 'old', achievedAt: now.subtract(const Duration(days: 7))),
          _pb(id: 'new', achievedAt: now),
          _pb(id: 'middle', achievedAt: now.subtract(const Duration(days: 2))),
          _pb(id: 'older', achievedAt: now.subtract(const Duration(days: 10))),
        ],
      );

      expect(analytics.pbHighlights.map((pb) => pb.id), [
        'new',
        'middle',
        'old',
      ]);
    });
  });
}
