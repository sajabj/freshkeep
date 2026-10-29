import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/inventory/domain/inventory_repository.dart';

import 'support/food_fixture.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late SqliteInventoryRepository repo;
  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repo = SqliteInventoryRepository(db);
  });
  tearDown(() async => db.close());
  test('same barcode has independent batches and dates', () async {
    await repo.save(foodFixture(), isNew: true);
    await repo.save(
      foodFixture(id: 'batch-2', expiry: DateTime(2026, 11, 1)),
      isNew: true,
    );
    final items = await repo.load();
    expect(items.length, 2);
    expect(items.first.expiryDate, DateTime(2026, 10, 23));
    expect(items.last.expiryDate, DateTime(2026, 11, 1));
    expect((await db.query('inventory_events')).length, 2);
  });
  test(
    'edit preserves creation date, increments revision, rejects stale edit',
    () async {
      final item = foodFixture();
      await repo.save(item, isNew: true);
      final edited = FoodItem.fromMap(
        item.toMap()..addAll({
          'name': 'Oat milk',
          'quantity': 2.5,
          'created_at': '2000-01-01T00:00:00Z',
        }),
      );
      await repo.save(edited, isNew: false);
      final saved = (await repo.load()).single;
      expect(saved.name, 'Oat milk');
      expect(saved.quantity, 2.5);
      expect(saved.createdAt, item.createdAt);
      expect(saved.revision, 1);
      await expectLater(
        repo.save(edited, isNew: false),
        throwsA(isA<InventoryConflict>()),
      );
      expect((await db.query('inventory_events')).length, 2);
    },
  );
  test('lifecycle records reason, supports restore, and does not duplicate same status', () async {
    await repo.save(foodFixture(), isNew: true);
    var item = (await repo.load()).single;
    final at = DateTime(2026, 10, 21, 9);
    await repo.changeStatus(
      item,
      FoodStatus.discarded,
      at,
      reason: 'Damaged package',
    );
    item = (await repo.load()).single;
    expect(item.disposalReason, 'Damaged package');
    expect(item.statusChangedAt, at);
    await repo.changeStatus(item, FoodStatus.discarded, at);
    expect((await db.query('inventory_events')).length, 2);
    await repo.changeStatus(item, FoodStatus.available, at);
    item = (await repo.load()).single;
    expect(item.disposalReason, isNull);
    await repo.changeStatus(item, FoodStatus.used, at);
    expect((await repo.load()).single.status, FoodStatus.used);
  });
  test('event failure rolls back the food write', () async {
    await db.execute(
      "CREATE TRIGGER reject_event BEFORE INSERT ON inventory_events BEGIN SELECT RAISE(ABORT, 'event failure'); END",
    );
    await expectLater(
      repo.save(foodFixture(), isNew: true),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repo.load(), isEmpty);
  });
  test('delete removes batch but retains detached audit snapshots', () async {
    await repo.save(foodFixture(), isNew: true);
    await repo.delete((await repo.load()).single, DateTime(2026, 10, 21));
    expect(await repo.load(), isEmpty);
    final events = await db.query('inventory_events');
    expect(events.length, 2);
    expect(events.every((e) => e['food_id'] == null), isTrue);
    expect(
      (jsonDecode(events.last['snapshot'] as String) as Map)['name'],
      'Milk',
    );
  });
  test('invalid quantity is rejected before persistence', () async {
    await expectLater(
      repo.save(foodFixture(quantity: double.nan), isNew: true),
      throwsArgumentError,
    );
    expect(await repo.load(), isEmpty);
  });
  test(
    'v1 database upgrades without losing a saved batch, and survives reopen',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'freshkeep-migration-',
      );
      final path = '${temp.path}/inventory.db';
      final first = await LocalDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
        targetVersion: 1,
      );
      await first.insert('food_items', foodFixture().toMap());
      await first.close();
      final upgraded = await LocalDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect(await upgraded.getVersion(), LocalDatabase.version);
      final upgradedRepo = SqliteInventoryRepository(upgraded);
      expect((await upgradedRepo.load()).single.name, 'Milk');
      await upgradedRepo.changeStatus(
        (await upgradedRepo.load()).single,
        FoodStatus.used,
        DateTime(2026, 10, 21),
      );
      await upgraded.close();
      final reopened = await LocalDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect(
        (await SqliteInventoryRepository(reopened).load()).single.status,
        FoodStatus.used,
      );
      await reopened.close();
      await temp.delete(recursive: true);
    },
  );
}
