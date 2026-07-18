import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/core/constants/app_constants.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/coach_share_dao.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';
import 'package:rep_swim/features/coach/presentation/providers/coach_providers.dart';

void main() {
  test('CoachShareController loads, toggles, and persists a profile share',
      () async {
    final db = AppDatabase.test();
    addTearDown(db.close);
    final dao = CoachShareDao(db);

    final container = ProviderContainer(overrides: [
      coachShareDaoProvider.overrideWithValue(dao),
    ]);
    addTearDown(container.dispose);

    final controller = container
        .read(coachShareControllerProvider(kDefaultProfileId).notifier);
    await controller.future;

    await controller.setEnabled(true);
    await controller.setCategory(CoachShareCategory.goals, true);

    final reloaded = await dao.getForProfile(kDefaultProfileId);
    expect(reloaded.enabled, isTrue);
    expect(reloaded.isShared(CoachShareCategory.goals), isTrue);
  });

  test('stopSharing disables sharing for the profile', () async {
    final db = AppDatabase.test();
    addTearDown(db.close);
    final dao = CoachShareDao(db);
    await dao.save(const CoachShare(
      profileId: kDefaultProfileId,
      enabled: true,
      sharedCategories: {CoachShareCategory.notes},
    ));

    final container = ProviderContainer(overrides: [
      coachShareDaoProvider.overrideWithValue(dao),
    ]);
    addTearDown(container.dispose);

    final controller = container
        .read(coachShareControllerProvider(kDefaultProfileId).notifier);
    await controller.future;
    await controller.stopSharing();

    expect((await dao.getForProfile(kDefaultProfileId)).enabled, isFalse);
  });
}
