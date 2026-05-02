import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tempo_mode.dart';
import '../../domain/entities/tempo_template.dart';
import '../../domain/services/tempo_calculator.dart';
import 'tempo_cue_player.dart';

class TempoTrainerState {
  const TempoTrainerState({
    this.mode = TempoMode.strokeRate,
    this.poolLengthMeters = 25,
    this.targetDistanceMeters = 100,
    this.targetTime = const Duration(seconds: 90),
    this.strokeRate = 60,
    this.breathEveryStrokes = 3,
    this.cueSettings = const TempoCueSettings(),
    this.safetyWarningAcknowledged = false,
    this.isRunning = false,
    this.beatCount = 0,
    this.elapsed = Duration.zero,
    this.flashActive = false,
    this.lastCueLabel = 'Ready',
  });

  final TempoMode mode;
  final int poolLengthMeters;
  final int targetDistanceMeters;
  final Duration targetTime;
  final double strokeRate;
  final int breathEveryStrokes;
  final TempoCueSettings cueSettings;
  final bool safetyWarningAcknowledged;
  final bool isRunning;
  final int beatCount;
  final Duration elapsed;
  final bool flashActive;
  final String lastCueLabel;

  TempoCalculator get _calculator => const TempoCalculator();

  Duration get baseStrokeBeatInterval =>
      _calculator.beatIntervalForStrokeRate(strokeRate);

  Duration get lapSplit => _calculator.splitForDistance(
        targetTime: targetTime,
        targetDistanceMeters: targetDistanceMeters,
        splitDistanceMeters: poolLengthMeters,
      );

  Duration get pacePer100 => _calculator.pacePer100(
        targetTime: targetTime,
        targetDistanceMeters: targetDistanceMeters,
      );

  Duration get cueInterval {
    return switch (mode) {
      TempoMode.strokeRate => baseStrokeBeatInterval,
      TempoMode.lapPace => lapSplit,
      TempoMode.breathPattern => Duration(
          microseconds:
              baseStrokeBeatInterval.inMicroseconds * breathEveryStrokes,
        ),
    };
  }

  bool get requiresSafetyWarning =>
      mode == TempoMode.breathPattern &&
      _calculator.requiresBreathSafetyWarning(breathEveryStrokes);

  TempoTrainerState copyWith({
    TempoMode? mode,
    int? poolLengthMeters,
    int? targetDistanceMeters,
    Duration? targetTime,
    double? strokeRate,
    int? breathEveryStrokes,
    TempoCueSettings? cueSettings,
    bool? safetyWarningAcknowledged,
    bool? isRunning,
    int? beatCount,
    Duration? elapsed,
    bool? flashActive,
    String? lastCueLabel,
  }) {
    return TempoTrainerState(
      mode: mode ?? this.mode,
      poolLengthMeters: poolLengthMeters ?? this.poolLengthMeters,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      targetTime: targetTime ?? this.targetTime,
      strokeRate: strokeRate ?? this.strokeRate,
      breathEveryStrokes: breathEveryStrokes ?? this.breathEveryStrokes,
      cueSettings: cueSettings ?? this.cueSettings,
      safetyWarningAcknowledged:
          safetyWarningAcknowledged ?? this.safetyWarningAcknowledged,
      isRunning: isRunning ?? this.isRunning,
      beatCount: beatCount ?? this.beatCount,
      elapsed: elapsed ?? this.elapsed,
      flashActive: flashActive ?? this.flashActive,
      lastCueLabel: lastCueLabel ?? this.lastCueLabel,
    );
  }

  TempoTemplate toTemplate({
    required String id,
    required String profileId,
    required String name,
    required DateTime now,
  }) {
    return TempoTemplate(
      id: id,
      profileId: profileId,
      name: name,
      mode: mode,
      poolLengthMeters: poolLengthMeters,
      targetDistanceMeters: targetDistanceMeters,
      targetTime: targetTime,
      strokeRate: strokeRate,
      breathEveryStrokes: breathEveryStrokes,
      cueSettings: cueSettings,
      safetyWarningAcknowledged: safetyWarningAcknowledged,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class TempoTrainerNotifier extends StateNotifier<TempoTrainerState> {
  TempoTrainerNotifier(this._cuePlayer) : super(const TempoTrainerState());

  final TempoCuePlayer _cuePlayer;
  Timer? _timer;

  void configure({
    required TempoMode mode,
    required int poolLengthMeters,
    required int targetDistanceMeters,
    required Duration targetTime,
    required double strokeRate,
    required int breathEveryStrokes,
    required TempoCueSettings cueSettings,
    required bool safetyWarningAcknowledged,
  }) {
    stop();
    state = state.copyWith(
      mode: mode,
      poolLengthMeters: poolLengthMeters,
      targetDistanceMeters: targetDistanceMeters,
      targetTime: targetTime,
      strokeRate: strokeRate,
      breathEveryStrokes: breathEveryStrokes,
      cueSettings: cueSettings,
      safetyWarningAcknowledged: safetyWarningAcknowledged,
      lastCueLabel: 'Ready',
    );
  }

  void loadTemplate(TempoTemplate template) {
    configure(
      mode: template.mode,
      poolLengthMeters: template.poolLengthMeters,
      targetDistanceMeters: template.targetDistanceMeters,
      targetTime: template.targetTime,
      strokeRate: template.strokeRate,
      breathEveryStrokes: template.breathEveryStrokes,
      cueSettings: template.cueSettings,
      safetyWarningAcknowledged: template.safetyWarningAcknowledged,
    );
  }

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, lastCueLabel: 'Running');
    _playCue();
    _timer = Timer.periodic(state.cueInterval, (_) => _playCue());
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false, lastCueLabel: 'Paused');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      isRunning: false,
      beatCount: 0,
      elapsed: Duration.zero,
      flashActive: false,
      lastCueLabel: 'Ready',
    );
  }

  void clearFlash() {
    if (!state.flashActive) return;
    state = state.copyWith(flashActive: false);
  }

  Future<void> _playCue() async {
    final nextBeat = state.beatCount + 1;
    final accentEvery = state.cueSettings.accentEvery;
    final accent = accentEvery > 0 && nextBeat % accentEvery == 0;
    state = state.copyWith(
      beatCount: nextBeat,
      elapsed: state.elapsed + state.cueInterval,
      flashActive: state.cueSettings.visualFlash,
      lastCueLabel: accent ? 'Accent cue' : _cueLabelForMode(state.mode),
    );
    await _cuePlayer.playCue(settings: state.cueSettings, accent: accent);
  }

  String _cueLabelForMode(TempoMode mode) {
    return switch (mode) {
      TempoMode.strokeRate => 'Stroke cue',
      TempoMode.lapPace => 'Wall cue',
      TempoMode.breathPattern => 'Breathe cue',
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final tempoTrainerProvider =
    StateNotifierProvider<TempoTrainerNotifier, TempoTrainerState>(
  (ref) => TempoTrainerNotifier(ref.read(tempoCuePlayerProvider)),
);
