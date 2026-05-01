class Lap {
  const Lap({
    required this.id,
    required this.sessionId,
    required this.distance,
    required this.time,
    required this.lapNumber,
  });

  final String id;
  final String sessionId;

  /// Distance in meters.
  final int distance;
  final Duration time;
  final int lapNumber;

  Lap copyWith({
    String? id,
    String? sessionId,
    int? distance,
    Duration? time,
    int? lapNumber,
  }) {
    return Lap(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      distance: distance ?? this.distance,
      time: time ?? this.time,
      lapNumber: lapNumber ?? this.lapNumber,
    );
  }

  @override
  String toString() =>
      'Lap(#$lapNumber, ${distance}m, ${time.inSeconds}s)';
}
