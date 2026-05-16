import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../dryland/domain/entities/dryland_workout.dart';
import '../../../pb/domain/entities/personal_best.dart';
import '../../../profiles/domain/entities/swimmer_profile.dart';
import '../../../race/domain/entities/race_time.dart';
import '../../../swim/domain/entities/swim_session.dart';
import 'coach_share_category.dart';

/// An immutable snapshot of a swimmer's shared data assembled for a coach.
///
/// Fields backed by data are nullable: a null value indicates that category
/// was not included in this report. The [includedCategories] set is the
/// authoritative record of what was requested; use [includes] to query it.
///
/// [profileDetails], [goals], and [notes] carry no dedicated field because
/// they are already present on [profile]; they are tracked only via
/// [includedCategories].
class CoachReport {
  const CoachReport({
    required this.profile,
    required this.includedCategories,
    this.swimSessions,
    this.raceTimes,
    this.personalBests,
    this.drylandWorkouts,
    this.analytics,
  });

  /// The swimmer profile whose data this report covers.
  final SwimmerProfile profile;

  /// The set of categories that were active when this report was built.
  final Set<CoachShareCategory> includedCategories;

  /// Swim sessions shared with the coach, or null if not included.
  final List<SwimSession>? swimSessions;

  /// Race times shared with the coach, or null if not included.
  final List<RaceTime>? raceTimes;

  /// Personal bests shared with the coach, or null if not included.
  final List<PersonalBest>? personalBests;

  /// Dryland workouts shared with the coach, or null if not included.
  final List<DrylandWorkout>? drylandWorkouts;

  /// Computed analytics shared with the coach, or null if not included.
  final AnalyticsData? analytics;

  /// Returns true when [category] is part of this report.
  bool includes(CoachShareCategory category) =>
      includedCategories.contains(category);
}
