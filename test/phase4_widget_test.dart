import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/database_provider.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/core/time/clock.dart';
import 'package:freshkeep/app/freshkeep_app.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/shopping/presentation/shopping_screen.dart';
import 'package:freshkeep/features/recipes/presentation/recipes_screen.dart';
import 'package:freshkeep/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:freshkeep/features/reminders/application/reminder_controller.dart';
import 'package:freshkeep/features/reminders/presentation/reminder_settings_screen.dart';
import 'package:freshkeep/features/settings/application/preferences_controller.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';
import 'package:freshkeep/l10n/generated/app_localizations.dart';

import 'support/memory_preferences_repository.dart';
import 'support/memory_inventory_repository.dart';
import 'support/memory_reminder_platform.dart';
import 'support/food_fixture.dart';
import 'scanning_widget_test.dart' show host;

Future<void> press4(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  final rect = t.getRect(f);
  final view = t.view.physicalSize / t.view.devicePixelRatio;
  await t.tapAt(
    Offset(
      rect.center.dx.clamp(1, view.width - 1),
      (rect.top + 20).clamp(1, view.height - 1),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  sqfliteFfiInit();
  late Database db;
  late MemoryReminderPlatform platform;
  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    platform = MemoryReminderPlatform();
  });
  tearDown(() => db.close());
  Future<void> launch(
    WidgetTester t,
    Widget child, {
    String language = 'en',
    ThemeMode mode = ThemeMode.light,
  }) async {
    addTearDown(() => t.pumpWidget(const SizedBox()));
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          reminderPlatformProvider.overrideWithValue(platform),
          todayProvider.overrideWith(TestTodayController.new),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 20, 8)),
          preferencesRepositoryProvider.overrideWithValue(
            MemoryPreferencesRepository(
              AppPreferences(languageCode: language, onboardingComplete: true),
            ),
          ),
        ],
        child: host(child, language: language, mode: mode),
      ),
    );
    // Recipe photography is decoded asynchronously. A bounded pump lets the
    // repository and visible assets finish without waiting on image-cache
    // bookkeeping that can keep a frame scheduled in widget tests.
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    if (find.byType(RecipesScreen).evaluate().isNotEmpty) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await t.pump();
    }
    for (
      var i = 0;
      i < 100 &&
          find.byType(RecipesScreen).evaluate().isNotEmpty &&
          find.byType(CustomScrollView).evaluate().isEmpty;
      i++
    ) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(milliseconds: 500));
  }

  for (final language in ['en', 'ar']) {
    testWidgets(
      '$language shopping CRUD and confirmed-date conversion use same inventory',
      (t) async {
        await launch(t, const ShoppingScreen(), language: language);
        await press4(t, find.byKey(const Key('add-shopping')));
        await t.enterText(
          find.byKey(const Key('shopping-name')),
          language == 'ar' ? 'حليب' : 'Milk',
        );
        await t.enterText(find.byKey(const Key('shopping-quantity')), '٢');
        await t.enterText(find.byKey(const Key('shopping-unit')), 'l');
        await press4(t, find.byKey(const Key('save-shopping')));
        expect((await db.query('shopping_items')).single['quantity'], 2.0);
        final id = (await db.query('shopping_items')).single['id'];
        await press4(t, find.byKey(Key('purchased-$id')));
        expect((await db.query('shopping_items')).single['purchased'], 1);
        await press4(t, find.byKey(Key('convert-$id')));
        await press4(t, find.byKey(const Key('save-food')));
        expect(await db.query('food_items'), isEmpty);
        await press4(t, find.byKey(const Key('choose-expiry')));
        final picker = find.byType(DatePickerDialog);
        await press4(
          t,
          find.text(MaterialLocalizations.of(t.element(picker)).okButtonLabel),
        );
        await press4(t, find.byKey(const Key('save-food')));
        expect((await db.query('food_items')).length, 1);
        expect((await db.query('shopping_items')).single['converted'], 1);
        expect((await db.query('inventory_events')).length, 1);
        final text = AppLocalizations.of(t.element(find.byType(ShoppingScreen)))
            .deleteShopping;
        await press4(t, find.text(text));
        await press4(t, find.widgetWithText(FilledButton, text));
        expect(await db.query('shopping_items'), isEmpty);
        expect((await db.query('food_items')).length, 1);
      },
    );
  }
  testWidgets(
    'recipe search, details, favorites and missing ingredient shopping flow',
    (t) async {
      await launch(t, const Scaffold(body: RecipesScreen()));
      await t.enterText(find.byKey(const Key('recipe-search')), 'banana milk');
      await t.pumpAndSettle();
      expect(find.byKey(const Key('recipe-banana-oats')), findsOneWidget);
      await press4(t, find.byKey(const Key('recipe-banana-oats')));
      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      await press4(t, find.byKey(const Key('favorite-recipe')));
      expect(
        (await db.query(
          'recipes',
          where: 'id=?',
          whereArgs: ['banana-oats'],
        )).single['favorite'],
        1,
      );
      await press4(t, find.text('Add missing amount to shopping').first);
      await press4(t, find.byKey(const Key('save-shopping')));
      expect((await db.query('shopping_items')).length, 1);
      await press4(t, find.byType(BackButton));
      await t.enterText(find.byKey(const Key('recipe-search')), '');
      await t.pumpAndSettle();
      await press4(t, find.byKey(const Key('recipes-favorites')));
      expect(find.byKey(const Key('recipe-banana-oats')), findsOneWidget);
      expect(find.byKey(const Key('recipe-tomato-pasta')), findsNothing);
    },
  );
  testWidgets('settings permission denied, opt-in, offset and time persist', (
    t,
  ) async {
    platform.allowed = false;
    await launch(t, const ReminderSettingsScreen());
    await press4(t, find.byKey(const Key('enable-reminders')));
    expect(platform.requests, 1);
    expect(await db.query('reminder_settings'), isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
    platform.allowed = true;
    await press4(t, find.byKey(const Key('enable-reminders')));
    expect(
      (await db.query('reminder_settings')).single['content'],
      contains('"enabled":true'),
    );
    await press4(t, find.byKey(const Key('reminder-day-7')));
    expect(
      (await db.query('reminder_settings')).single['content'],
      isNot(contains('[7,')),
    );
    await press4(t, find.text('Add days'));
    await t.enterText(find.byKey(const Key('custom-reminder-days')), '٢');
    await press4(t, find.widgetWithText(FilledButton, 'Add days'));
    expect(find.byKey(const Key('reminder-day-2')), findsOneWidget);
    await press4(t, find.byKey(const Key('reminder-time')));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    final material = MaterialLocalizations.of(
      t.element(find.byType(TimePickerDialog)),
    );
    await press4(t, find.byTooltip(material.inputTimeModeButtonLabel));
    final inputs = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await t.enterText(inputs.at(0), '11');
    await t.enterText(inputs.at(1), '45');
    await press4(
      t,
      find.text(
        MaterialLocalizations.of(t.element(find.byType(TimePickerDialog)))
            .okButtonLabel,
      ),
    );
    expect(
      (await db.query('reminder_settings')).single['content'],
      contains('"hour":11'),
    );
    expect(
      (await db.query('reminder_settings')).single['content'],
      contains('"minute":45'),
    );
    await press4(t, find.byKey(const Key('enable-reminders')));
    expect(
      (await db.query('reminder_settings')).single['content'],
      contains('"enabled":false'),
    );
  });
  testWidgets(
    'app reacts to inventory edits and used status by rescheduling reminders',
    (t) async {
      addTearDown(() => t.pumpWidget(const SizedBox()));
      await db.insert('reminder_settings', {
        'id': 1,
        'content': '{"enabled":true,"hour":9,"minute":0,"days":[7,3,1,0]}',
      });
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async => db),
            reminderPlatformProvider.overrideWithValue(platform),
            todayProvider.overrideWith(TestTodayController.new),
            clockProvider.overrideWithValue(() => DateTime(2026, 10, 20, 8)),
            preferencesRepositoryProvider.overrideWithValue(
              MemoryPreferencesRepository(
                const AppPreferences(
                  languageCode: 'en',
                  onboardingComplete: true,
                ),
              ),
            ),
          ],
          child: const FreshKeepApp(),
        ),
      );
      await t.pumpAndSettle();
      final context = t.element(find.byType(FreshKeepApp));
      final container = ProviderScope.containerOf(context);
      await container
          .read(inventoryProvider.notifier)
          .save(foodFixture(expiry: DateTime(2026, 11, 1)), isNew: true);
      await t.pumpAndSettle();
      expect(platform.jobs.length, 4);
      final item = (await container.read(inventoryProvider.future)).single;
      await container
          .read(inventoryProvider.notifier)
          .changeStatus(item, FoodStatus.used);
      await t.pumpAndSettle();
      expect(platform.jobs, isEmpty);
    },
  );
  for (final language in ['ar', 'en']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'small $language ${mode.name} phase4 screens support 150 percent text',
        (t) async {
          t.view.physicalSize = const Size(320, 568);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          await launch(
            t,
            const Scaffold(body: RecipesScreen()),
            language: language,
            mode: mode,
          );
          await t.drag(find.byType(CustomScrollView), const Offset(0, -500));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          await launch(
            t,
            const ReminderSettingsScreen(),
            language: language,
            mode: mode,
          );
          await t.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -500),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          await launch(
            t,
            const ShoppingScreen(),
            language: language,
            mode: mode,
          );
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
