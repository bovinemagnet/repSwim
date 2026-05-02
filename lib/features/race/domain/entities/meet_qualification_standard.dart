import 'race_time.dart';

enum QualificationSex {
  male('Male'),
  female('Female');

  const QualificationSex(this.label);

  final String label;
}

class MeetQualificationStandard {
  const MeetQualificationStandard({
    required this.id,
    required this.sourceName,
    required this.ageGroupLabel,
    required this.course,
    required this.validFrom,
    required this.competitionStart,
    required this.competitionEnd,
    required this.isRelay,
    this.sex,
    this.minAge,
    this.maxAge,
    this.isOpen = false,
    this.distance,
    this.stroke,
    this.qualifyingTime,
    this.mcPoints,
    this.relayEvent,
  });

  final String id;
  final String sourceName;
  final QualificationSex? sex;
  final String ageGroupLabel;
  final int? minAge;
  final int? maxAge;
  final bool isOpen;
  final int? distance;
  final String? stroke;
  final RaceCourse course;
  final Duration? qualifyingTime;
  final int? mcPoints;
  final bool isRelay;
  final String? relayEvent;
  final DateTime validFrom;
  final DateTime competitionStart;
  final DateTime competitionEnd;

  int? get qualifyingCentiseconds {
    final time = qualifyingTime;
    if (time == null) return null;
    return (time.inMilliseconds / 10).round();
  }

  bool get hasQualifyingTime => qualifyingTime != null;

  bool matchesAge(int age) {
    if (isOpen) return true;
    final min = minAge;
    final max = maxAge;
    if (min != null && age < min) return false;
    if (max != null && age > max) return false;
    return min != null || max != null;
  }
}
