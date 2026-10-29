import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/statistics/domain/statistics.dart';
import 'package:freshkeep/features/settings/data/personal_data_store.dart';
import 'package:freshkeep/features/reminders/data/reminder_service.dart';
import 'package:freshkeep/features/reminders/domain/reminders.dart';
import 'package:freshkeep/l10n/generated/app_localizations_en.dart';

import 'support/food_fixture.dart';
import 'support/memory_reminder_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Database db;
  late SqliteInventoryRepository repo;
  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    repo = SqliteInventoryRepository(db);
  });
  tearDown(() => db.close());
  Future<InventoryStatistics> stats() async => InventoryStatistics.fromRows(
    await db.query('inventory_events'),
    await db.query('food_items'),
  );
  Future<FoodItem> batch(String id, {double? price}) async {
    final data = foodFixture(id: id, quantity: 5).toMap()..['price'] = price;
    final item = FoodItem.fromMap(data);
    await repo.save(item, isNew: true);
    return item;
  }

  Future<FoodItem> current(String id) async =>
      (await repo.load()).singleWhere((f) => f.id == id);
  test('real lifecycle counts once, restore reverses, deletion preserves history and price is total batch', () async {
    final a = await batch('a', price: 12.5);
    await repo.changeStatus(a, FoodStatus.used, DateTime(2026, 10, 18));
    await repo.changeStatus(
      await current('a'),
      FoodStatus.available,
      DateTime(2026, 10, 19),
    );
    expect((await stats()).totals(DateTime(2026, 10, 30)).used, 0);
    await repo.changeStatus(
      await current('a'),
      FoodStatus.discarded,
      DateTime(2026, 10, 20),
    );
    await repo.delete(await current('a'), DateTime(2026, 10, 21));
    final result = (await stats()).totals(DateTime(2026, 10, 30));
    expect(result.used, 0);
    expect(result.discarded, 1);
    expect(result.discardedValue, 12.5);
    expect(result.discardedPriced, 1);
    expect(
      (await db.query('inventory_events')).every((e) => e['food_id'] == null),
      isTrue,
    );
  });
  test(
    'zero is a known price, absent price excluded and future outcomes excluded',
    () async {
      for (final entry in [('zero', 0.0), ('missing', null), ('future', 8.0)]) {
        final f = await batch(entry.$1, price: entry.$2);
        await repo.changeStatus(
          f,
          FoodStatus.used,
          DateTime(2026, entry.$1 == 'future' ? 11 : 10, 20),
        );
      }
      final t = (await stats()).totals(DateTime(2026, 10, 21));
      expect(t.used, 2);
      expect(t.usedPriced, 1);
      expect(t.usedValue, 0);
    },
  );
  test(
    'weekly Monday boundaries and monthly year/leap boundaries are half open',
    () {
      final s = InventoryStatistics([
        Outcome('a', FoodStatus.used, DateTime(2026, 10, 18, 23, 59), null),
        Outcome('b', FoodStatus.discarded, DateTime(2026, 10, 19), null),
        Outcome('c', FoodStatus.used, DateTime(2026, 10, 26), null),
      ]);
      final weeks = s.trend(DateTime(2026, 10, 20, 12), TrendPeriod.weekly);
      expect(weeks.last.start, DateTime(2026, 10, 19));
      expect(weeks.last.totals.discarded, 1);
      expect(weeks.last.totals.used, 0);
      expect(weeks[4].totals.used, 1);
      final months = InventoryStatistics([
        Outcome('leap', FoodStatus.used, DateTime(2024, 2, 29, 23), 1),
      ]).trend(DateTime(2024, 3, 2), TrendPeriod.monthly);
      expect(months[4].start, DateTime(2024, 2));
      expect(months[4].totals.used, 1);
      expect(months.first.start, DateTime(2023, 10));
    },
  );
  test('revision orders same-time snapshots, corrupted history reported, legacy inventory supported', () {
    final data = foodFixture().toMap()
      ..addAll({
        'status': 'used',
        'status_changed_at': DateTime(2026, 10, 20).toUtc().toIso8601String(),
        'revision': 2,
      });
    final newer = {...data, 'status': 'available', 'revision': 3};
    final s = InventoryStatistics.fromRows([
      {'occurred_at': '2026-10-20T00:00:00Z', 'snapshot': jsonEncode(newer)},
      {'occurred_at': '2026-10-20T00:00:00Z', 'snapshot': jsonEncode(data)},
      {'occurred_at': 'invalid', 'snapshot': 'broken'},
    ], []);
    expect(s.outcomes, isEmpty);
    expect(s.invalidEvents, 1);
    final legacy = InventoryStatistics.fromRows([], [data]);
    expect(legacy.outcomes.length, 1);
  });
  test('empty history yields six honest zero buckets', () {
    final s = InventoryStatistics.fromRows([], []);
    expect(s.totals(DateTime.now()).used, 0);
    expect(s.trend(DateTime.now(), TrendPeriod.monthly).length, 6);
    expect(
      s
          .trend(DateTime.now(), TrendPeriod.monthly)
          .every((b) => b.totals.used + b.totals.discarded == 0),
      isTrue,
    );
  });
  test('JSON round trips Arabic, quotes and hostile CSV-looking names without exposing paths', () async {
    final data = foodFixture(name: '=SUM(1,2) حليب "خاص"\nسطر').toMap()
      ..['image_path'] = 'C:/private/secret.jpg'
      ..['source_url'] = 'https://world.openfoodfacts.org/product/123';
    await repo.save(FoodItem.fromMap(data), isNew: true);
    final output = await PersonalDataStore(db)
        .export(DateTime.utc(2026, 10, 20));
    final json = jsonDecode(output) as Map;
    expect(json['format'], 'freshkeep-export');
    expect(json['database_version'], 7);
    expect(json['inventory'][0]['name'], data['name']);
    expect(json['inventory'][0]['source_url'], data['source_url']);
    expect(output, isNot(contains('secret.jpg')));
    expect(output, isNot(contains('image_path')));
    expect(json['events'][0]['snapshot'], isA<Map>());
    expect((await db.query('food_items')).length, 1);
  });
  test('malformed snapshot export fails closed instead of leaking raw private content', () async {
    await db.insert('inventory_events', {
      'id': 'bad',
      'kind': 'used',
      'occurred_at': '2026-10-20',
      'snapshot': 'private path not json',
    });
    await expectLater(
      PersonalDataStore(db).export(DateTime.now()),
      throwsFormatException,
    );
  });
  test('deletion respects foreign keys, clears personal rows and retains schema, recipe library and category IDs', () async {
    await batch('a');
    await db.insert('shopping_items', {
      'id': 's',
      'name': 'a',
      'quantity': 1,
      'unit': 'pcs',
      'category_id': 'dairy',
      'inventory_id': 'a',
      'created_at': '2026-10-20',
    });
    await db.insert('recipes', {'id': 'r', 'content': '{}', 'favorite': 1});
    await db.insert('product_cache', {
      'barcode': '123',
      'fetched_at': '2026-10-20',
    });
    await db.insert('reminder_settings', {'id': 1, 'content': '{}'});
    await db.insert('reminder_ids', {'food_id': 'a', 'days': 1});
    final store = PersonalDataStore(db);
    await store.deleteRecords();
    await store.deleteRecords();
    for (final table in [
      'food_items',
      'inventory_events',
      'shopping_items',
      'product_cache',
      'reminder_settings',
      'reminder_ids',
      'meal_plans',
    ]) {
      expect(await db.query(table), isEmpty, reason: table);
    }
    expect((await db.query('recipes')).single['favorite'], 0);
    expect((await db.query('categories')).length, 10);
    expect(await db.getVersion(), 7);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await batch('new');
    expect((await stats()).outcomes, isEmpty);
  });
  test('deletion is atomic if a child deletion fails', () async {
    await batch('a');
    await db.execute(
      "CREATE TRIGGER deny_delete BEFORE DELETE ON food_items BEGIN SELECT RAISE(ABORT, 'test refusal'); END",
    );
    await expectLater(
      PersonalDataStore(db).deleteRecords(),
      throwsA(isA<DatabaseException>()),
    );
    expect((await db.query('inventory_events')).length, 1);
    expect((await db.query('food_items')).length, 1);
  });
  test(
    'suspension cancels reminders and blocks stale and queued reconciliations',
    () async {
      final platform = MemoryReminderPlatform();
      final service = ReminderService(db, platform);
      final food = foodFixture(expiry: DateTime(2026, 11, 5));
      final pending = service.reconcile(
        [food],
        const ReminderSettings(enabled: true),
        DateTime(2026, 10, 20),
        'Europe/London',
        AppLocalizationsEn(),
      );
      await service.suspendAndCancel();
      await pending;
      await service.reconcile(
        [food],
        const ReminderSettings(enabled: true),
        DateTime(2026, 10, 20),
        'Europe/London',
        AppLocalizationsEn(),
      );
      expect(platform.jobs, isEmpty);
    },
  );
  test('photo cleanup only deletes immediate owned files and ignores outside paths', () async {
    final root = await Directory.systemTemp.createTemp('freshkeep-phase5-');
    addTearDown(() async {
      await root.delete(recursive: true);
    });
    final outside = File('${root.path}/outside.jpg');
    await outside.writeAsString('retain');
    final photos = Directory('${root.path}/food_photos');
    await photos.create();
    final own = File('${photos.path}/owned.jpg');
    await own.writeAsString('erase');
    await PersonalDataStore.deletePhotos(root);
    expect(await own.exists(), isFalse);
    expect(await outside.exists(), isTrue);
  });
}
