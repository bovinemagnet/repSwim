import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/race/domain/services/race_time_service.dart';

void main() {
  group('filterRaceTimes', () {
    test('filters by query, distance, and course then sorts by fastest', () {
      final races = [
        _race(
          id: 'slow',
          raceName: 'State Sprint',
          distance: 100,
          course: RaceCourse.longCourseMeters,
          time: const Duration(seconds: 62),
        ),
        _race(
          id: 'fast',
          raceName: 'State Sprint',
          distance: 100,
          course: RaceCourse.longCourseMeters,
          time: const Duration(seconds: 58),
        ),
        _race(
          id: 'other-course',
          raceName: 'State Sprint',
          distance: 100,
          course: RaceCourse.shortCourseMeters,
          time: const Duration(seconds: 55),
        ),
      ];

      final filtered = filterRaceTimes(
        races,
        query: 'state',
        distance: 100,
        course: RaceCourse.longCourseMeters,
        sort: RaceTimeSort.fastest,
      );

      expect(filtered.map((race) => race.id), ['fast', 'slow']);
    });
  });

  group('bestRaceTimesByEventCourse', () {
    test('keeps short-course and long-course bests separate', () {
      final races = [
        _race(
          id: 'lcm',
          course: RaceCourse.longCourseMeters,
          time: const Duration(seconds: 61),
        ),
        _race(
          id: 'scm',
          course: RaceCourse.shortCourseMeters,
          time: const Duration(seconds: 59),
        ),
        _race(
          id: 'lcm-faster',
          course: RaceCourse.longCourseMeters,
          time: const Duration(seconds: 60),
        ),
      ];

      final best = bestRaceTimesByEventCourse(races);

      expect(best.map((race) => race.id), ['lcm-faster', 'scm']);
    });
  });
}

RaceTime _race({
  required String id,
  String profileId = 'profile-1',
  String raceName = 'Club Champs',
  int distance = 100,
  RaceCourse course = RaceCourse.shortCourseMeters,
  Duration time = const Duration(seconds: 60),
}) {
  return RaceTime(
    id: id,
    profileId: profileId,
    raceName: raceName,
    eventDate: DateTime.utc(2024, 5, 1),
    distance: distance,
    stroke: 'Freestyle',
    course: course,
    time: time,
    createdAt: DateTime.utc(2024, 5, 1),
    updatedAt: DateTime.utc(2024, 5, 1),
  );
}
