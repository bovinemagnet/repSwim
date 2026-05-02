import '../../../../core/constants/app_constants.dart';

class SwimmerProfile {
  SwimmerProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.preferredPoolLengthMeters = 25,
    this.photoUri,
    List<String> preferredStrokes = const [],
    this.primaryEvents,
    this.clubName,
    this.goals,
    this.notes,
  }) : preferredStrokes = List.unmodifiable(preferredStrokes);

  final String id;
  final String displayName;
  final int preferredPoolLengthMeters;
  final String? photoUri;
  final List<String> preferredStrokes;
  final String? primaryEvents;
  final String? clubName;
  final String? goals;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static final defaultProfile = SwimmerProfile(
    id: kDefaultProfileId,
    displayName: kDefaultProfileName,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  SwimmerProfile copyWith({
    String? id,
    String? displayName,
    int? preferredPoolLengthMeters,
    String? photoUri,
    List<String>? preferredStrokes,
    String? primaryEvents,
    String? clubName,
    String? goals,
    String? notes,
    bool clearPhotoUri = false,
    bool clearPrimaryEvents = false,
    bool clearClubName = false,
    bool clearGoals = false,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SwimmerProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      preferredPoolLengthMeters:
          preferredPoolLengthMeters ?? this.preferredPoolLengthMeters,
      photoUri: clearPhotoUri ? null : photoUri ?? this.photoUri,
      preferredStrokes: preferredStrokes ?? this.preferredStrokes,
      primaryEvents:
          clearPrimaryEvents ? null : primaryEvents ?? this.primaryEvents,
      clubName: clearClubName ? null : clubName ?? this.clubName,
      goals: clearGoals ? null : goals ?? this.goals,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
