/// A category of swimmer data that can be shared with a coach.
///
/// [key] is the stable identifier persisted in the database; [label] is the
/// human-readable name shown in the UI.
enum CoachShareCategory {
  profileDetails('profile_details', 'Profile details'),
  goals('goals', 'Goals'),
  notes('notes', 'Notes'),
  swimSessions('swim_sessions', 'Swim sessions'),
  raceTimes('race_times', 'Race times'),
  personalBests('personal_bests', 'Personal bests'),
  analytics('analytics', 'Analytics'),
  dryland('dryland', 'Dryland training');

  const CoachShareCategory(this.key, this.label);

  final String key;
  final String label;

  /// Returns the category with the given [key], or null if none matches.
  static CoachShareCategory? fromKey(String key) {
    for (final category in values) {
      if (category.key == key) return category;
    }
    return null;
  }
}
