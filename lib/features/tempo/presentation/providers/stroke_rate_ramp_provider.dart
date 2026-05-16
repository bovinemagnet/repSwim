import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/duration_utils.dart';
import '../../domain/services/stroke_rate_ramp_calculator.dart';

class StrokeRateRampState {
  const StrokeRateRampState({
    this.startStrokeRate = 60,
    this.increment = 4,
    this.repeatDistanceMeters = 25,
    this.reps = 6,
    this.restDuration = const Duration(seconds: 20),
    this.logs = const [],
    this.lastStatus = 'Ready',
  });

  final double startStrokeRate;
  final double increment;
  final int repeatDistanceMeters;
  final int reps;
  final Duration restDuration;
  final List<StrokeRateRampRepLog> logs;
  final String lastStatus;

  StrokeRateRampProtocol get protocol =>
      const StrokeRateRampCalculator().generate(
        startStrokeRate: startStrokeRate,
        increment: increment,
        repeatDistanceMeters: repeatDistanceMeters,
        reps: reps,
        restDuration: restDuration,
      );

  bool get isComplete => logs.length >= reps;
  int get nextRep => isComplete ? reps : logs.length + 1;
  StrokeRateRampRep get currentTarget => protocol.targets[nextRep - 1];

  String get summary {
    if (logs.isEmpty) return 'No ramp reps logged';
    final fastest = logs.reduce(
      (best, log) => log.pacePer100 < best.pacePer100 ? log : best,
    );
    final efficient = logs.reduce(
      (best, log) =>
          log.distancePerStroke > best.distancePerStroke ? log : best,
    );
    return 'Fastest ${DurationUtils.formatDuration(fastest.pacePer100)}/100m '
        'at ${fastest.strokeRate.toStringAsFixed(1)} spm; '
        'best DPS ${efficient.distancePerStroke.toStringAsFixed(2)}m '
        'at ${efficient.strokeRate.toStringAsFixed(1)} spm';
  }

  StrokeRateRampState copyWith({
    double? startStrokeRate,
    double? increment,
    int? repeatDistanceMeters,
    int? reps,
    Duration? restDuration,
    List<StrokeRateRampRepLog>? logs,
    String? lastStatus,
  }) {
    return StrokeRateRampState(
      startStrokeRate: startStrokeRate ?? this.startStrokeRate,
      increment: increment ?? this.increment,
      repeatDistanceMeters: repeatDistanceMeters ?? this.repeatDistanceMeters,
      reps: reps ?? this.reps,
      restDuration: restDuration ?? this.restDuration,
      logs: logs ?? this.logs,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}

class StrokeRateRampNotifier extends StateNotifier<StrokeRateRampState> {
  StrokeRateRampNotifier() : super(const StrokeRateRampState());

  void configure({
    required double startStrokeRate,
    required double increment,
    required int repeatDistanceMeters,
    required int reps,
    required Duration restDuration,
  }) {
    const StrokeRateRampCalculator().generate(
      startStrokeRate: startStrokeRate,
      increment: increment,
      repeatDistanceMeters: repeatDistanceMeters,
      reps: reps,
      restDuration: restDuration,
    );
    state = state.copyWith(
      startStrokeRate: startStrokeRate,
      increment: increment,
      repeatDistanceMeters: repeatDistanceMeters,
      reps: reps,
      restDuration: restDuration,
      logs: const [],
      lastStatus: 'Ready',
    );
  }

  void logRep({
    required Duration split,
    required int strokeCount,
    int? rpe,
    String? notes,
  }) {
    if (state.isComplete) return;
    if (split <= Duration.zero || strokeCount <= 0) {
      throw ArgumentError('Ramp split and stroke count must be positive.');
    }
    if (rpe != null && (rpe < 1 || rpe > 10)) {
      throw ArgumentError('Ramp RPE must be between 1 and 10.');
    }

    final target = state.currentTarget;
    final log = StrokeRateRampRepLog(
      index: target.index,
      strokeRate: target.strokeRate,
      repeatDistanceMeters: target.repeatDistanceMeters,
      split: split,
      strokeCount: strokeCount,
      rpe: rpe,
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
    );
    final logs = [...state.logs, log];
    state = state.copyWith(
      logs: logs,
      lastStatus: logs.length >= state.reps
          ? 'Ramp complete.'
          : 'Logged rep ${log.index}.',
    );
  }

  void resetLogs() {
    state = state.copyWith(logs: const [], lastStatus: 'Ready');
  }
}

final strokeRateRampProvider =
    StateNotifierProvider<StrokeRateRampNotifier, StrokeRateRampState>(
  (ref) => StrokeRateRampNotifier(),
);
