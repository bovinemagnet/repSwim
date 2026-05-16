import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profiles/presentation/providers/profile_providers.dart';
import '../../../race/presentation/providers/race_time_providers.dart';
import '../../../swim/presentation/providers/swim_providers.dart';
import '../../domain/entities/coach_report.dart';
import '../../domain/services/coach_report_builder.dart';
import 'coach_providers.dart';

/// Wires [CoachReportBuilder] to the real DAOs.
final coachReportBuilderProvider = Provider<CoachReportBuilder>((ref) {
  return CoachReportBuilder(
    profileDao: ref.read(profileDaoProvider),
    sessionDao: ref.read(swimSessionDaoProvider),
    raceTimeDao: ref.read(raceTimeDaoProvider),
    pbDao: ref.read(pbDaoProvider),
    drylandDao: ref.read(drylandDaoProvider),
  );
});

/// Builds a [CoachReport] for the given profile id.
///
/// Reads the profile's [CoachShare] from the DAO and assembles the report via
/// [CoachReportBuilder].  autoDispose ensures a fresh report is built every
/// time the coach view is opened, preventing stale data after sharing settings
/// change.
final coachReportProvider = FutureProvider.autoDispose
    .family<CoachReport, String>((ref, profileId) async {
  final share = await ref.read(coachShareDaoProvider).getForProfile(profileId);
  final builder = ref.read(coachReportBuilderProvider);
  return builder.build(profileId, share);
});
