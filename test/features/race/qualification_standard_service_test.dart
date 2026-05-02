import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/race/domain/entities/qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';
import 'package:rep_swim/features/race/domain/services/qualification_standard_service.dart';

void main() {
  group('qualification standards', () {
    test('validates that gold is fastest and bronze is slowest', () {
      expect(hasValidQualificationOrder(_standard()), isTrue);
      expect(
        hasValidQualificationOrder(
          _standard(goldTime: const Duration(seconds: 33)),
        ),
        isFalse,
      );
    });

    test('assigns the best qualifying tier for a race time', () {
      final standard = _standard();

      expect(
        qualificationTierForTime(standard, const Duration(seconds: 28)),
        QualificationTier.gold,
      );
      expect(
        qualificationTierForTime(standard, const Duration(seconds: 31)),
        QualificationTier.silver,
      );
      expect(
        qualificationTierForTime(standard, const Duration(seconds: 34)),
        QualificationTier.bronze,
      );
      expect(
        qualificationTierForTime(standard, const Duration(seconds: 36)),
        isNull,
      );
    });

    test('matches standards by profile, age, stroke, distance, and course', () {
      final raceTime = RaceTime(
        id: 'race-1',
        profileId: 'profile-1',
        raceName: 'State Sprint',
        eventDate: DateTime.utc(2024),
        distance: 50,
        stroke: 'Freestyle',
        course: RaceCourse.longCourseMeters,
        time: const Duration(seconds: 31),
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
      );

      final result = qualificationResultForRace(
        standards: [
          _standard(age: 11),
          _standard(profileId: 'other-profile', age: 12),
          _standard(age: 12, course: RaceCourse.longCourseMeters),
        ],
        raceTime: raceTime,
        age: 12,
      );

      expect(result?.tier, QualificationTier.silver);
      expect(result?.margin, const Duration(seconds: 1));
    });
  });
}

QualificationStandard _standard({
  String profileId = 'profile-1',
  int age = 12,
  RaceCourse course = RaceCourse.shortCourseMeters,
  Duration goldTime = const Duration(seconds: 30),
  Duration silverTime = const Duration(seconds: 32),
  Duration bronzeTime = const Duration(seconds: 35),
}) {
  return QualificationStandard(
    id: 'standard-1',
    profileId: profileId,
    age: age,
    distance: 50,
    stroke: 'Freestyle',
    course: course,
    goldTime: goldTime,
    silverTime: silverTime,
    bronzeTime: bronzeTime,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}
