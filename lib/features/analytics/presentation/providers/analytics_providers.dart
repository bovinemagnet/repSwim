import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../pb/domain/entities/personal_best.dart';
import '../../../pb/presentation/providers/pb_providers.dart';
import '../../../swim/presentation/providers/swim_providers.dart';
import '../../../swim/domain/entities/swim_session.dart';
import '../../../../core/utils/duration_utils.dart';

class PaceTrendPoint {
  const PaceTrendPoint({
    required this.date,
    required this.pacePerHundred,
  });

  final DateTime date;
  final Duration pacePerHundred;
}

/// Aggregated analytics data derived from all swim sessions.
class AnalyticsData {
  const AnalyticsData({
    required this.totalSessions,
    required this.totalDistanceMeters,
    required this.weeklyDistances,
    required this.averagePacePerHundred,
    required this.consistencyScore,
    required this.paceTrend,
    required this.pbHighlights,
  });

  final int totalSessions;
  final int totalDistanceMeters;

  /// Distance in metres for each of the last 7 days (index 0 = oldest).
  final List<int> weeklyDistances;

  final Duration averagePacePerHundred;
  final int consistencyScore;
  final List<PaceTrendPoint> paceTrend;
  final List<PersonalBest> pbHighlights;

  static const empty = AnalyticsData(
    totalSessions: 0,
    totalDistanceMeters: 0,
    weeklyDistances: [0, 0, 0, 0, 0, 0, 0],
    averagePacePerHundred: Duration.zero,
    consistencyScore: 0,
    paceTrend: [],
    pbHighlights: [],
  );
}

AnalyticsData computeAnalytics(
  List<SwimSession> sessions,
  List<PersonalBest> personalBests,
) {
  if (sessions.isEmpty && personalBests.isEmpty) return AnalyticsData.empty;

  final totalDist = sessions.fold<int>(0, (s, e) => s + e.totalDistance);

  // Build weekly buckets (last 7 days including today).
  final today = DateTime.now();
  final weeklyDist = List<int>.filled(7, 0);
  final activeDays = <DateTime>{};
  for (final s in sessions) {
    final diff = today.difference(s.date).inDays;
    if (diff >= 0 && diff < 7) {
      // day 0 = today (index 6), day 6 = 6 days ago (index 0)
      weeklyDist[6 - diff] += s.totalDistance;
      activeDays.add(DateTime(s.date.year, s.date.month, s.date.day));
    }
  }

  // Average pace: total time / total distance * 100m.
  final totalSeconds =
      sessions.fold<int>(0, (s, e) => s + e.totalTime.inSeconds);
  final avgPace = totalDist > 0
      ? Duration(
          milliseconds: (totalSeconds * 1000 * 100 / totalDist).round(),
        )
      : Duration.zero;

  final sessionsWithPace = sessions
      .where((session) => session.totalDistance > 0)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final paceTrend = sessionsWithPace
      .skip(sessionsWithPace.length > 7 ? sessionsWithPace.length - 7 : 0)
      .map(
        (session) => PaceTrendPoint(
          date: session.date,
          pacePerHundred: DurationUtils.calculatePace(
            session.totalTime,
            session.totalDistance,
          ),
        ),
      )
      .toList();

  final pbHighlights = [...personalBests]
    ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

  return AnalyticsData(
    totalSessions: sessions.length,
    totalDistanceMeters: totalDist,
    weeklyDistances: weeklyDist,
    averagePacePerHundred: avgPace,
    consistencyScore: (activeDays.length / 3 * 100).clamp(0, 100).round(),
    paceTrend: paceTrend,
    pbHighlights: pbHighlights.take(3).toList(),
  );
}

final analyticsProvider = Provider<AnalyticsData>((ref) {
  final sessionsAsync = ref.watch(swimSessionsProvider);
  final pbsAsync = ref.watch(personalBestsProvider);
  final sessions = sessionsAsync.valueOrNull ?? const <SwimSession>[];
  final pbs = pbsAsync.valueOrNull ?? const <PersonalBest>[];
  return computeAnalytics(sessions, pbs);
});
