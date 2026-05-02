import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/race/data/qualification_sources/victorian_metro_sc_2026.dart';
import 'package:rep_swim/features/race/domain/entities/meet_qualification_standard.dart';
import 'package:rep_swim/features/race/domain/entities/race_time.dart';

void main() {
  group('Victorian Metro SC 2026 qualification source', () {
    test('preserves all extracted PDF rows by category', () {
      final standards = victorianMetroSc2026QualifyingStandards();

      expect(standards, hasLength(92));
      expect(standards.map((standard) => standard.id).toSet(), hasLength(92));
      expect(
        standards.where(
          (standard) =>
              !standard.isRelay &&
              standard.mcPoints == null &&
              standard.hasQualifyingTime,
        ),
        hasLength(74),
      );
      expect(
        standards.where((standard) => standard.mcPoints != null),
        hasLength(12),
      );
      expect(
        standards.where((standard) => standard.isRelay),
        hasLength(6),
      );
    });

    test('maps representative individual standards to centiseconds', () {
      final standards = victorianMetroSc2026QualifyingStandards();

      final maleFreestyle = standards.singleWhere(
        (standard) =>
            standard.sex == QualificationSex.male &&
            standard.ageGroupLabel == '14 - 15 Years' &&
            standard.distance == 100 &&
            standard.stroke == 'Freestyle',
      );
      expect(maleFreestyle.course, RaceCourse.shortCourseMeters);
      expect(maleFreestyle.qualifyingCentiseconds, 5962);
      expect(maleFreestyle.matchesAge(14), isTrue);
      expect(maleFreestyle.matchesAge(16), isFalse);

      final femaleMedley = standards.singleWhere(
        (standard) =>
            standard.sex == QualificationSex.female &&
            standard.ageGroupLabel == '18 / Over' &&
            standard.distance == 100 &&
            standard.stroke == 'Individual Medley',
      );
      expect(femaleMedley.qualifyingCentiseconds, 7418);
      expect(femaleMedley.matchesAge(18), isTrue);
      expect(femaleMedley.matchesAge(17), isFalse);
    });

    test('represents MC point thresholds and relay rows separately', () {
      final standards = victorianMetroSc2026QualifyingStandards();

      final mcStandard = standards.singleWhere(
        (standard) =>
            standard.sex == QualificationSex.male &&
            standard.ageGroupLabel == 'MC' &&
            standard.distance == 50 &&
            standard.stroke == 'Butterfly',
      );
      expect(mcStandard.mcPoints, 20);
      expect(mcStandard.qualifyingTime, isNull);
      expect(mcStandard.matchesAge(99), isTrue);

      final relayStandard = standards.singleWhere(
        (standard) =>
            standard.relayEvent == 'Freestyle Relay' &&
            standard.ageGroupLabel == '13 / Under',
      );
      expect(relayStandard.isRelay, isTrue);
      expect(relayStandard.qualifyingCentiseconds, 13000);
      expect(relayStandard.matchesAge(13), isTrue);
      expect(relayStandard.matchesAge(14), isFalse);

      final paraRelayStandard = standards.singleWhere(
        (standard) =>
            standard.relayEvent == 'Medley Relay' &&
            standard.ageGroupLabel == 'Open Para Able Bodied',
      );
      expect(paraRelayStandard.hasQualifyingTime, isFalse);
      expect(paraRelayStandard.matchesAge(10), isTrue);
    });
  });
}
