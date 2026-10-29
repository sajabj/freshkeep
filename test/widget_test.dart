import 'package:freshkeep/features/inventory/application/inventory_controller.dart';

import 'support/memory_inventory_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/app/freshkeep_app.dart';
import 'package:freshkeep/features/settings/application/preferences_controller.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';

import 'support/memory_preferences_repository.dart';

Future<void> launch(
  WidgetTester tester,
  MemoryPreferencesRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(repo),
        inventoryRepositoryProvider.overrideWith(
          (ref) async => MemoryInventoryRepository(),
        ),
        todayProvider.overrideWith(TestTodayController.new),
      ],
      child: const FreshKeepApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'four introduction pages, Arabic choice, completion and restart',
    (tester) async {
      final repo = MemoryPreferencesRepository();
      await launch(tester, repo);
      for (var i = 0; i < 4; i++) {
        await tap(tester, find.byKey(const Key('onboarding-next')));
      }
      await tap(tester, find.byKey(const Key('language-ar')));
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('finish-onboarding'))),
        ),
        TextDirection.rtl,
      );
      await tap(tester, find.byKey(const Key('finish-onboarding')));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(repo.value.onboardingComplete, isTrue);
      await tester.pumpWidget(const SizedBox());
      await launch(tester, repo);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const Key('onboarding-next')), findsNothing);
    },
  );
  for (final code in ['ar', 'en']) {
    testWidgets('$code navigation, shopping and preferences', (tester) async {
      final repo = MemoryPreferencesRepository(
        AppPreferences(languageCode: code, onboardingComplete: true),
      );
      await launch(tester, repo);
      for (final tab in ['inventory', 'recipes', 'statistics', 'home']) {
        await tap(tester, find.byKey(Key('nav-$tab')));
        expect(tester.takeException(), isNull);
      }
      await tap(tester, find.byKey(const Key('open-shopping')));
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-settings')));
      await tap(tester, find.byKey(const Key('theme-dark')));
      expect(repo.value.themeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byKey(const Key('theme-dark'))))
            .brightness,
        Brightness.dark,
      );
      final other = code == 'ar' ? 'en' : 'ar';
      await tap(tester, find.byKey(Key('settings-language-$other')));
      expect(repo.value.languageCode, other);
    });
  }
  testWidgets('write error does not dismiss onboarding', (tester) async {
    final repo = MemoryPreferencesRepository()..failWrite = true;
    await launch(tester, repo);
    await tap(tester, find.text('Skip introduction'));
    await tap(tester, find.byKey(const Key('finish-onboarding')));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(repo.value.onboardingComplete, isFalse);
  });
  testWidgets('read failure offers retry without overwriting data', (
    tester,
  ) async {
    final repo = MemoryPreferencesRepository()..failRead = true;
    await launch(tester, repo);
    expect(find.text('Try again'), findsOneWidget);
    repo.failRead = false;
    await tap(tester, find.text('Try again'));
    expect(find.byKey(const Key('onboarding-next')), findsOneWidget);
  });
  testWidgets('Android back returns secondary tab to home', (tester) async {
    await launch(
      tester,
      MemoryPreferencesRepository(
        const AppPreferences(onboardingComplete: true),
      ),
    );
    await tap(tester, find.byKey(const Key('nav-recipes')));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });
  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(800, 1024),
  ]) {
    testWidgets('Arabic large text fits $size in both themes', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = MemoryPreferencesRepository(
        const AppPreferences(languageCode: 'ar'),
      );
      await launch(tester, repo);
      for (var i = 0; i < 4; i++) {
        expect(tester.takeException(), isNull);
        await tap(tester, find.byKey(const Key('onboarding-next')));
      }
      await tap(tester, find.byKey(const Key('finish-onboarding')));
      expect(tester.takeException(), isNull);
      for (final tab in ['inventory', 'recipes', 'statistics']) {
        await tap(tester, find.byKey(Key('nav-$tab')));
        expect(tester.takeException(), isNull);
      }
      await tap(tester, find.byKey(const Key('open-settings')));
      await tap(tester, find.byKey(const Key('theme-dark')));
      expect(tester.takeException(), isNull);
    });
  }
}
