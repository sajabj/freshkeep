import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/statistics/domain/statistics.dart';
import 'package:freshkeep/features/settings/data/personal_data_store.dart';
import 'package:freshkeep/features/settings/presentation/data_privacy_screen.dart';
import 'package:freshkeep/features/recipes/data/recipe_repository.dart';

import '../test/support/food_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native existing v4 database, statistics, export, relational deletion and owned photos',
    (t) async {
      final path = '${await getDatabasesPath()}/phase5-${const Uuid().v4()}.db';
      var db = await LocalDatabase.open(path: path, targetVersion: 4);
      addTearDown(() async {
        await db.close();
        await databaseFactory.deleteDatabase(path);
      });
      final repo = SqliteInventoryRepository(db);
      final item = FoodItem.fromMap(
        foodFixture(id: 'phase4-retained').toMap()..['price'] = 7.5,
      );
      await repo.save(item, isNew: true);
      await db.close();
      db = await LocalDatabase.open(path: path);
      expect(await db.getVersion(), 4);
      expect((await db.query('food_items')).length, 1);
      final liveRepo = SqliteInventoryRepository(db);
      await liveRepo.changeStatus(
        (await liveRepo.load()).single,
        FoodStatus.used,
        DateTime.now(),
      );
      await liveRepo.delete((await liveRepo.load()).single, DateTime.now());
      final stats = InventoryStatistics.fromRows(
        await db.query('inventory_events'),
        await db.query('food_items'),
      );
      expect(stats.totals(DateTime.now()).used, 1);
      expect(stats.totals(DateTime.now()).usedValue, 7.5);
      final recipes = await RecipeRepository(db).load();
      expect(recipes.length, 12);
      await db.update('recipes', {'favorite': 1});
      final json =
          jsonDecode(await PersonalDataStore(db).export(DateTime.now())) as Map;
      expect(json['events'], hasLength(3));
      expect(json['inventory'], isEmpty);
      expect(json['favorite_recipes'], hasLength(12));
      await PersonalDataStore(db).deleteRecords();
      expect(await db.query('inventory_events'), isEmpty);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect(
        (await db.query('recipes')).every((r) => r['favorite'] == 0),
        isTrue,
      );
      final docs = await getApplicationDocumentsDirectory();
      final probe = Directory('${docs.path}/phase5-test-${const Uuid().v4()}');
      await probe.create();
      addTearDown(() => probe.delete(recursive: true));
      final folder = Directory('${probe.path}/food_photos');
      await folder.create();
      final photo = File('${folder.path}/test.jpg');
      await photo.writeAsString('test-owned-file');
      await PersonalDataStore.deletePhotos(probe);
      expect(await photo.exists(), isFalse);
    },
  );
  // These two cases intentionally require the system document picker. The
  // verification driver saves/cancels through Android UI, never broad storage.
  testWidgets('native SAF JSON save through explicit user-selected document', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Phase 5 export verification')),
      ),
    );
    final name = 'FreshKeep-phase5-test-${const Uuid().v4()}.json';
    debugPrint('FRESHKEEP_PHASE5_SAVE_READY:$name');
    final saved = await dataExportChannel.invokeMethod<bool>('exportJson', {
      'name': name,
      'content': jsonEncode({
        'format': 'freshkeep-export-test',
        'name': 'حليب',
        'price': 7.5,
      }),
    });
    expect(saved, isTrue);
    debugPrint('FRESHKEEP_PHASE5_SAVE_VERIFIED:$name');
  }, timeout: const Timeout(Duration(minutes: 3)));
  testWidgets(
    'native SAF cancellation returns false without changing application data',
    (t) async {
      debugPrint('FRESHKEEP_PHASE5_CANCEL_READY');
      final saved = await dataExportChannel.invokeMethod<bool>('exportJson', {
        'name': 'FreshKeep-cancelled-test.json',
        'content': '{}',
      });
      expect(saved, isFalse);
      debugPrint('FRESHKEEP_PHASE5_CANCEL_VERIFIED');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
