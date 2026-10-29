import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/shopping/data/shopping_repository.dart';
import 'package:freshkeep/features/shopping/domain/shopping_item.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/inventory/domain/inventory_repository.dart';
import 'package:freshkeep/features/recipes/data/recipe_repository.dart';
import 'package:freshkeep/features/recipes/domain/recipe.dart';
import 'package:freshkeep/features/reminders/domain/reminders.dart';
import 'package:freshkeep/features/reminders/data/reminder_service.dart';
import 'package:freshkeep/l10n/generated/app_localizations_en.dart';

import 'support/food_fixture.dart';
import 'support/memory_reminder_platform.dart';

ShoppingItem shopping({
  String id = 'shop',
  double quantity = 2,
  int revision = 0,
}) => ShoppingItem(
  id: id,
  name: 'Milk',
  quantity: quantity,
  unit: 'l',
  categoryId: 'dairy',
  createdAt: DateTime(2026, 10, 20),
  revision: revision,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Database db;
  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() => db.close());
  test(
    'resume/manual refresh rearms stable IDs after OS alarms were cleared',
    () async {
      final platform = MemoryReminderPlatform();
      final service = ReminderService(db, platform);
      final food = foodFixture(expiry: DateTime(2026, 11, 1));
      const settings = ReminderSettings(enabled: true);
      final now = DateTime(2026, 10, 20);
      final l = AppLocalizationsEn();
      await service.reconcile(
        [food],
        settings,
        now,
        'Europe/London',
        l,
        refresh: 0,
      );
      final ids = platform.jobs.keys.toSet();
      await service.reconcile(
        [food],
        settings,
        now,
        'Europe/London',
        l,
        refresh: 0,
      );
      expect(platform.schedules, 4);
      await service.reconcile(
        [food],
        settings,
        now,
        'Europe/London',
        l,
        refresh: 1,
      );
      expect(platform.schedules, 8);
      expect(platform.jobs.keys.toSet(), ids);
      expect(platform.jobs.length, 4);
    },
  );
  test('v3 to v4 preserves food, event, product cache and source', () async {
    final folder = await Directory.systemTemp.createTemp('freshkeep-v4-');
    final path = '${folder.path}/app.db';
    final old = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: path,
      targetVersion: 3,
    );
    final original = foodFixture().toMap()
      ..['source_url'] = 'https://world.openfoodfacts.net/product/12345678';
    await old.insert('food_items', original);
    await old.insert('inventory_events', {
      'id': 'event',
      'food_id': original['id'],
      'kind': 'created',
      'occurred_at': '2026-10-20',
      'snapshot': jsonEncode(original),
    });
    await old.insert('product_cache', {
      'barcode': 'test',
      'payload': '{}',
      'fetched_at': '2026-10-20',
    });
    await old.close();
    final next = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: path,
    );
    expect(await next.getVersion(), 7);
    expect(
      (await next.query('food_items')).single['source_url'],
      original['source_url'],
    );
    expect((await next.query('inventory_events')).length, 1);
    expect((await next.query('product_cache')).length, 1);
    await ShoppingRepository(next).save(shopping(), isNew: true);
    await next.close();
    await File(path).delete();
    await folder.delete();
  });
  test('shopping create edit check delete, stale writes rejected', () async {
    final repo = ShoppingRepository(db);
    await repo.save(shopping(), isNew: true);
    await repo.save(shopping(quantity: 3), isNew: false);
    await expectLater(
      repo.save(shopping(quantity: 4), isNew: false),
      throwsA(isA<InventoryConflict>()),
    );
    var current = (await repo.load()).single;
    expect(current.quantity, 3);
    await repo.setPurchased(current, true);
    current = (await repo.load()).single;
    expect(current.purchased, isTrue);
    await repo.setPurchased(current, false);
    current = (await repo.load()).single;
    await repo.delete(current);
    expect(await repo.load(), isEmpty);
  });
  test('conversion is atomic, creates audit, cannot duplicate; deleting shopping retains food', () async {
    final repo = ShoppingRepository(db);
    await repo.save(shopping(), isNew: true);
    await repo.convert(shopping(), foodFixture());
    final converted = (await repo.load()).single;
    expect(converted.converted, isTrue);
    expect(converted.purchased, isTrue);
    expect(converted.inventoryId, foodFixture().id);
    expect((await db.query('inventory_events')).length, 1);
    await expectLater(
      repo.convert(shopping(), foodFixture(id: 'other')),
      throwsA(isA<InventoryConflict>()),
    );
    await repo.delete(converted);
    expect((await db.query('food_items')).length, 1);
  });
  test('conversion event failure rolls back shopping and food', () async {
    final repo = ShoppingRepository(db);
    await repo.save(shopping(), isNew: true);
    await db.execute(
      "CREATE TRIGGER fail_event BEFORE INSERT ON inventory_events BEGIN SELECT RAISE(ABORT,'test'); END",
    );
    await expectLater(
      repo.convert(shopping(), foodFixture()),
      throwsA(anything),
    );
    expect((await repo.load()).single.converted, isFalse);
    expect(await db.query('food_items'), isEmpty);
  });
  test('recipe library preserves 12 originals and favorites persist', () async {
    final repo = RecipeRepository(db);
    final recipes = await repo.load();
    final originals = recipes.where((r) => !r.isFitness).toList();
    expect(originals.length, 12);
    expect(recipes.map((r) => r.id).toSet().length, recipes.length);
    for (final r in recipes) {
      expect(r.ar, isNotEmpty);
      expect(r.en, isNotEmpty);
      expect(r.minutes, greaterThan(0));
      expect(r.stepsAr.length, r.stepsEn.length);
      expect(r.stepsAr.length, greaterThanOrEqualTo(3));
      expect(r.ingredients.length, greaterThanOrEqualTo(3));
      for (final i in r.ingredients) {
        expect(i.amount, greaterThan(0));
        expect(i.aliases, isNotEmpty);
      }
    }
    await repo.favorite(recipes.first.id, true);
    expect(
      (await RecipeRepository(
        db,
      ).load()).singleWhere((r) => r.id == recipes.first.id).favorite,
      isTrue,
    );
    expect((await db.query('recipes')).length, recipes.length);
  });
  test('quantity/unit matching excludes past/archived and does not guess unknown names', () async {
    final r = (await RecipeRepository(
      db,
    ).load()).singleWhere((r) => r.id == 'banana-oats');
    final foods = [
      foodFixture(
        name: 'Milk',
        quantity: .5,
        unit: 'l',
        expiry: DateTime(2026, 10, 22),
      ),
      foodFixture(
        id: 'oats',
        name: 'شوفان',
        quantity: 50,
        unit: 'g',
        expiry: DateTime(2026, 10, 21),
      ),
      foodFixture(
        id: 'old',
        name: 'Oats',
        quantity: 500,
        unit: 'g',
        expiry: DateTime(2026, 10, 19),
      ),
      foodFixture(
        id: 'used',
        name: 'Banana',
        quantity: 5,
        unit: 'pcs',
        status: FoodStatus.used,
      ),
      foodFixture(id: 'odd', name: 'Oat milk', quantity: 5, unit: 'l'),
    ];
    final matches = matchRecipe(r, foods, DateTime(2026, 10, 20));
    expect(matches[0].availability, IngredientAvailability.partial);
    expect(matches[1].availability, IngredientAvailability.enough);
    expect(matches[2].availability, IngredientAvailability.missing);
    expect(matches[1].foods.length, 1);
    final unmeasured = matchRecipe(r, [
      foodFixture(name: 'Milk', unit: 'bottles'),
    ], DateTime(2026, 10, 19));
    expect(unmeasured[1].availability, IngredientAvailability.unmeasured);
  });
  test('urgent ingredient ranking uses eligible stock only', () async {
    final recipes = await RecipeRepository(db).load();
    final foods = [
      foodFixture(
        name: 'Red lentils',
        quantity: 200,
        unit: 'g',
        expiry: DateTime(2026, 10, 20),
      ),
    ];
    expect(
      rankedRecipes(recipes, foods, DateTime(2026, 10, 20)).first.id,
      'red-lentil-soup',
    );
    final matches = matchRecipe(
      recipes.singleWhere((r) => r.id == 'red-lentil-soup'),
      foods,
      DateTime(2026, 10, 21),
    );
    expect(matches.every((m) => m.urgency == 0), isTrue);
  });
  test('restock excludes available duplicate batches and existing unpurchased entries', () {
    final used = foodFixture(status: FoodStatus.used);
    expect(restockSuggestions([used], []).length, 1);
    expect(restockSuggestions([used, foodFixture(id: 'another')], []), isEmpty);
    expect(restockSuggestions([used], [shopping()]), isEmpty);
    expect(
      restockSuggestions([foodFixture(status: FoodStatus.discarded)], []),
      isEmpty,
    );
  });
  test('calendar reminder planning uses civil days, future only, offsets and status', () {
    final settings = const ReminderSettings(enabled: true);
    final plans = planReminders(
      [foodFixture(expiry: DateTime(2026, 11, 1))],
      settings,
      DateTime(2026, 10, 20),
    );
    expect(plans.map((p) => p.days), [7, 3, 1, 0]);
    expect(plans.first.at, DateTime(2026, 10, 25, 9));
    expect(
      planReminders(
        [foodFixture(expiry: DateTime(2026, 10, 20))],
        settings,
        DateTime(2026, 10, 20, 10),
      ),
      isEmpty,
    );
    expect(
      planReminders(
        [foodFixture(status: FoodStatus.used)],
        settings,
        DateTime(2026, 10, 1),
      ),
      isEmpty,
    );
    expect(
      () => const ReminderSettings(days: []).validate(),
      throwsArgumentError,
    );
  });
  test('reminders stable IDs, no duplicates, changes replace; deleting/status/disable cancel', () async {
    final platform = MemoryReminderPlatform();
    final service = ReminderService(db, platform);
    final settings = const ReminderSettings(enabled: true);
    final now = DateTime(2026, 10, 20);
    final l = AppLocalizationsEn();
    final food = foodFixture(expiry: DateTime(2026, 11, 1));
    await service.saveSettings(settings);
    expect((await service.settings()).enabled, isTrue);
    await service.reconcile([food], settings, now, 'Europe/London', l);
    expect(platform.jobs.length, 4);
    final ids = platform.jobs.keys.toSet();
    await service.reconcile([food], settings, now, 'Europe/London', l);
    expect(platform.schedules, 4);
    expect(platform.jobs.keys.toSet(), ids);
    await service.reconcile(
      [foodFixture(name: 'New name', expiry: DateTime(2026, 11, 1))],
      settings,
      now,
      'Europe/London',
      l,
    );
    expect(platform.schedules, 8);
    expect(platform.jobs.keys.toSet(), ids);
    await service.reconcile(
      [foodFixture(status: FoodStatus.used)],
      settings,
      now,
      'Europe/London',
      l,
    );
    expect(platform.jobs, isEmpty);
    await service.reconcile([food], settings, now, 'Europe/London', l);
    await service.reconcile([], settings, now, 'Europe/London', l);
    expect(platform.jobs, isEmpty);
    await service.reconcile([food], settings, now, 'Europe/London', l);
    await service.reconcile(
      [food],
      const ReminderSettings(),
      now,
      'Europe/London',
      l,
    );
    expect(platform.jobs, isEmpty);
  });
  test('permission denial and schedule failure are recoverable without touching food', () async {
    final platform = MemoryReminderPlatform()..allowed = false;
    final service = ReminderService(db, platform);
    final f = foodFixture(expiry: DateTime(2026, 11, 1));
    const s = ReminderSettings(enabled: true);
    final now = DateTime(2026, 10, 20);
    final l = AppLocalizationsEn();
    expect(
      (await service.reconcile([f], s, now, 'Europe/London', l)).blocked,
      isTrue,
    );
    expect(platform.requests, 0);
    platform.allowed = true;
    platform.failSchedule = true;
    await expectLater(
      service.reconcile([f], s, now, 'Europe/London', l),
      throwsStateError,
    );
    platform.failSchedule = false;
    await service.reconcile([f], s, now, 'Europe/London', l);
    expect(platform.jobs.length, 4);
    expect(await db.query('food_items'), isEmpty);
  });
  test(
    'reminder cap is explicit and unrelated notifications remain untouched',
    () async {
      final platform = MemoryReminderPlatform();
      final service = ReminderService(db, platform);
      final foods = [
        for (var i = 0; i < 101; i++)
          foodFixture(id: 'food-$i', expiry: DateTime(2026, 11, 1)),
      ];
      platform.jobs[99999] = (
        date: DateTime(2027),
        zone: 'UTC',
        title: 'other',
        body: 'other',
        payload: 'other',
      );
      final status = await service.reconcile(
        foods,
        const ReminderSettings(enabled: true),
        DateTime(2026, 10, 20),
        'Europe/London',
        AppLocalizationsEn(),
      );
      expect(status.total, 404);
      expect(status.scheduled, 400);
      expect(platform.jobs.containsKey(99999), isTrue);
    },
  );
}
