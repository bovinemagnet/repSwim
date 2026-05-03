import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/usrpt_calculator.dart';

class UsrptSessionState {
  const UsrptSessionState({
    this.eventDistanceMeters = 100,
    this.eventTargetTime = const Duration(seconds: 60),
    this.repetitionDistanceMeters = 25,
    this.restDuration = const Duration(seconds: 20),
    this.failLimit = 3,
    this.outcomes = const [],
    this.restRemaining = Duration.zero,
    this.lastStatus = 'Ready',
    this.failRuleReached = false,
  });

  final int eventDistanceMeters;
  final Duration eventTargetTime;
  final int repetitionDistanceMeters;
  final Duration restDuration;
  final int failLimit;
  final List<UsrptRepOutcome> outcomes;
  final Duration restRemaining;
  final String lastStatus;
  final bool failRuleReached;

  UsrptRacePacePreset get preset => const UsrptRacePaceCalculator().calculate(
        eventDistanceMeters: eventDistanceMeters,
        eventTargetTime: eventTargetTime,
        repetitionDistanceMeters: repetitionDistanceMeters,
        restDuration: restDuration,
        failLimit: failLimit,
      );

  int get nextRep => outcomes.length + 1;
  int get passCount => outcomes.where((outcome) => outcome.passed).length;
  int get failCount => outcomes.where((outcome) => !outcome.passed).length;

  UsrptSessionState copyWith({
    int? eventDistanceMeters,
    Duration? eventTargetTime,
    int? repetitionDistanceMeters,
    Duration? restDuration,
    int? failLimit,
    List<UsrptRepOutcome>? outcomes,
    Duration? restRemaining,
    String? lastStatus,
    bool? failRuleReached,
  }) {
    return UsrptSessionState(
      eventDistanceMeters: eventDistanceMeters ?? this.eventDistanceMeters,
      eventTargetTime: eventTargetTime ?? this.eventTargetTime,
      repetitionDistanceMeters:
          repetitionDistanceMeters ?? this.repetitionDistanceMeters,
      restDuration: restDuration ?? this.restDuration,
      failLimit: failLimit ?? this.failLimit,
      outcomes: outcomes ?? this.outcomes,
      restRemaining: restRemaining ?? this.restRemaining,
      lastStatus: lastStatus ?? this.lastStatus,
      failRuleReached: failRuleReached ?? this.failRuleReached,
    );
  }
}

class UsrptSessionNotifier extends StateNotifier<UsrptSessionState> {
  UsrptSessionNotifier() : super(const UsrptSessionState());

  void configure({
    required int eventDistanceMeters,
    required Duration eventTargetTime,
    required int repetitionDistanceMeters,
    required Duration restDuration,
    required int failLimit,
  }) {
    const UsrptRacePaceCalculator().calculate(
      eventDistanceMeters: eventDistanceMeters,
      eventTargetTime: eventTargetTime,
      repetitionDistanceMeters: repetitionDistanceMeters,
      restDuration: restDuration,
      failLimit: failLimit,
    );
    state = state.copyWith(
      eventDistanceMeters: eventDistanceMeters,
      eventTargetTime: eventTargetTime,
      repetitionDistanceMeters: repetitionDistanceMeters,
      restDuration: restDuration,
      failLimit: failLimit,
      outcomes: const [],
      restRemaining: Duration.zero,
      lastStatus: 'Ready',
      failRuleReached: false,
    );
  }

  void logPass() => _logOutcome(passed: true);

  void logFail() => _logOutcome(passed: false);

  void tickRest(Duration elapsed) {
    if (state.restRemaining <= Duration.zero || elapsed <= Duration.zero) {
      return;
    }
    final nextRest = state.restRemaining - elapsed;
    state = state.copyWith(
      restRemaining: nextRest.isNegative ? Duration.zero : nextRest,
    );
  }

  void resetOutcomes() {
    state = state.copyWith(
      outcomes: const [],
      restRemaining: Duration.zero,
      lastStatus: 'Ready',
      failRuleReached: false,
    );
  }

  void _logOutcome({required bool passed}) {
    if (state.failRuleReached) return;

    final outcomes = [
      ...state.outcomes,
      UsrptRepOutcome(index: state.nextRep, passed: passed),
    ];
    final failCount = outcomes.where((outcome) => !outcome.passed).length;
    final reached = failCount >= state.failLimit;
    final status = reached
        ? 'Fail rule reached after $failCount fails.'
        : passed
            ? 'Rep ${outcomes.length} pass. Rest next.'
            : 'Rep ${outcomes.length} fail. Rest next.';

    state = state.copyWith(
      outcomes: outcomes,
      restRemaining: reached ? Duration.zero : state.restDuration,
      lastStatus: status,
      failRuleReached: reached,
    );
  }
}

final usrptSessionProvider =
    StateNotifierProvider<UsrptSessionNotifier, UsrptSessionState>(
  (ref) => UsrptSessionNotifier(),
);
