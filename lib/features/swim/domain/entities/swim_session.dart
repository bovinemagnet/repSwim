import 'lap.dart';

class SwimSession {
  const SwimSession({
    required this.id,
    required this.date,
    required this.totalDistance,
    required this.totalTime,
    required this.stroke,
    required this.laps,
    this.notes,
  });

  final String id;
  final DateTime date;

  /// Total distance in meters.
  final int totalDistance;
  final Duration totalTime;
  final String stroke;
  final List<Lap> laps;
  final String? notes;

  SwimSession copyWith({
    String? id,
    DateTime? date,
    int? totalDistance,
    Duration? totalTime,
    String? stroke,
    List<Lap>? laps,
    String? notes,
  }) {
    return SwimSession(
      id: id ?? this.id,
      date: date ?? this.date,
      totalDistance: totalDistance ?? this.totalDistance,
      totalTime: totalTime ?? this.totalTime,
      stroke: stroke ?? this.stroke,
      laps: laps ?? this.laps,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'SwimSession(id: $id, date: $date, distance: ${totalDistance}m, stroke: $stroke)';
}
