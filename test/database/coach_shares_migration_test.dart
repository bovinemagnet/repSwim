import 'package:flutter_test/flutter_test.dart';
import 'package:rep_swim/database/app_database.dart';

void main() {
  test('coach_shares table exists with the expected columns', () async {
    final db = AppDatabase.test();
    final database = await db.database;

    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='coach_shares'",
    );
    expect(tables, hasLength(1), reason: 'coach_shares table must exist');

    final columns = await database.rawQuery('PRAGMA table_info(coach_shares)');
    final names = columns.map((row) => row['name'] as String).toSet();
    expect(names, containsAll(<String>[
      'profile_id',
      'enabled',
      'shared_categories_json',
      'updated_at',
    ]));

    await db.close();
  });
}
