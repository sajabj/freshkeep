import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freshkeep/core/database/database_provider.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/shopping/presentation/shopping_screen.dart';
import 'package:freshkeep/features/recipes/presentation/recipes_screen.dart';
import 'package:freshkeep/features/recipes/data/recipe_repository.dart';
import 'package:freshkeep/features/reminders/data/android_reminder_platform.dart';
import 'package:freshkeep/features/reminders/data/reminder_service.dart';
import 'package:freshkeep/features/reminders/domain/reminders.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/l10n/generated/app_localizations_en.dart';

import '../test/support/food_fixture.dart';
import '../test/support/memory_inventory_repository.dart';
import '../test/scanning_widget_test.dart' show host;

Future<void> tap4(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native v3 migration, shopping conversion, recipe favorite persist together',
    (t) async {
      final path = '${await getDatabasesPath()}/phase4-${const Uuid().v4()}.db';
      final old = await LocalDatabase.open(path: path, targetVersion: 3);
      await old.insert('food_items', foodFixture(id: 'prior-food').toMap());
      await old.insert('product_cache', {
        'barcode': 'prior-cache',
        'payload': null,
        'fetched_at': DateTime.now().toIso8601String(),
      });
      await old.close();
      var db = await LocalDatabase.open(path: path);
      addTearDown(() async {
        await t.pumpWidget(const SizedBox());
        await db.close();
        await databaseFactory.deleteDatabase(path);
      });
      expect((await db.query('food_items')).single['id'], 'prior-food');
      expect((await db.query('product_cache')).length, 1);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async => db),
            todayProvider.overrideWith(TestTodayController.new),
          ],
          child: host(const ShoppingScreen(), language: 'ar'),
        ),
      );
      await t.pumpAndSettle();
      await tap4(t, find.byKey(const Key('add-shopping')));
      await t.enterText(find.byKey(const Key('shopping-name')), 'حليب');
      await t.enterText(find.byKey(const Key('shopping-unit')), 'ml');
      await t.enterText(find.byKey(const Key('shopping-quantity')), '٥٠٠');
      await tap4(t, find.byKey(const Key('save-shopping')));
      final id = (await db.query('shopping_items')).single['id'];
      await tap4(t, find.byKey(Key('convert-$id')));
      await tap4(t, find.byKey(const Key('choose-expiry')));
      final dialog = find.byType(DatePickerDialog);
      await tap4(
        t,
        find.text(MaterialLocalizations.of(t.element(dialog)).okButtonLabel),
      );
      await tap4(t, find.byKey(const Key('save-food')));
      expect((await db.query('food_items')).length, 2);
      expect((await db.query('shopping_items')).single['converted'], 1);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async => db),
            todayProvider.overrideWith(TestTodayController.new),
          ],
          child: host(const Scaffold(body: RecipesScreen())),
        ),
      );
      await t.pumpAndSettle();
      await tap4(t, find.byKey(const Key('recipe-banana-oats')));
      await tap4(t, find.byKey(const Key('favorite-recipe')));
      await t.pumpWidget(const SizedBox());
      await db.close();
      db = await LocalDatabase.open(path: path);
      expect((await db.query('food_items')).length, 2);
      expect(
        (await RecipeRepository(
          db,
        ).load()).singleWhere((r) => r.id == 'banana-oats').favorite,
        isTrue,
      );
      expect((await db.query('inventory_events')).length, 1);
    },
  );
  testWidgets(
    'native inexact reminders schedule replace cancel and post without exact alarm permission',
    (t) async {
      final path =
          '${await getDatabasesPath()}/reminder-test-${const Uuid().v4()}.db';
      final db = await LocalDatabase.open(path: path);
      final native = AndroidReminderPlatform();
      await native.initialize();
      const base = 1900300000;
      await db.insert('reminder_ids', {
        'id': base,
        'food_id': 'seed',
        'days': 0,
      });
      await db.delete('reminder_ids');
      final owner = 'freshkeep-test-${const Uuid().v4()}';
      final service = ReminderService(db, native, owner: owner);
      addTearDown(() async {
        for (final row in await db.query('reminder_ids')) {
          await native.cancel(row['id'] as int);
        }
        await native.cancel(base - 1);
        await db.close();
        await databaseFactory.deleteDatabase(path);
      });
      expect(
        await native.permitted(),
        isTrue,
        reason: 'The emulator notification permission must be granted before this test.',
      );
      final now = DateTime.now();
      final expiry = DateTime(now.year, now.month, now.day + 10);
      final f = foodFixture(id: 'native-fixture', expiry: expiry);
      const settings = ReminderSettings(enabled: true);
      final zone = await native.timezone();
      await service.reconcile(
        [f],
        settings,
        now,
        zone,
        AppLocalizationsEn(),
        refresh: 0,
      );
      List<PendingReminder> owned(List<PendingReminder> values) =>
          values.where((p) => p.payload?.contains(owner) ?? false).toList();
      final first = owned(await native.pending());
      expect(first.length, 4);
      final ids = first.map((p) => p.id).toSet();
      await service.reconcile(
        [f],
        settings,
        now,
        zone,
        AppLocalizationsEn(),
        refresh: 1,
      );
      expect(owned(await native.pending()).map((p) => p.id).toSet(), ids);
      await service.reconcile(
        [foodFixture(id: f.id, name: 'Changed', expiry: expiry)],
        settings,
        now,
        zone,
        AppLocalizationsEn(),
      );
      expect(
        owned(await native.pending())
            .every((p) => jsonDecode(p.payload!)['body'].contains('Changed')),
        isTrue,
      );
      await service.reconcile([], settings, now, zone, AppLocalizationsEn());
      expect(owned(await native.pending()), isEmpty);
      await native.plugin.show(
        id: base - 1,
        title: 'FreshKeep integration test',
        body: 'Notification channel verification · test fixture',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'freshkeep_expiry_v1',
            'FreshKeep expiry reminders',
            enableVibration: false,
            icon: 'ic_notification',
          ),
        ),
      );
      expect(
        (await native.plugin.getActiveNotifications()).any(
          (n) => n.id == base - 1,
        ),
        isTrue,
      );
      await native.cancel(base - 1);
    },
  );
}
