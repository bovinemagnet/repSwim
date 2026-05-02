import '../../../../core/constants/app_constants.dart';
import 'tempo_mode.dart';

class TempoSplitResult {
  const TempoSplitResult({
    required this.index,
    required this.targetSplit,
    required this.actualSplit,
    this.strokeCount,
  });

  final int index;
  final Duration targetSplit;
  final Duration actualSplit;
  final int? strokeCount;

  Duration get error => actualSplit - targetSplit;
  bool get isOnPace => error.inMilliseconds.abs() <= 500;
}

class TempoSessionResult {
  const TempoSessionResult({
    required this.id,
    required this.mode,
    required this.startedAt,
    required this.targetDistanceMeters,
    required this.poolLengthMeters,
    required this.targetTime,
    required this.targetStrokeRate,
    required this.actualSplits,
    required this.strokeCounts,
    this.profileId = kDefaultProfileId,
    this.templateId,
    this.completedAt,
    this.rpe,
    this.notes,
  });

  final String id;
  final String profileId;
  final String? templateId;
  final TempoMode mode;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int targetDistanceMeters;
  final int poolLengthMeters;
  final Duration targetTime;
  final double targetStrokeRate;
  final List<Duration> actualSplits;
  final List<int> strokeCounts;
  final int? rpe;
  final String? notes;
}
