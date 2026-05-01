import '../../../../core/constants/app_constants.dart';

class SwimmerProfile {
  const SwimmerProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.preferredPoolLengthMeters = 25,
    this.notes,
  });

  final String id;
  final String displayName;
  final int preferredPoolLengthMeters;
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
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SwimmerProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      preferredPoolLengthMeters:
          preferredPoolLengthMeters ?? this.preferredPoolLengthMeters,
      notes: clearNotes ? null : notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
