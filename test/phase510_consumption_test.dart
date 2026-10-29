import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/consumption/data/consumption_repository.dart';
import 'package:freshkeep/features/consumption/domain/consumption.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/recipes/domain/recipe.dart';
import 'package:freshkeep/features/settings/data/personal_data_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/food_fixture.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late ConsumptionRepository repo;

  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    repo = ConsumptionRepository(db);
  });
  tearDown(() => db.close());

  ConsumptionRequest request(
    String id,
    List<ConsumptionAllocation> allocations, {
    ConsumptionKind kind = ConsumptionKind.manual,
    String? recipeId,
  }) => ConsumptionRequest(
    id: id,
    kind: kind,
    recipeId: recipeId,
    occurredAt: DateTime.utc(2026, 10, 21, 12),
    allocations: allocations,
  );

  test(
    'partial and full deduction preserve batch and update lifecycle',
    () async {
      await db.insert(
        'food_items',
        foodFixture(id: 'milk', quantity: 1000, unit: 'ml').toMap(),
      );
      await repo.apply(
        request('partial', const [
          ConsumptionAllocation(foodId: 'milk', amount: 250),
        ]),
      );
      var row = (await db.query('food_items')).single;
      expect(row['quantity'], 750);
      expect(row['status'], FoodStatus.available.name);
      expect(row['revision'], 1);

      await repo.apply(
        request('full', const [
          ConsumptionAllocation(foodId: 'milk', amount: 750),
        ]),
      );
      row = (await db.query('food_items')).single;
      expect(row['quantity'], 0);
      expect(row['status'], FoodStatus.used.name);
      expect(await db.query('consumption_operations'), hasLength(2));
      expect(await db.query('inventory_events'), hasLength(2));
    },
  );

  test('rejects invalid, excessive and repeated operation safely', () async {
    await db.insert('food_items', foodFixture(quantity: 5).toMap());
    expect(
      () => repo.apply(
        request('zero', const [
          ConsumptionAllocation(foodId: 'batch-1', amount: 0),
        ]),
      ),
      throwsA(isA<ConsumptionConflict>()),
    );
    expect(
      () => repo.apply(
        request('too-much', const [
          ConsumptionAllocation(foodId: 'batch-1', amount: 6),
        ]),
      ),
      throwsA(isA<ConsumptionConflict>()),
    );
    final valid = request('once', const [
      ConsumptionAllocation(foodId: 'batch-1', amount: 2),
    ]);
    await repo.apply(valid);
    expect(() => repo.apply(valid), throwsA(isA<ConsumptionConflict>()));
    expect((await db.query('food_items')).single['quantity'], 3);
  });

  test('trusted conversions work and volume to weight is refused', () {
    expect(convertAmount(1, 'kg', 'g'), 1000);
    expect(convertAmount(250, 'ml', 'l'), .25);
    expect(convertAmount(1, 'l', 'g'), isNull);
    expect(convertAmount(1, 'unknown', 'g'), isNull);
  });

  test('recipe suggestion scales servings and splits expiry-first batches', () {
    final ingredient = RecipeIngredient({
      'key': 'milk',
      'ar': 'حليب',
      'en': 'Milk',
      'amount': 750,
      'unit': 'ml',
      'aliases': <String>[],
    });
    final allocations = suggestAllocations(
      ingredient: ingredient,
      servings: 4,
      recipeServings: 2,
      inventory: [
        foodFixture(
          id: 'later',
          name: 'Milk',
          quantity: 1,
          unit: 'l',
          expiry: DateTime(2026, 10, 25),
        ),
        foodFixture(
          id: 'first',
          name: 'Milk',
          quantity: 750,
          unit: 'ml',
          expiry: DateTime(2026, 10, 22),
        ),
        foodFixture(
          id: 'expired',
          name: 'Milk',
          quantity: 1,
          unit: 'l',
          expiry: DateTime(2026, 10, 20),
        ),
      ],
      today: DateTime(2026, 10, 21),
    );
    expect(allocations.map((a) => a.foodId), ['first', 'later']);
    expect(allocations[0].amount, 750);
    expect(allocations[1].amount, .75);
  });

  test(
    'recipe operation is atomic when a later allocation conflicts',
    () async {
      await db.insert('food_items', foodFixture(id: 'a', quantity: 5).toMap());
      await db.insert('food_items', foodFixture(id: 'b', quantity: 1).toMap());
      expect(
        () => repo.apply(
          request(
            'atomic',
            const [
              ConsumptionAllocation(foodId: 'a', amount: 2),
              ConsumptionAllocation(foodId: 'b', amount: 2),
            ],
            kind: ConsumptionKind.recipe,
            recipeId: 'banana-oats',
          ),
        ),
        throwsA(isA<ConsumptionConflict>()),
      );
      final rows = await db.query('food_items', orderBy: 'id');
      expect(rows.map((r) => r['quantity']), [5, 1]);
      expect(await db.query('consumption_operations'), isEmpty);
    },
  );

  test(
    'undo restores unchanged data once and rejects later conflicts',
    () async {
      await db.insert('food_items', foodFixture(quantity: 5).toMap());
      await repo.apply(
        request('undo-me', const [
          ConsumptionAllocation(foodId: 'batch-1', amount: 2),
        ]),
      );
      await repo.undo('undo-me', DateTime.utc(2026, 10, 21, 13));
      expect((await db.query('food_items')).single['quantity'], 5);
      expect(
        () => repo.undo('undo-me', DateTime.utc(2026, 10, 21, 14)),
        throwsA(isA<ConsumptionConflict>()),
      );

      final row = (await db.query('food_items')).single;
      await repo.apply(
        request('changed', const [
          ConsumptionAllocation(foodId: 'batch-1', amount: 1),
        ]),
      );
      await db.update(
        'food_items',
        {'revision': (row['revision'] as int) + 3},
        where: 'id=?',
        whereArgs: ['batch-1'],
      );
      expect(
        () => repo.undo('changed', DateTime.utc(2026, 10, 21, 15)),
        throwsA(isA<ConsumptionConflict>()),
      );
    },
  );

  test('v6 upgrades to v7 without losing linked inventory', () async {
    final path = await databaseFactoryFfiNoIsolate.getDatabasesPath();
    final file = '$path/phase510-migration.db';
    await databaseFactoryFfiNoIsolate.deleteDatabase(file);
    final old = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: file,
      targetVersion: 6,
    );
    await old.insert('food_items', foodFixture(id: 'kept').toMap());
    await old.insert('shopping_items', {
      'id': 'shop',
      'name': 'Milk',
      'quantity': 1.0,
      'unit': 'l',
      'category_id': 'dairy',
      'purchased': 1,
      'inventory_id': 'kept',
      'converted': 1,
      'revision': 0,
      'created_at': DateTime.utc(2026).toIso8601String(),
    });
    await old.close();
    final upgraded = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: file,
    );
    expect(await upgraded.getVersion(), 7);
    expect(await upgraded.query('food_items'), hasLength(1));
    expect(
      (await upgraded.query('shopping_items')).single['inventory_id'],
      'kept',
    );
    await upgraded.close();
    await databaseFactoryFfiNoIsolate.deleteDatabase(file);
  });

  test(
    'export and personal-data deletion include consumption history',
    () async {
      await db.insert('food_items', foodFixture(quantity: 5).toMap());
      await repo.apply(
        request('exported', const [
          ConsumptionAllocation(foodId: 'batch-1', amount: 1),
        ]),
      );
      final json = jsonDecode(
        await PersonalDataStore(db).export(DateTime.utc(2026)),
      ) as Map<String, dynamic>;
      expect(json['consumption_operations'], hasLength(1));
      expect(json['consumption_entries'], hasLength(1));
      await PersonalDataStore(db).deleteRecords();
      expect(await db.query('consumption_operations'), isEmpty);
      expect(await db.query('consumption_entries'), isEmpty);
    },
  );
}
