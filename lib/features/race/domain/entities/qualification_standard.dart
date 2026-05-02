import 'race_time.dart';

enum QualificationTier {
  gold('Gold'),
  silver('Silver'),
  bronze('Bronze');

  const QualificationTier(this.label);

  final String label;
}

class QualificationStandard {
  const QualificationStandard({
    required this.id,
    required this.profileId,
    required this.age,
    required this.distance,
    required this.stroke,
    required this.course,
    required this.goldTime,
    required this.silverTime,
    required this.bronzeTime,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final int age;
  final int distance;
  final String stroke;
  final RaceCourse course;
  final Duration goldTime;
  final Duration silverTime;
  final Duration bronzeTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get goldCentiseconds => (goldTime.inMilliseconds / 10).round();
  int get silverCentiseconds => (silverTime.inMilliseconds / 10).round();
  int get bronzeCentiseconds => (bronzeTime.inMilliseconds / 10).round();

  QualificationStandard copyWith({
    String? id,
    String? profileId,
    int? age,
    int? distance,
    String? stroke,
    RaceCourse? course,
    Duration? goldTime,
    Duration? silverTime,
    Duration? bronzeTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QualificationStandard(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      age: age ?? this.age,
      distance: distance ?? this.distance,
      stroke: stroke ?? this.stroke,
      course: course ?? this.course,
      goldTime: goldTime ?? this.goldTime,
      silverTime: silverTime ?? this.silverTime,
      bronzeTime: bronzeTime ?? this.bronzeTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
