import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../swim/presentation/providers/swim_providers.dart';
import '../../../swim/domain/entities/swim_session.dart';

/// Aggregated analytics data derived from all swim sessions.
class AnalyticsData {
  const AnalyticsData({
    required this.totalSessions,
    required this.totalDistanceMeters,
    required this.weeklyDistances,
    required this.averagePacePerHundred,
  });

  final int totalSessions;
  final int totalDistanceMeters;

  /// Distance in metres for each of the last 7 days (index 0 = oldest).
  final List<int> weeklyDistances;

  final Duration averagePacePerHundred;

  static const empty = AnalyticsData(
    totalSessions: 0,
    totalDistanceMeters: 0,
    weeklyDistances: [0, 0, 0, 0, 0, 0, 0],
    averagePacePerHundred: Duration.zero,
  );
}

AnalyticsData _compute(List<SwimSession> sessions) {
  if (sessions.isEmpty) return AnalyticsData.empty;

  final totalDist = sessions.fold<int>(0, (s, e) => s + e.totalDistance);

  // Build weekly buckets (last 7 days including today).
  final today = DateTime.now();
  final weeklyDist = List<int>.filled(7, 0);
  for (final s in sessions) {
    final diff = today.difference(s.date).inDays;
    if (diff >= 0 && diff < 7) {
      // day 0 = today (index 6), day 6 = 6 days ago (index 0)
      weeklyDist[6 - diff] += s.totalDistance;
    }
  }

  // Average pace: total time / total distance * 100m.
  final totalSeconds =
      sessions.fold<int>(0, (s, e) => s + e.totalTime.inSeconds);
  final avgPace = totalDist > 0
      ? Duration(
          milliseconds:
              (totalSeconds * 1000 * 100 / totalDist).round(),
        )
      : Duration.zero;

  return AnalyticsData(
    totalSessions: sessions.length,
    totalDistanceMeters: totalDist,
    weeklyDistances: weeklyDist,
    averagePacePerHundred: avgPace,
  );
}

final analyticsProvider = Provider<AnalyticsData>((ref) {
  final sessionsAsync = ref.watch(swimSessionsProvider);
  return sessionsAsync.when(
    data: (sessions) => _compute(sessions),
    loading: () => AnalyticsData.empty,
    error: (_, __) => AnalyticsData.empty,
  );
});
