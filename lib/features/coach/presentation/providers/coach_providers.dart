import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../database/daos/coach_share_dao.dart';
import '../../domain/entities/coach_share.dart';
import '../../domain/entities/coach_share_category.dart';

/// DAO for coach-sharing configuration.
final coachShareDaoProvider = Provider<CoachShareDao>((ref) {
  return CoachShareDao(AppDatabase.instance);
});

/// IDs of profiles that currently share data with a coach.
final sharedProfileIdsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(coachShareDaoProvider).getSharedProfileIds();
});

/// Editable coach-sharing state for a single profile, keyed by profile id.
final coachShareControllerProvider =
    AsyncNotifierProvider.family<CoachShareController, CoachShare, String>(
        CoachShareController.new);

class CoachShareController extends FamilyAsyncNotifier<CoachShare, String> {
  @override
  Future<CoachShare> build(String profileId) {
    return ref.read(coachShareDaoProvider).getForProfile(profileId);
  }

  Future<void> _persist(CoachShare share) async {
    await ref.read(coachShareDaoProvider).save(share);
    state = AsyncData(share);
    ref.invalidate(sharedProfileIdsProvider);
  }

  /// Turns the master "share with coach" flag on or off.
  Future<void> setEnabled(bool enabled) async {
    final current = state.value ?? CoachShare(profileId: arg);
    await _persist(current.copyWith(enabled: enabled));
  }

  /// Adds or removes a single shared category.
  Future<void> setCategory(CoachShareCategory category, bool shared) async {
    final current = state.value ?? CoachShare(profileId: arg);
    await _persist(
      shared
          ? current.withCategory(category)
          : current.withoutCategory(category),
    );
  }

  /// Disables all sharing for this profile.
  Future<void> stopSharing() async {
    final current = state.value ?? CoachShare(profileId: arg);
    await _persist(current.copyWith(enabled: false));
  }
}
