import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../features/profiles/domain/entities/swimmer_profile.dart';
import '../app_database.dart';

class ProfileDao {
  const ProfileDao(this._db);

  final AppDatabase _db;

  Future<void> ensureDefaultProfile() async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.insert(
      'swimmer_profiles',
      {
        'id': kDefaultProfileId,
        'display_name': kDefaultProfileName,
        'preferred_pool_length_meters': 25,
        'photo_uri': null,
        'preferred_strokes_json': '[]',
        'primary_events': null,
        'club_name': null,
        'goals': null,
        'notes': null,
        'created_at': now,
        'updated_at': now,
        'deleted_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<SwimmerProfile>> getAll() async {
    final db = await _db.database;
    await ensureDefaultProfile();
    final rows = await db.query(
      'swimmer_profiles',
      where: 'deleted_at IS NULL',
      orderBy: 'display_name ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> insert(SwimmerProfile profile) async {
    final db = await _db.database;
    await db.insert(
      'swimmer_profiles',
      {
        'id': profile.id,
        'display_name': profile.displayName,
        'preferred_pool_length_meters': profile.preferredPoolLengthMeters,
        'photo_uri': profile.photoUri,
        'preferred_strokes_json': jsonEncode(profile.preferredStrokes),
        'primary_events': profile.primaryEvents,
        'club_name': profile.clubName,
        'goals': profile.goals,
        'notes': profile.notes,
        'created_at': profile.createdAt.millisecondsSinceEpoch,
        'updated_at': profile.updatedAt.millisecondsSinceEpoch,
        'deleted_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(SwimmerProfile profile) async {
    final db = await _db.database;
    await db.update(
      'swimmer_profiles',
      {
        'display_name': profile.displayName,
        'preferred_pool_length_meters': profile.preferredPoolLengthMeters,
        'photo_uri': profile.photoUri,
        'preferred_strokes_json': jsonEncode(profile.preferredStrokes),
        'primary_events': profile.primaryEvents,
        'club_name': profile.clubName,
        'goals': profile.goals,
        'notes': profile.notes,
        'updated_at': profile.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [profile.id],
    );
  }

  Future<void> archive(String id) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.update(
      'swimmer_profiles',
      {
        'updated_at': now,
        'deleted_at': now,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  SwimmerProfile _fromRow(Map<String, Object?> row) {
    return SwimmerProfile(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      preferredPoolLengthMeters: row['preferred_pool_length_meters'] as int,
      photoUri: row['photo_uri'] as String?,
      preferredStrokes:
          _decodePreferredStrokes(row['preferred_strokes_json'] as String?),
      primaryEvents: row['primary_events'] as String?,
      clubName: row['club_name'] as String?,
      goals: row['goals'] as String?,
      notes: row['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  List<String> _decodePreferredStrokes(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().toList();
    } on FormatException {
      return const [];
    }
  }
}
