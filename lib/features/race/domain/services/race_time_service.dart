import '../entities/race_time.dart';

enum RaceTimeSort {
  newest,
  oldest,
  fastest,
  distance,
}

List<RaceTime> filterRaceTimes(
  List<RaceTime> raceTimes, {
  String query = '',
  int? distance,
  String? stroke,
  RaceCourse? course,
  RaceTimeSort sort = RaceTimeSort.newest,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = raceTimes.where((raceTime) {
    final searchable = [
      raceTime.raceName,
      raceTime.stroke,
      raceTime.course.code,
      raceTime.course.label,
      raceTime.location ?? '',
      raceTime.notes ?? '',
    ].join(' ').toLowerCase();
    return (normalizedQuery.isEmpty || searchable.contains(normalizedQuery)) &&
        (distance == null || raceTime.distance == distance) &&
        (stroke == null || raceTime.stroke == stroke) &&
        (course == null || raceTime.course == course);
  }).toList();

  filtered.sort((a, b) {
    switch (sort) {
      case RaceTimeSort.newest:
        return b.eventDate.compareTo(a.eventDate);
      case RaceTimeSort.oldest:
        return a.eventDate.compareTo(b.eventDate);
      case RaceTimeSort.fastest:
        final timeComparison = a.time.compareTo(b.time);
        if (timeComparison != 0) return timeComparison;
        return b.eventDate.compareTo(a.eventDate);
      case RaceTimeSort.distance:
        final distanceComparison = a.distance.compareTo(b.distance);
        if (distanceComparison != 0) return distanceComparison;
        return a.time.compareTo(b.time);
    }
  });
  return filtered;
}

List<RaceTime> bestRaceTimesByEventCourse(List<RaceTime> raceTimes) {
  final bestByKey = <String, RaceTime>{};
  for (final raceTime in raceTimes) {
    final key = [
      raceTime.profileId,
      raceTime.stroke,
      raceTime.distance,
      raceTime.course.name,
    ].join('|');
    final existing = bestByKey[key];
    if (existing == null ||
        raceTime.time < existing.time ||
        (raceTime.time == existing.time &&
            raceTime.eventDate.isBefore(existing.eventDate))) {
      bestByKey[key] = raceTime;
    }
  }
  final best = bestByKey.values.toList()
    ..sort((a, b) {
      final strokeComparison = a.stroke.compareTo(b.stroke);
      if (strokeComparison != 0) return strokeComparison;
      final distanceComparison = a.distance.compareTo(b.distance);
      if (distanceComparison != 0) return distanceComparison;
      return a.course.code.compareTo(b.course.code);
    });
  return best;
}
