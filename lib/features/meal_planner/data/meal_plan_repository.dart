import 'package:sqflite/sqflite.dart';

import '../domain/meal_plan.dart';

class MealPlanRepository {
  MealPlanRepository(this.db);
  final Database db;
  Future<List<MealPlanEntry>> load(DateTime start) async {
    final end = start.add(const Duration(days: 7));
    return (await db.query(
      'meal_plans',
      where: 'meal_date>=? AND meal_date<?',
      whereArgs: [_date(start), _date(end)],
      orderBy: 'meal_date, slot',
    )).map(MealPlanEntry.fromMap).toList();
  }

  Future<void> save(MealPlanEntry entry) => db.insert(
    'meal_plans',
    entry.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  Future<void> remove(DateTime date, MealSlot slot) => db.delete(
    'meal_plans',
    where: 'meal_date=? AND slot=?',
    whereArgs: [_date(date), slot.name],
  );
  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
