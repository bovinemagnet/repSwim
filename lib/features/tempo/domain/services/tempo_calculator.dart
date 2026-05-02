import '../entities/tempo_session_result.dart';

class TempoCalculator {
  const TempoCalculator();

  Duration beatIntervalForStrokeRate(double strokesPerMinute) {
    if (strokesPerMinute <= 0) {
      throw ArgumentError.value(strokesPerMinute, 'strokesPerMinute');
    }
    final microseconds =
        (Duration.microsecondsPerMinute / strokesPerMinute).round();
    return Duration(microseconds: microseconds);
  }

  double strokeRateForBeatInterval(Duration beatInterval) {
    if (beatInterval <= Duration.zero) {
      throw ArgumentError.value(beatInterval, 'beatInterval');
    }
    return Duration.microsecondsPerMinute / beatInterval.inMicroseconds;
  }

  Duration splitForDistance({
    required Duration targetTime,
    required int targetDistanceMeters,
    required int splitDistanceMeters,
  }) {
    if (targetTime <= Duration.zero ||
        targetDistanceMeters <= 0 ||
        splitDistanceMeters <= 0) {
      throw ArgumentError('Target time and distances must be positive.');
    }
    final ratio = splitDistanceMeters / targetDistanceMeters;
    return Duration(
      microseconds: (targetTime.inMicroseconds * ratio).round(),
    );
  }

  Duration pacePer100({
    required Duration targetTime,
    required int targetDistanceMeters,
  }) {
    return splitForDistance(
      targetTime: targetTime,
      targetDistanceMeters: targetDistanceMeters,
      splitDistanceMeters: 100,
    );
  }

  double distancePerStroke({
    required int distanceMeters,
    required int strokeCount,
  }) {
    if (distanceMeters <= 0 || strokeCount <= 0) {
      throw ArgumentError('Distance and stroke count must be positive.');
    }
    return distanceMeters / strokeCount;
  }

  List<TempoSplitResult> compareSplits({
    required List<Duration> actualSplits,
    required Duration targetSplit,
    List<int> strokeCounts = const [],
  }) {
    return [
      for (var i = 0; i < actualSplits.length; i++)
        TempoSplitResult(
          index: i + 1,
          targetSplit: targetSplit,
          actualSplit: actualSplits[i],
          strokeCount: i < strokeCounts.length ? strokeCounts[i] : null,
        ),
    ];
  }

  Duration averageSplitError(List<TempoSplitResult> results) {
    if (results.isEmpty) return Duration.zero;
    final totalError = results.fold<int>(
      0,
      (sum, result) => sum + result.error.inMilliseconds,
    );
    return Duration(milliseconds: (totalError / results.length).round());
  }

  bool requiresBreathSafetyWarning(int breathEveryStrokes) {
    return breathEveryStrokes >= 5;
  }
}
