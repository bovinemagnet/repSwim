import '../../../../core/constants/app_constants.dart';

enum RaceCourse {
  shortCourseMeters('SCM', 'Short course meters'),
  shortCourseYards('SCY', 'Short course yards'),
  longCourseMeters('LCM', 'Long course meters');

  const RaceCourse(this.code, this.label);

  final String code;
  final String label;
}

class RaceTime {
  const RaceTime({
    required this.id,
    required this.raceName,
    required this.eventDate,
    required this.distance,
    required this.stroke,
    required this.course,
    required this.time,
    required this.createdAt,
    required this.updatedAt,
    this.profileId = kDefaultProfileId,
    this.notes,
    this.placement,
    this.location,
  });

  final String id;
  final String profileId;
  final String raceName;
  final DateTime eventDate;
  final int distance;
  final String stroke;
  final RaceCourse course;
  final Duration time;
  final String? notes;
  final int? placement;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get timeCentiseconds => (time.inMilliseconds / 10).round();

  RaceTime copyWith({
    String? id,
    String? profileId,
    String? raceName,
    DateTime? eventDate,
    int? distance,
    String? stroke,
    RaceCourse? course,
    Duration? time,
    String? notes,
    bool clearNotes = false,
    int? placement,
    bool clearPlacement = false,
    String? location,
    bool clearLocation = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RaceTime(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      raceName: raceName ?? this.raceName,
      eventDate: eventDate ?? this.eventDate,
      distance: distance ?? this.distance,
      stroke: stroke ?? this.stroke,
      course: course ?? this.course,
      time: time ?? this.time,
      notes: clearNotes ? null : notes ?? this.notes,
      placement: clearPlacement ? null : placement ?? this.placement,
      location: clearLocation ? null : location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
