class PersonalBest {
  const PersonalBest({
    required this.id,
    required this.stroke,
    required this.distance,
    required this.bestTime,
    required this.achievedAt,
  });

  final String id;
  final String stroke;

  /// Distance in meters.
  final int distance;
  final Duration bestTime;
  final DateTime achievedAt;

  PersonalBest copyWith({
    String? id,
    String? stroke,
    int? distance,
    Duration? bestTime,
    DateTime? achievedAt,
  }) {
    return PersonalBest(
      id: id ?? this.id,
      stroke: stroke ?? this.stroke,
      distance: distance ?? this.distance,
      bestTime: bestTime ?? this.bestTime,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  @override
  String toString() =>
      'PersonalBest($stroke ${distance}m, ${bestTime.inSeconds}s)';
}
