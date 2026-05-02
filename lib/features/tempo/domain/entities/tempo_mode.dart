enum TempoMode {
  strokeRate,
  lapPace,
  breathPattern;

  String get label {
    return switch (this) {
      TempoMode.strokeRate => 'Stroke Rate',
      TempoMode.lapPace => 'Lap Pace',
      TempoMode.breathPattern => 'Breath Pattern',
    };
  }
}

TempoMode tempoModeFromName(String name) {
  return TempoMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => TempoMode.strokeRate,
  );
}
