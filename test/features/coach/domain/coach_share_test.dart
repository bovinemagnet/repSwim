import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';

void main() {
  group('CoachShare', () {
    test('a profile with no row is not sharing anything', () {
      const share = CoachShare(profileId: 'p1');
      expect(share.enabled, isFalse);
      expect(share.hasActiveSharing, isFalse);
      expect(share.isShared(CoachShareCategory.goals), isFalse);
    });

    test('isShared requires both the master flag and the category', () {
      const disabled = CoachShare(
        profileId: 'p1',
        sharedCategories: {CoachShareCategory.goals},
      );
      expect(disabled.isShared(CoachShareCategory.goals), isFalse,
          reason: 'master flag off means nothing is shared');

      const enabled = CoachShare(
        profileId: 'p1',
        enabled: true,
        sharedCategories: {CoachShareCategory.goals},
      );
      expect(enabled.isShared(CoachShareCategory.goals), isTrue);
      expect(enabled.isShared(CoachShareCategory.notes), isFalse);
    });

    test('withCategory and withoutCategory return updated copies', () {
      const base = CoachShare(profileId: 'p1', enabled: true);
      final added = base.withCategory(CoachShareCategory.notes);
      expect(added.sharedCategories, {CoachShareCategory.notes});
      expect(base.sharedCategories, isEmpty, reason: 'original unchanged');

      final removed = added.withoutCategory(CoachShareCategory.notes);
      expect(removed.sharedCategories, isEmpty);
    });

    test('activeCategories is empty when the master flag is off', () {
      const share = CoachShare(
        profileId: 'p1',
        sharedCategories: {CoachShareCategory.goals},
      );
      expect(share.activeCategories, isEmpty);
    });

    test('hasActiveSharing is true only when enabled with a category', () {
      const enabledNoCategories = CoachShare(profileId: 'p1', enabled: true);
      expect(enabledNoCategories.hasActiveSharing, isFalse);

      const enabledWithCategory = CoachShare(
        profileId: 'p1',
        enabled: true,
        sharedCategories: {CoachShareCategory.dryland},
      );
      expect(enabledWithCategory.hasActiveSharing, isTrue);
    });
  });
}
