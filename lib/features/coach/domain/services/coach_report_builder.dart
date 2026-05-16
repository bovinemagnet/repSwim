import '../../../../database/daos/dryland_dao.dart';
import '../../../../database/daos/pb_dao.dart';
import '../../../../database/daos/profile_dao.dart';
import '../../../../database/daos/race_time_dao.dart';
import '../../../../database/daos/swim_session_dao.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../dryland/domain/entities/dryland_workout.dart';
import '../../../pb/domain/entities/personal_best.dart';
import '../../../profiles/domain/entities/swimmer_profile.dart';
import '../../../race/domain/entities/race_time.dart';
import '../../../swim/domain/entities/swim_session.dart';
import '../entities/coach_report.dart';
import '../entities/coach_share.dart';
import '../entities/coach_share_category.dart';

/// Assembles a [CoachReport] for a given profile by loading only the data
/// categories that the [CoachShare] has enabled.
///
/// Every DAO call is scoped to [profileId] so no cross-profile data leaks.
class CoachReportBuilder {
  const CoachReportBuilder({
    required this.profileDao,
    required this.sessionDao,
    required this.raceTimeDao,
    required this.pbDao,
    required this.drylandDao,
  });

  final ProfileDao profileDao;
  final SwimSessionDao sessionDao;
  final RaceTimeDao raceTimeDao;
  final PbDao pbDao;
  final DrylandDao drylandDao;

  /// Builds a [CoachReport] for [profileId] respecting the [share] settings.
  ///
  /// Only categories present in [share.activeCategories] are loaded.
  /// Returns an empty [CoachReport] (no data fields populated) when [share]
  /// is disabled.
  Future<CoachReport> build(String profileId, CoachShare share) async {
    // Resolve the swimmer profile; fall back to the default if not found.
    final allProfiles = await profileDao.getAll();
    final SwimmerProfile profile = allProfiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => SwimmerProfile.defaultProfile,
    );

    final categories = share.activeCategories;

    // Load data for each active category, keeping other fields null.
    List<SwimSession>? swimSessions;
    List<RaceTime>? raceTimes;
    List<PersonalBest>? personalBests;
    List<DrylandWorkout>? drylandWorkouts;
    AnalyticsData? analytics;

    if (categories.contains(CoachShareCategory.swimSessions)) {
      swimSessions = await sessionDao.getAllSessions(profileId);
    }

    if (categories.contains(CoachShareCategory.raceTimes)) {
      raceTimes = await raceTimeDao.getAll(profileId);
    }

    if (categories.contains(CoachShareCategory.personalBests)) {
      personalBests = await pbDao.getAll(profileId);
    }

    if (categories.contains(CoachShareCategory.dryland)) {
      drylandWorkouts = await drylandDao.getAll(profileId);
    }

    if (categories.contains(CoachShareCategory.analytics)) {
      // Ensure the sessions and PBs used for analytics are scoped to this
      // profile, loading them here if they were not already requested.
      final sessions =
          swimSessions ?? await sessionDao.getAllSessions(profileId);
      final pbs = personalBests ?? await pbDao.getAll(profileId);
      analytics = computeAnalytics(sessions, pbs);
    }

    return CoachReport(
      profile: profile,
      includedCategories: categories,
      swimSessions: swimSessions,
      raceTimes: raceTimes,
      personalBests: personalBests,
      drylandWorkouts: drylandWorkouts,
      analytics: analytics,
    );
  }
}
