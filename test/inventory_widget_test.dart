import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:freshkeep/app/freshkeep_app.dart';

import 'package:freshkeep/features/inventory/application/inventory_controller.dart';

import 'package:freshkeep/features/settings/application/preferences_controller.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';

import 'support/memory_preferences_repository.dart';
import 'support/memory_inventory_repository.dart';

Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> confirmDate(WidgetTester tester) async {
  await press(tester, find.byKey(const Key('choose-expiry')));
  final dialog = find.byType(DatePickerDialog);
  final ok = MaterialLocalizations.of(tester.element(dialog)).okButtonLabel;
  await press(tester, find.text(ok));
}

void main() {
  sqfliteFfiInit();

  for (final language in ['en', 'ar']) {
    testWidgets(
      '$language form validates date, persists Arabic quantity, and edits a real SQLite batch',
      (tester) async {
        final db = await LocalDatabase.open(
          factory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        );
        final repo = SqliteInventoryRepository(db);
        addTearDown(db.close);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesRepositoryProvider.overrideWithValue(
                MemoryPreferencesRepository(
                  AppPreferences(
                    languageCode: language,
                    onboardingComplete: true,
                  ),
                ),
              ),
              inventoryRepositoryProvider.overrideWith((ref) async => repo),
              todayProvider.overrideWith(TestTodayController.new),
            ],
            child: const FreshKeepApp(),
          ),
        );
        await tester.pumpAndSettle();
        await press(tester, find.byKey(const Key('home-add-food')));
        await tester.enterText(
          find.byKey(const Key('food-name')),
          language == 'ar' ? 'حليب' : 'Milk',
        );
        await tester.enterText(find.byKey(const Key('food-quantity')), '٢٫٥');
        await press(tester, find.byKey(const Key('save-food')));
        expect(await repo.load(), isEmpty);
        await confirmDate(tester);
        await press(tester, find.byKey(const Key('save-food')));
        final first = (await repo.load()).single;
        expect(first.quantity, 2.5);
        await press(tester, find.text(first.name));
        await press(tester, find.byKey(const Key('edit-food')));
        await tester.enterText(find.byKey(const Key('food-quantity')), '3');
        await press(tester, find.byKey(const Key('save-food')));
        expect((await repo.load()).single.quantity, 3);
        await press(tester, find.byKey(const Key('duplicate-food')));
        await press(tester, find.byKey(const Key('save-food')));
        expect(
          (await repo.load()).length,
          1,
        ); // A duplicate must confirm its own date.
        await confirmDate(tester);
        await press(tester, find.byKey(const Key('save-food')));
        expect((await repo.load()).length, 2);
        await press(tester, find.byKey(const Key('delete-food')));
        // Cancel leaves both batches intact.
        await press(tester, find.text(language == 'ar' ? 'إلغاء' : 'Cancel'));
        expect((await repo.load()).length, 2);
        await press(tester, find.byKey(const Key('delete-food')));
        await press(tester, find.byKey(const Key('confirm-food-action')));
        expect((await repo.load()).length, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
  testWidgets('write failure keeps entered form values and allows a retry', (
    tester,
  ) async {
    final repo = MemoryInventoryRepository()..failWrite = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            MemoryPreferencesRepository(
              const AppPreferences(
                languageCode: 'en',
                onboardingComplete: true,
              ),
            ),
          ),
          inventoryRepositoryProvider.overrideWith((ref) async => repo),
          todayProvider.overrideWith(TestTodayController.new),
        ],
        child: const FreshKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
    await press(tester, find.byKey(const Key('home-add-food')));
    await tester.enterText(find.byKey(const Key('food-name')), 'Lentils');
    await confirmDate(tester);
    await press(tester, find.byKey(const Key('save-food')));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(repo.items, isEmpty);
    expect(find.text('Lentils'), findsOneWidget);
    repo.failWrite = false;
    await press(tester, find.byKey(const Key('save-food')));
    expect(repo.items.single.name, 'Lentils');
  });
  testWidgets('small Arabic form supports enlarged text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(
            MemoryPreferencesRepository(
              const AppPreferences(
                languageCode: 'ar',
                onboardingComplete: true,
              ),
            ),
          ),
          inventoryRepositoryProvider.overrideWith(
            (ref) async => MemoryInventoryRepository(),
          ),
          todayProvider.overrideWith(TestTodayController.new),
        ],
        child: const FreshKeepApp(),
      ),
    );
    await tester.pumpAndSettle();
    await press(tester, find.byKey(const Key('home-add-food')));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('اختر صورة'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
