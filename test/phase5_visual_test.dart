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
import 'package:freshkeep/features/statistics/presentation/statistics_screen.dart';
import 'package:freshkeep/features/settings/presentation/data_privacy_screen.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
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
      for (final screen in ['statistics', 'privacy']) {
        testWidgets('phase5 $screen $language ${mode.name}', (t) async {
          t.view.physicalSize = const Size(390, 1600);
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
          for (var i = 0; i < 10; i++) {
            final day = DateTime(2026, 10, 20 - i * 3);
            final data =
                foodFixture(
                    id: 'visual-$i',
                    status: i % 3 == 0 ? FoodStatus.discarded : FoodStatus.used,
                  ).toMap()
                  ..['status_changed_at'] = day.toUtc().toIso8601String()
                  ..['price'] = i % 4 == 0 ? null : 4.5 + i;
            await db.insert('food_items', data);
          }
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                appDatabaseProvider.overrideWith((ref) async => db),
                reminderPlatformProvider.overrideWithValue(
                  MemoryReminderPlatform(),
                ),
                todayProvider.overrideWith(TestTodayController.new),
                clockProvider.overrideWithValue(
                  () => DateTime(2026, 10, 20, 12),
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
              child: host(
                screen == 'statistics'
                    ? const Scaffold(body: StatisticsScreen())
                    : const DataPrivacyScreen(),
                language: language,
                mode: mode,
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/phase5_${screen}_${language}_${mode.name}.png',
            ),
          );
        });
      }
    }
  }
}
