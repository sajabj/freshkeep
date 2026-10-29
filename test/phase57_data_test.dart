import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/meal_planner/data/meal_plan_repository.dart';
import 'package:freshkeep/features/meal_planner/domain/meal_plan.dart';
import 'package:freshkeep/features/recipes/domain/recipe.dart';
import 'package:freshkeep/features/settings/data/personal_data_store.dart';
import 'package:freshkeep/features/storage_guide/domain/storage_food.dart';
import 'package:freshkeep/features/storage_guide/data/storage_guide_repository.dart';

import 'support/food_fixture.dart';

Recipe recipe() => Recipe({
  'id': 'stable-recipe',
  'ar': 'وصفة',
  'en': 'Recipe',
  'minutes': 10,
  'servings': 2,
  'category': 'main',
  'art': 'x',
  'ingredients': [
    {
      'key': 'milk',
      'ar': 'حليب',
      'en': 'Milk',
      'aliases': ['milk', 'حليب'],
      'amount': 500,
      'unit': 'ml',
    },
  ],
  'stepsAr': ['خطوة'],
  'stepsEn': ['Step'],
});
MealPlanEntry plan(
  String id,
  DateTime date,
  MealSlot slot, {
  double servings = 2,
}) => MealPlanEntry(
  id: id,
  date: date,
  slot: slot,
  recipeId: 'stable-recipe',
  servings: servings,
  createdAt: date,
  updatedAt: date,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'v4 to v5 migration preserves inventory and adds meal planner',
    () async {
      final dir = await Directory.systemTemp.createTemp('freshkeep57');
      final path = '${dir.path}/db.sqlite';
      var db = await LocalDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: path,
        targetVersion: 4,
      );
      await db.insert('food_items', foodFixture(id: 'kept').toMap());
      await db.close();
      db = await LocalDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: path,
      );
      expect(await db.getVersion(), 7);
      expect((await db.query('food_items')).single['id'], 'kept');
      await MealPlanRepository(db)
          .save(plan('p', DateTime(2026, 10, 20), MealSlot.dinner));
      expect(
        await MealPlanRepository(db).load(DateTime(2026, 10, 19)),
        hasLength(1),
      );
      await db.close();
      await dir.delete(recursive: true);
    },
  );
  test('week boundary honors requested locale first day', () {
    expect(
      weekStart(DateTime(2026, 10, 21), DateTime.monday),
      DateTime(2026, 10, 19),
    );
    expect(weekStart(DateTime(2026, 10, 21), 0), DateTime(2026, 10, 18));
  });
  test(
    'weekly demand aggregates compatible units and allocates stock once',
    () {
      final milk = FoodItem.fromMap({
        ...foodFixture(id: 'milk', name: 'Milk', quantity: 0.75).toMap(),
        'unit': 'l',
      });
      final req = weeklyRequirements(
        [
          plan('a', DateTime(2026, 10, 19), MealSlot.breakfast),
          plan('b', DateTime(2026, 10, 20), MealSlot.breakfast),
        ],
        [recipe()],
        [milk],
        DateTime(2026, 10, 18),
      ).single;
      expect(req.amount, 1000);
      expect(req.stock, 750);
      expect(req.missing, 250);
    },
  );
  test('incompatible stock is not merged and uncertainty is explicit', () {
    final milk = FoodItem.fromMap({
      ...foodFixture(id: 'milk', name: 'Milk', quantity: 1).toMap(),
      'unit': 'pcs',
    });
    final req = weeklyRequirements(
      [plan('a', DateTime(2026, 10, 19), MealSlot.breakfast)],
      [recipe()],
      [milk],
      DateTime(2026, 10, 18),
    ).single;
    expect(req.stock, 0);
    expect(req.missing, 500);
    expect(req.uncertain, isTrue);
  });
  test('expired inventory is excluded from weekly availability', () {
    final milk = FoodItem.fromMap({
      ...foodFixture(
        id: 'milk',
        name: 'Milk',
        quantity: 500,
        expiry: DateTime(2026, 10, 17),
      ).toMap(),
      'unit': 'ml',
    });
    expect(
      weeklyRequirements(
        [plan('a', DateTime(2026, 10, 19), MealSlot.breakfast)],
        [recipe()],
        [milk],
        DateTime(2026, 10, 18),
      ).single.stock,
      0,
    );
  });
  test('storage matching is exact, bilingual, and refuses partial names', () {
    final apple = StorageFood.fromJson({
      'id': 'apple',
      'name': {'ar': 'تفاح', 'en': 'Apple'},
      'aliases': ['apples', 'تفاحة'],
      'category': 'fruit',
      'location': {'ar': 'ثلاجة', 'en': 'Fridge'},
      'tips': [
        {'ar': 'نصيحة', 'en': 'Tip'},
      ],
      'freezing': {'ar': 'نعم', 'en': 'Yes'},
      'mistakes': {'ar': 'خطأ', 'en': 'Mistake'},
      'opened': {'ar': 'برد', 'en': 'Chill'},
      'safety': false,
      'sources': ['FDA'],
    });
    expect(exactStorageMatch([apple], 'تفاحة'), same(apple));
    expect(exactStorageMatch([apple], 'Apple juice'), isNull);
  });
  test('bundled storage guide is bilingual, sourced and broad', () async {
    final foods = await StorageGuideRepository().load();
    expect(foods.length, greaterThanOrEqualTo(20));
    expect(
      foods.every(
        (f) =>
            f.name.ar.isNotEmpty &&
            f.name.en.isNotEmpty &&
            f.sourceIds.isNotEmpty,
      ),
      isTrue,
    );
    expect(exactStorageMatch(foods, 'Milk')?.id, 'milk');
    expect(exactStorageMatch(foods, 'حليب')?.id, 'milk');
  });
  test(
    'meal plan can be changed and removed without changing recipe id',
    () async {
      final db = await LocalDatabase.open(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      );
      final repo = MealPlanRepository(db);
      final day = DateTime(2026, 10, 20);
      await repo.save(plan('one', day, MealSlot.lunch));
      await repo.save(plan('one', day, MealSlot.lunch, servings: 4));
      expect((await repo.load(DateTime(2026, 10, 19))).single.servings, 4);
      expect(
        (await repo.load(DateTime(2026, 10, 19))).single.recipeId,
        'stable-recipe',
      );
      await repo.remove(day, MealSlot.lunch);
      expect(await repo.load(DateTime(2026, 10, 19)), isEmpty);
      await db.close();
    },
  );
  test('delete and export include meal plans safely', () async {
    final db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    await MealPlanRepository(db)
        .save(plan('p', DateTime(2026, 10, 20), MealSlot.lunch));
    expect(
      await PersonalDataStore(db).export(DateTime(2026, 10, 21)),
      contains('meal_plans'),
    );
    await PersonalDataStore(db).deleteRecords();
    expect(await db.query('meal_plans'), isEmpty);
    await db.close();
  });
}
