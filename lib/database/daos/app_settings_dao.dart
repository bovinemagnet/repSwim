import 'package:sqflite/sqflite.dart';

import '../app_database.dart';

class AppSettingsDao {
  const AppSettingsDao(this._db);

  final AppDatabase _db;

  Future<String?> getString(String key) async {
    final db = await _db.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.single['value'] as String;
  }

  Future<void> setString(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
