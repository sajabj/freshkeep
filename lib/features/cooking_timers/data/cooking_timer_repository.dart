import 'package:sqflite/sqflite.dart';

import '../domain/cooking_timer.dart';

class CookingTimerRepository {
  CookingTimerRepository(this.db);
  final Database db;
  Future<List<CookingTimer>> load(DateTime now) async {
    await db.update(
      'cooking_timers',
      {'state': 'finished', 'remaining_seconds': 0, 'end_at': null},
      where: "state='running' AND end_at<=?",
      whereArgs: [now.toUtc().toIso8601String()],
    );
    return (await db.query(
      'cooking_timers',
      orderBy: "CASE state WHEN 'running' THEN 0 WHEN 'paused' THEN 1 ELSE 2 END, created_at DESC",
    )).map(CookingTimer.fromMap).toList();
  }

  Future<CookingTimer> create(
    String id,
    String name,
    int seconds,
    DateTime now,
  ) async {
    await db.insert('cooking_timers', {
      'id': id,
      'name': name.trim(),
      'duration_seconds': seconds,
      'remaining_seconds': seconds,
      'end_at': null,
      'state': 'paused',
      'notified': 0,
      'created_at': now.toUtc().toIso8601String(),
      'updated_at': now.toUtc().toIso8601String(),
    });
    return CookingTimer.fromMap(
      (await db.query('cooking_timers', where: 'id=?', whereArgs: [id])).single,
    );
  }

  Future<void> update(CookingTimer timer) => db.update(
    'cooking_timers',
    timer.toMap()
      ..remove('notification_id')
      ..remove('id')
      ..remove('created_at'),
    where: 'id=?',
    whereArgs: [timer.id],
  );
  Future<void> delete(String id) =>
      db.delete('cooking_timers', where: 'id=?', whereArgs: [id]);
}
