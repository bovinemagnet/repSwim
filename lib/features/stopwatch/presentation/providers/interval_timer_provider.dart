import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum IntervalPhase { ready, swim, rest, complete }

class IntervalTimerState {
  const IntervalTimerState({
    this.sets = 3,
    this.reps = 4,
    this.workDuration = const Duration(seconds: 45),
    this.restDuration = const Duration(seconds: 15),
    this.currentSet = 1,
    this.currentRep = 1,
    this.remaining = const Duration(seconds: 45),
    this.phase = IntervalPhase.ready,
    this.isRunning = false,
  });

  final int sets;
  final int reps;
  final Duration workDuration;
  final Duration restDuration;
  final int currentSet;
  final int currentRep;
  final Duration remaining;
  final IntervalPhase phase;
  final bool isRunning;

  int get totalRounds => sets * reps;
  int get completedRounds => ((currentSet - 1) * reps) + currentRep - 1;
  int get currentRound =>
      phase == IntervalPhase.complete ? totalRounds : completedRounds + 1;

  IntervalTimerState copyWith({
    int? sets,
    int? reps,
    Duration? workDuration,
    Duration? restDuration,
    int? currentSet,
    int? currentRep,
    Duration? remaining,
    IntervalPhase? phase,
    bool? isRunning,
  }) {
    return IntervalTimerState(
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      workDuration: workDuration ?? this.workDuration,
      restDuration: restDuration ?? this.restDuration,
      currentSet: currentSet ?? this.currentSet,
      currentRep: currentRep ?? this.currentRep,
      remaining: remaining ?? this.remaining,
      phase: phase ?? this.phase,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class IntervalTimerNotifier extends StateNotifier<IntervalTimerState> {
  IntervalTimerNotifier() : super(const IntervalTimerState());

  Timer? _ticker;

  void configure({
    required int sets,
    required int reps,
    required Duration workDuration,
    required Duration restDuration,
  }) {
    _ticker?.cancel();
    state = IntervalTimerState(
      sets: sets,
      reps: reps,
      workDuration: workDuration,
      restDuration: restDuration,
      remaining: workDuration,
    );
  }

  void start() {
    if (state.isRunning || state.phase == IntervalPhase.complete) return;

    final nextPhase =
        state.phase == IntervalPhase.ready ? IntervalPhase.swim : state.phase;
    state = state.copyWith(phase: nextPhase, isRunning: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(
      currentSet: 1,
      currentRep: 1,
      remaining: state.workDuration,
      phase: IntervalPhase.ready,
      isRunning: false,
    );
  }

  void skipPhase() {
    if (state.phase == IntervalPhase.ready) {
      state = state.copyWith(phase: IntervalPhase.swim);
      return;
    }
    if (state.phase == IntervalPhase.complete) return;
    _advancePhase();
  }

  void _tick() {
    if (!state.isRunning) return;

    final nextRemaining = state.remaining - const Duration(seconds: 1);
    if (nextRemaining > Duration.zero) {
      state = state.copyWith(remaining: nextRemaining);
      return;
    }

    _advancePhase();
  }

  void _advancePhase() {
    final hasMoreReps = state.currentRep < state.reps;
    final hasMoreSets = state.currentSet < state.sets;
    final hasMoreWork = hasMoreReps || hasMoreSets;

    if (state.phase == IntervalPhase.swim) {
      if (hasMoreWork && state.restDuration > Duration.zero) {
        state = state.copyWith(
          phase: IntervalPhase.rest,
          remaining: state.restDuration,
        );
        return;
      }
      _moveToNextSwimOrComplete(hasMoreReps, hasMoreSets);
      return;
    }

    _moveToNextSwimOrComplete(hasMoreReps, hasMoreSets);
  }

  void _moveToNextSwimOrComplete(bool hasMoreReps, bool hasMoreSets) {
    if (hasMoreReps) {
      state = state.copyWith(
        currentRep: state.currentRep + 1,
        phase: IntervalPhase.swim,
        remaining: state.workDuration,
      );
      return;
    }

    if (hasMoreSets) {
      state = state.copyWith(
        currentSet: state.currentSet + 1,
        currentRep: 1,
        phase: IntervalPhase.swim,
        remaining: state.workDuration,
      );
      return;
    }

    _ticker?.cancel();
    _ticker = null;
    state = state.copyWith(
      phase: IntervalPhase.complete,
      remaining: Duration.zero,
      isRunning: false,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final intervalTimerProvider =
    StateNotifierProvider<IntervalTimerNotifier, IntervalTimerState>(
  (ref) => IntervalTimerNotifier(),
);
