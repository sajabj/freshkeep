import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:freshkeep/features/inventory/data/food_photo_store.dart';
import 'package:freshkeep/app/freshkeep_app.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/settings/application/preferences_controller.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';

import '../test/support/memory_preferences_repository.dart';
import '../test/support/memory_inventory_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('gallery import copies a photo out of temporary storage', (
    tester,
  ) async {
    final source = File(
      p.join((await getTemporaryDirectory()).path, '${const Uuid().v4()}.png'),
    );
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aJLsAAAAASUVORK5CYII=',
    );
    await source.writeAsBytes(bytes);
    final store = FoodPhotoStore();
    final imported = await store.import(XFile(source.path));
    await source.delete();
    expect(await File(imported).readAsBytes(), bytes);
    expect(
      imported.startsWith((await getApplicationDocumentsDirectory()).path),
      isTrue,
    );
    await store.discardStaged([imported]);
  });
  testWidgets(
    'Android real SQLite CRUD, lifecycle and process-independent persistence',
    (tester) async {
      final path = p.join(
        await getDatabasesPath(),
        'integration-${const Uuid().v4()}.db',
      );
      var db = await LocalDatabase.open(path: path);
      var repo = SqliteInventoryRepository(db);
      final prefs = MemoryPreferencesRepository(
        const AppPreferences(languageCode: 'ar', onboardingComplete: true),
      );
      Future<void> launch() async {
        final activeRepo = repo;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesRepositoryProvider.overrideWithValue(prefs),
              inventoryRepositoryProvider.overrideWith(
                (ref) async => activeRepo,
              ),
              todayProvider.overrideWith(TestTodayController.new),
            ],
            child: const FreshKeepApp(),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await db.close();
        await deleteDatabase(path);
      });
      await launch();
      await tap(find.byKey(const Key('home-add-food')));
      await tester.enterText(
        find.byKey(const Key('food-name')),
        'حليب الاختبار',
      );
      await tester.enterText(find.byKey(const Key('food-quantity')), '٢٫٥');
      await tap(find.byKey(const Key('choose-expiry')));
      final ok = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      ).okButtonLabel;
      await tap(find.text(ok));
      await tap(find.byKey(const Key('save-food')));
      expect((await repo.load()).single.quantity, 2.5);
      await tap(find.byKey(const Key('nav-inventory')));
      await tap(find.text('حليب الاختبار'));
      await tap(find.text('تم استخدامه'));
      await tap(find.byKey(const Key('confirm-food-action')));
      expect((await repo.load()).single.status, FoodStatus.used);
      await tap(find.text('إعادة إلى المخزون'));
      await tap(find.byKey(const Key('confirm-food-action')));
      await tap(find.text('تم التخلص منه'));
      await tester.enterText(
        find.byKey(const Key('disposal-reason')),
        'عبوة تالفة',
      );
      await tap(find.byKey(const Key('confirm-food-action')));
      expect((await repo.load()).single.disposalReason, 'عبوة تالفة');
      await tap(find.text('إعادة إلى المخزون'));
      await tap(find.byKey(const Key('confirm-food-action')));
      await tap(find.byKey(const Key('edit-food')));
      await tester.enterText(find.byKey(const Key('food-quantity')), '3');
      await tap(find.byKey(const Key('save-food')));
      expect((await repo.load()).single.quantity, 3);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await db.close();
      db = await LocalDatabase.open(path: path);
      repo = SqliteInventoryRepository(db);
      expect((await repo.load()).single.quantity, 3);
      await launch();
      await tap(find.byKey(const Key('nav-inventory')));
      await tap(find.text('حليب الاختبار'));
      await tap(find.byKey(const Key('delete-food')));
      await tap(find.byKey(const Key('confirm-food-action')));
      expect(await repo.load(), isEmpty);
      final events = await db.query('inventory_events');
      expect(
        events.length,
        7,
      ); // create, use, restore, discard, restore, edit, delete.
      expect(events.every((e) => e['food_id'] == null), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
