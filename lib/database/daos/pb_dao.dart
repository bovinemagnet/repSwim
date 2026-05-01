import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../features/pb/domain/entities/personal_best.dart';

class PbDao {
  const PbDao(this._db);

  final AppDatabase _db;

  Future<void> insertOrUpdate(PersonalBest pb) async {
    final db = await _db.database;
    await db.insert(
      'personal_bests',
      {
        'id': pb.id,
        'stroke': pb.stroke,
        'distance': pb.distance,
        'best_time_seconds': pb.bestTime.inSeconds,
        'achieved_at': pb.achievedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PersonalBest>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('personal_bests', orderBy: 'stroke ASC, distance ASC');
    return rows
        .map((r) => PersonalBest(
              id: r['id'] as String,
              stroke: r['stroke'] as String,
              distance: r['distance'] as int,
              bestTime: Duration(seconds: r['best_time_seconds'] as int),
              achievedAt:
                  DateTime.fromMillisecondsSinceEpoch(r['achieved_at'] as int),
            ))
        .toList();
  }

  Future<PersonalBest?> getForStrokeAndDistance(
      String stroke, int distance) async {
    final db = await _db.database;
    final rows = await db.query(
      'personal_bests',
      where: 'stroke = ? AND distance = ?',
      whereArgs: [stroke, distance],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return PersonalBest(
      id: r['id'] as String,
      stroke: r['stroke'] as String,
      distance: r['distance'] as int,
      bestTime: Duration(seconds: r['best_time_seconds'] as int),
      achievedAt:
          DateTime.fromMillisecondsSinceEpoch(r['achieved_at'] as int),
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('personal_bests', where: 'id = ?', whereArgs: [id]);
  }
}
