import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/database_provider.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/core/time/clock.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/features/reminders/application/reminder_controller.dart';
import 'package:freshkeep/features/reminders/presentation/reminder_settings_screen.dart';
import 'package:freshkeep/features/recipes/presentation/recipes_screen.dart';
import 'package:freshkeep/features/shopping/presentation/shopping_screen.dart';
import 'package:freshkeep/features/shopping/data/shopping_repository.dart';
import 'package:freshkeep/features/shopping/domain/shopping_item.dart';
import 'package:freshkeep/features/settings/application/preferences_controller.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';

import 'support/food_fixture.dart';
import 'support/memory_inventory_repository.dart';
import 'support/memory_preferences_repository.dart';
import 'support/memory_reminder_platform.dart';
import 'scanning_widget_test.dart' show host;

void main() {
  sqfliteFfiInit();
  setUpAll(() async {
    await (FontLoader('NotoSansArabic')..addFont(
          Future.value(
            ByteData.sublistView(
              await File('assets/fonts/NotoSansArabic.ttf').readAsBytes(),
            ),
          ),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final language in ['ar', 'en']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final screen in ['recipes', 'shopping', 'reminders']) {
        for (final width in [
          390.0,
          if (language == 'ar' && mode == ThemeMode.dark) 320.0,
        ]) {
          testWidgets('phase4 $screen $language ${mode.name} $width', (
            t,
          ) async {
            t.view.physicalSize = Size(width, 844);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.resetPhysicalSize);
            addTearDown(t.view.resetDevicePixelRatio);
            final db = await LocalDatabase.open(
              factory: databaseFactoryFfiNoIsolate,
              path: inMemoryDatabasePath,
            );
            addTearDown(() async {
              await t.pumpWidget(const SizedBox());
              await db.close();
            });
            await db.insert(
              'food_items',
              foodFixture(
                name: language == 'ar' ? 'حليب' : 'Milk',
                expiry: DateTime(2026, 10, 21),
                quantity: 500,
                unit: 'ml',
              ).toMap(),
            );
            await ShoppingRepository(db).save(
              ShoppingItem(
                id: 'fixture',
                name: language == 'ar' ? 'تفاح' : 'Apple',
                quantity: 3,
                unit: language == 'ar' ? 'حبة' : 'pcs',
                categoryId: 'fruit',
                createdAt: DateTime(2026, 10, 20),
              ),
              isNew: true,
            );
            await db.insert('reminder_settings', {
              'id': 1,
              'content':
                  '{"enabled":true,"hour":9,"minute":0,"days":[7,3,1,0]}',
            });
            final child = switch (screen) {
              'recipes' => const Scaffold(body: RecipesScreen()),
              'shopping' => const ShoppingScreen(),
              _ => const ReminderSettingsScreen(),
            };
            await t.pumpWidget(
              ProviderScope(
                overrides: [
                  appDatabaseProvider.overrideWith((ref) async => db),
                  reminderPlatformProvider.overrideWithValue(
                    MemoryReminderPlatform(),
                  ),
                  todayProvider.overrideWith(TestTodayController.new),
                  clockProvider.overrideWithValue(
                    () => DateTime(2026, 10, 20, 8),
                  ),
                  preferencesRepositoryProvider.overrideWithValue(
                    MemoryPreferencesRepository(
                      AppPreferences(
                        languageCode: language,
                        onboardingComplete: true,
                      ),
                    ),
                  ),
                ],
                child: host(child, language: language, mode: mode),
              ),
            );
            // Use a deterministic frame budget: the recipe library now also
            // decodes local WebP photography and can keep cache work scheduled.
            await t.pump();
            await t.pump(const Duration(milliseconds: 100));
            if (screen == 'recipes') {
              await t.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 250)),
              );
              await t.pump();
            }
            for (
              var i = 0;
              i < 100 &&
                  screen == 'recipes' &&
                  find.byType(CustomScrollView).evaluate().isEmpty;
              i++
            ) {
              await t.pump(const Duration(milliseconds: 100));
            }
            await t.pump(const Duration(milliseconds: 500));
            expect(t.takeException(), isNull);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/phase4_${screen}_${language}_${mode.name}_${width.toInt()}.png',
              ),
            );
          });
        }
      }
    }
  }
}
