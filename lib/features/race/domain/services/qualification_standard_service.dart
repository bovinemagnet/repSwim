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

List<QualificationStandard> sortQualificationStandards(
  List<QualificationStandard> standards,
) {
  final sorted = [...standards];
  sorted.sort((a, b) {
    final ageCompare = a.age.compareTo(b.age);
    if (ageCompare != 0) return ageCompare;
    final distanceCompare = a.distance.compareTo(b.distance);
    if (distanceCompare != 0) return distanceCompare;
    final strokeCompare = a.stroke.toLowerCase().compareTo(
          b.stroke.toLowerCase(),
        );
    if (strokeCompare != 0) return strokeCompare;
    return a.course.index.compareTo(b.course.index);
  });
  return sorted;
}

List<int> qualificationAges(List<QualificationStandard> standards) {
  final ages = standards.map((standard) => standard.age).toSet().toList()
    ..sort();
  return ages;
}

Map<int, List<QualificationStandard>> qualificationStandardsByAge(
  List<QualificationStandard> standards,
) {
  final grouped = <int, List<QualificationStandard>>{};
  for (final standard in sortQualificationStandards(standards)) {
    grouped.putIfAbsent(standard.age, () => []).add(standard);
  }
  return grouped;
}

List<QualificationStandard> qualificationStandardsForAge(
  List<QualificationStandard> standards,
  int age,
) {
  return sortQualificationStandards(
    standards.where((standard) => standard.age == age).toList(),
  );
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
