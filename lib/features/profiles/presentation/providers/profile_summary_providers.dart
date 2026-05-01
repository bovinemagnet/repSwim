import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../swim/presentation/providers/swim_providers.dart';

class ProfileSummary {
  const ProfileSummary({
    required this.sessionCount,
    required this.totalDistance,
    required this.drylandWorkoutCount,
    required this.personalBestCount,
  });

  final int sessionCount;
  final int totalDistance;
  final int drylandWorkoutCount;
  final int personalBestCount;
}

final profileSummaryProvider =
    FutureProvider.autoDispose.family<ProfileSummary, String>(
  (ref, profileId) async {
    final sessions =
        await ref.read(swimRepositoryProvider).getAllSessions(profileId);
    final dryland = await ref.read(drylandDaoProvider).getAll(profileId);
    final pbs = await ref.read(pbDaoProvider).getAll(profileId);

    return ProfileSummary(
      sessionCount: sessions.length,
      totalDistance: sessions.fold<int>(
        0,
        (total, session) => total + session.totalDistance,
      ),
      drylandWorkoutCount: dryland.length,
      personalBestCount: pbs.length,
    );
  },
);
