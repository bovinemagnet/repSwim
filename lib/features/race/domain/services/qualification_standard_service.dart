import '../entities/qualification_standard.dart';
import '../entities/race_time.dart';

class QualificationResult {
  const QualificationResult({
    required this.standard,
    required this.tier,
    required this.margin,
  });

  final QualificationStandard standard;
  final QualificationTier tier;
  final Duration margin;
}

bool hasValidQualificationOrder(QualificationStandard standard) {
  return standard.goldTime > Duration.zero &&
      standard.silverTime > Duration.zero &&
      standard.bronzeTime > Duration.zero &&
      standard.goldTime <= standard.silverTime &&
      standard.silverTime <= standard.bronzeTime;
}

QualificationTier? qualificationTierForTime(
  QualificationStandard standard,
  Duration raceTime,
) {
  if (!hasValidQualificationOrder(standard)) return null;
  if (raceTime <= standard.goldTime) return QualificationTier.gold;
  if (raceTime <= standard.silverTime) return QualificationTier.silver;
  if (raceTime <= standard.bronzeTime) return QualificationTier.bronze;
  return null;
}

QualificationStandard? findQualificationStandard({
  required List<QualificationStandard> standards,
  required RaceTime raceTime,
  required int age,
}) {
  for (final standard in standards) {
    if (standard.profileId == raceTime.profileId &&
        standard.age == age &&
        standard.distance == raceTime.distance &&
        standard.stroke == raceTime.stroke &&
        standard.course == raceTime.course) {
      return standard;
    }
  }
  return null;
}

QualificationResult? qualificationResultForRace({
  required List<QualificationStandard> standards,
  required RaceTime raceTime,
  required int age,
}) {
  final standard = findQualificationStandard(
    standards: standards,
    raceTime: raceTime,
    age: age,
  );
  if (standard == null) return null;
  final tier = qualificationTierForTime(standard, raceTime.time);
  if (tier == null) return null;
  final threshold = switch (tier) {
    QualificationTier.gold => standard.goldTime,
    QualificationTier.silver => standard.silverTime,
    QualificationTier.bronze => standard.bronzeTime,
  };
  return QualificationResult(
    standard: standard,
    tier: tier,
    margin: threshold - raceTime.time,
  );
}
