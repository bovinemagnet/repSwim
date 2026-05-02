import '../../../../core/constants/app_constants.dart';
import 'tempo_mode.dart';

class TempoCueSettings {
  const TempoCueSettings({
    this.audible = true,
    this.vibration = false,
    this.visualFlash = true,
    this.spoken = false,
    this.accentEvery = 4,
  });

  final bool audible;
  final bool vibration;
  final bool visualFlash;
  final bool spoken;
  final int accentEvery;

  TempoCueSettings copyWith({
    bool? audible,
    bool? vibration,
    bool? visualFlash,
    bool? spoken,
    int? accentEvery,
  }) {
    return TempoCueSettings(
      audible: audible ?? this.audible,
      vibration: vibration ?? this.vibration,
      visualFlash: visualFlash ?? this.visualFlash,
      spoken: spoken ?? this.spoken,
      accentEvery: accentEvery ?? this.accentEvery,
    );
  }
}

class TempoTemplate {
  const TempoTemplate({
    required this.id,
    required this.name,
    required this.mode,
    required this.poolLengthMeters,
    required this.targetDistanceMeters,
    required this.targetTime,
    required this.strokeRate,
    required this.breathEveryStrokes,
    required this.cueSettings,
    required this.safetyWarningAcknowledged,
    required this.createdAt,
    required this.updatedAt,
    this.profileId = kDefaultProfileId,
  });

  final String id;
  final String profileId;
  final String name;
  final TempoMode mode;
  final int poolLengthMeters;
  final int targetDistanceMeters;
  final Duration targetTime;
  final double strokeRate;
  final int breathEveryStrokes;
  final TempoCueSettings cueSettings;
  final bool safetyWarningAcknowledged;
  final DateTime createdAt;
  final DateTime updatedAt;

  TempoTemplate copyWith({
    String? id,
    String? profileId,
    String? name,
    TempoMode? mode,
    int? poolLengthMeters,
    int? targetDistanceMeters,
    Duration? targetTime,
    double? strokeRate,
    int? breathEveryStrokes,
    TempoCueSettings? cueSettings,
    bool? safetyWarningAcknowledged,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TempoTemplate(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      poolLengthMeters: poolLengthMeters ?? this.poolLengthMeters,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      targetTime: targetTime ?? this.targetTime,
      strokeRate: strokeRate ?? this.strokeRate,
      breathEveryStrokes: breathEveryStrokes ?? this.breathEveryStrokes,
      cueSettings: cueSettings ?? this.cueSettings,
      safetyWarningAcknowledged:
          safetyWarningAcknowledged ?? this.safetyWarningAcknowledged,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
