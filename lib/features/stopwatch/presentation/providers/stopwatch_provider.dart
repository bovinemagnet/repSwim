import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StopwatchState {
  const StopwatchState({
    this.elapsed = Duration.zero,
    this.lapTimes = const [],
    this.isRunning = false,
    this.startedAt,
    this.baseElapsed = Duration.zero,
  });

  /// Total elapsed time including all resumed segments.
  final Duration elapsed;

  /// Recorded lap split times.
  final List<Duration> lapTimes;

  final bool isRunning;

  /// Wall-clock time when the current run segment started.
  final DateTime? startedAt;

  /// Accumulated elapsed before the last resume.
  final Duration baseElapsed;

  StopwatchState copyWith({
    Duration? elapsed,
    List<Duration>? lapTimes,
    bool? isRunning,
    DateTime? startedAt,
    Duration? baseElapsed,
    bool clearStartedAt = false,
  }) {
    return StopwatchState(
      elapsed: elapsed ?? this.elapsed,
      lapTimes: lapTimes ?? this.lapTimes,
      isRunning: isRunning ?? this.isRunning,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
      baseElapsed: baseElapsed ?? this.baseElapsed,
    );
  }
}

class StopwatchNotifier extends StateNotifier<StopwatchState> {
  StopwatchNotifier() : super(const StopwatchState());

  Timer? _ticker;

  void start() {
    if (state.isRunning) return;
    final now = DateTime.now();
    state = state.copyWith(isRunning: true, startedAt: now);
    _ticker = Timer.periodic(const Duration(milliseconds: 10), (_) {
      final newElapsed =
          state.baseElapsed + DateTime.now().difference(state.startedAt!);
      state = state.copyWith(elapsed: newElapsed);
    });
  }

  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    _ticker = null;
    final newBase =
        state.baseElapsed + DateTime.now().difference(state.startedAt!);
    state = state.copyWith(
      isRunning: false,
      baseElapsed: newBase,
      elapsed: newBase,
      clearStartedAt: true,
    );
  }

  void lap() {
    if (!state.isRunning) return;
    state = state.copyWith(
      lapTimes: [...state.lapTimes, state.elapsed],
    );
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = const StopwatchState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final stopwatchProvider =
    StateNotifierProvider<StopwatchNotifier, StopwatchState>(
  (ref) => StopwatchNotifier(),
);
