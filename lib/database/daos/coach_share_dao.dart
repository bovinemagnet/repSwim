import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../features/coach/domain/entities/coach_share.dart';
import '../../features/coach/domain/entities/coach_share_category.dart';
import '../app_database.dart';

/// Persistence for per-profile coach-sharing configuration.
class CoachShareDao {
  const CoachShareDao(this._db);

  final AppDatabase _db;

  /// Returns the sharing configuration for [profileId]. A profile with no
  /// stored row yields a disabled [CoachShare] with no categories.
  Future<CoachShare> getForProfile(String profileId) async {
    final db = await _db.database;
    final rows = await db.query(
      'coach_shares',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (rows.isEmpty) return CoachShare(profileId: profileId);
    return _fromRow(rows.first);
  }

  /// Inserts or replaces the configuration for the share's profile.
  Future<void> save(CoachShare share) async {
    final db = await _db.database;
    await db.insert(
      'coach_shares',
      {
        'profile_id': share.profileId,
        'enabled': share.enabled ? 1 : 0,
        'shared_categories_json': jsonEncode(
          share.sharedCategories.map((c) => c.key).toList(),
        ),
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes any stored configuration for [profileId].
  Future<void> delete(String profileId) async {
    final db = await _db.database;
    await db.delete(
      'coach_shares',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );
  }

  /// IDs of profiles that currently share at least one category.
  Future<List<String>> getSharedProfileIds() async {
    final db = await _db.database;
    final rows = await db.query('coach_shares', where: 'enabled = 1');
    return rows
        .map(_fromRow)
        .where((share) => share.hasActiveSharing)
        .map((share) => share.profileId)
        .toList();
  }

  CoachShare _fromRow(Map<String, Object?> row) {
    return CoachShare(
      profileId: row['profile_id'] as String,
      enabled: (row['enabled'] as int) == 1,
      sharedCategories: _decodeCategories(
        row['shared_categories_json'] as String?,
      ),
    );
  }

  Set<CoachShareCategory> _decodeCategories(String? value) {
    if (value == null || value.isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const {};
      return decoded
          .whereType<String>()
          .map(CoachShareCategory.fromKey)
          .whereType<CoachShareCategory>()
          .toSet();
    } on FormatException {
      return const {};
    }
  }
}
