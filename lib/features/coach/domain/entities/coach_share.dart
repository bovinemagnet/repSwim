import 'coach_share_category.dart';

/// The coach-sharing configuration for a single swimmer profile.
///
/// Sharing is opt-in: nothing is shared unless [enabled] is true *and* the
/// category is present in [sharedCategories].
class CoachShare {
  const CoachShare({
    required this.profileId,
    this.enabled = false,
    this.sharedCategories = const {},
  });

  final String profileId;
  final bool enabled;
  final Set<CoachShareCategory> sharedCategories;

  /// Whether [category] is actually shared (master flag on and ticked).
  bool isShared(CoachShareCategory category) =>
      enabled && sharedCategories.contains(category);

  /// The categories actually shared right now — empty when [enabled] is false.
  Set<CoachShareCategory> get activeCategories =>
      enabled ? Set.unmodifiable(sharedCategories) : const {};

  /// True when this profile shares at least one category with a coach.
  bool get hasActiveSharing => enabled && sharedCategories.isNotEmpty;

  CoachShare withCategory(CoachShareCategory category) => copyWith(
        sharedCategories: {...sharedCategories, category},
      );

  CoachShare withoutCategory(CoachShareCategory category) => copyWith(
        sharedCategories: {...sharedCategories}..remove(category),
      );

  CoachShare copyWith({
    bool? enabled,
    Set<CoachShareCategory>? sharedCategories,
  }) {
    return CoachShare(
      profileId: profileId,
      enabled: enabled ?? this.enabled,
      sharedCategories: sharedCategories ?? this.sharedCategories,
    );
  }
}
