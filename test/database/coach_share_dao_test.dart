import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';
import 'package:rep_swim/database/daos/coach_share_dao.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share.dart';
import 'package:rep_swim/features/coach/domain/entities/coach_share_category.dart';

void main() {
  late AppDatabase db;
  late CoachShareDao dao;

  setUp(() {
    db = AppDatabase.test();
    dao = CoachShareDao(db);
  });

  tearDown(() => db.close());

  test('getForProfile returns a disabled default when no row exists', () async {
    final share = await dao.getForProfile('local-default-profile');
    expect(share.profileId, 'local-default-profile');
    expect(share.enabled, isFalse);
    expect(share.sharedCategories, isEmpty);
  });

  test('save then getForProfile round-trips enabled state and categories',
      () async {
    const share = CoachShare(
      profileId: 'local-default-profile',
      enabled: true,
      sharedCategories: {
        CoachShareCategory.goals,
        CoachShareCategory.swimSessions,
      },
    );
    await dao.save(share);

    final loaded = await dao.getForProfile('local-default-profile');
    expect(loaded.enabled, isTrue);
    expect(loaded.sharedCategories, {
      CoachShareCategory.goals,
      CoachShareCategory.swimSessions,
    });
  });

  test('save overwrites a previous configuration', () async {
    await dao.save(const CoachShare(
      profileId: 'local-default-profile',
      enabled: true,
      sharedCategories: {CoachShareCategory.notes},
    ));
    await dao.save(const CoachShare(
      profileId: 'local-default-profile',
      enabled: false,
    ));
    final loaded = await dao.getForProfile('local-default-profile');
    expect(loaded.enabled, isFalse);
    expect(loaded.sharedCategories, isEmpty);
  });

  test('getSharedProfileIds lists only profiles with active sharing', () async {
    await dao.save(const CoachShare(
      profileId: 'local-default-profile',
      enabled: true,
      sharedCategories: {CoachShareCategory.goals},
    ));
    final ids = await dao.getSharedProfileIds();
    expect(ids, contains('local-default-profile'));
  });

  test('unknown category keys in storage are ignored on read', () async {
    final database = await db.database;
    await database.insert('coach_shares', {
      'profile_id': 'local-default-profile',
      'enabled': 1,
      'shared_categories_json': '["goals","bogus_category"]',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    final loaded = await dao.getForProfile('local-default-profile');
    expect(loaded.sharedCategories, {CoachShareCategory.goals});
  });
}
