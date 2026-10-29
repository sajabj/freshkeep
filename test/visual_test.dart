import 'support/food_fixture.dart';

import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';

import 'support/memory_inventory_repository.dart';

import 'dart:io';

import 'package:freshkeep/core/time/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/app/freshkeep_app.dart';
import 'package:freshkeep/features/settings/application/preferences_controller.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';

import 'support/memory_preferences_repository.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('NotoSansArabic')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('assets/fonts/NotoSansArabic.ttf').readAsBytes(),
          ),
        ),
      );
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final code in ['ar', 'en']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final intro in [true, false]) {
        testWidgets('visual $code ${mode.name} ${intro ? 'intro' : 'home'}', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = MemoryPreferencesRepository(
            AppPreferences(
              languageCode: code,
              themeMode: mode,
              onboardingComplete: !intro,
            ),
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                preferencesRepositoryProvider.overrideWithValue(repo),
                inventoryRepositoryProvider.overrideWith(
                  (ref) async => MemoryInventoryRepository(
                    intro
                        ? const []
                        : [
                            foodFixture(
                              id: 'milk',
                              name: code == 'ar' ? 'حليب طازج' : 'Fresh milk',
                            ),
                            foodFixture(
                              id: 'oats',
                              name: code == 'ar' ? 'شوفان' : 'Oats',
                              category: 'grains',
                              quantity: 500,
                              unit: 'g',
                              expiry: DateTime(2026, 10, 20),
                            ),
                            foodFixture(
                              id: 'past',
                              name: code == 'ar' ? 'خبز' : 'Bread',
                              category: 'bakery',
                              expiry: DateTime(2026, 10, 18),
                            ),
                            foodFixture(
                              id: 'used',
                              name: code == 'ar' ? 'عدس' : 'Lentils',
                              status: FoodStatus.used,
                            ),
                          ],
                  ),
                ),
                todayProvider.overrideWith(TestTodayController.new),
                clockProvider.overrideWithValue(
                  () => DateTime(2026, 10, 19, 9),
                ),
              ],
              child: const FreshKeepApp(),
            ),
          );
          await tester.pumpAndSettle();
          // Capture the full root boundary, including localized navigation.
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/${code}_${mode.name}_${intro ? 'intro' : 'home'}.png',
            ),
          );
        });
      }
    }
  }
}
