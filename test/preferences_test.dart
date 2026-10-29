import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';
import 'package:freshkeep/features/settings/application/preferences_controller.dart';

import 'support/memory_preferences_repository.dart';

void main() {
  test('preferences round-trip and tolerate unknown options', () {
    final prefs = AppPreferences.fromJson(
      const AppPreferences(
        languageCode: 'ar',
        themeMode: ThemeMode.dark,
        onboardingComplete: true,
      ).toJson(),
    );
    expect(prefs.languageCode, 'ar');
    expect(prefs.themeMode, ThemeMode.dark);
    expect(prefs.onboardingComplete, isTrue);
    final unknown = AppPreferences.fromJson({
      'language': 'xx',
      'theme': 'other',
    });
    expect(unknown.languageCode, isNull);
    expect(unknown.themeMode, ThemeMode.system);
  });
  test(
    'serialized changes and a new container preserve all preferences',
    () async {
      final repo = MemoryPreferencesRepository();
      final container = ProviderContainer(
        overrides: [preferencesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(preferencesProvider.future);
      final controller = container.read(preferencesProvider.notifier);
      await Future.wait([
        controller.setLanguage('ar'),
        controller.setTheme(ThemeMode.dark),
        controller.finishOnboarding('ar'),
      ]);
      final restarted = ProviderContainer(
        overrides: [preferencesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(restarted.dispose);
      final saved = await restarted.read(preferencesProvider.future);
      expect(saved.languageCode, 'ar');
      expect(saved.themeMode, ThemeMode.dark);
      expect(saved.onboardingComplete, isTrue);
    },
  );
  test('failed writes retain previous state and queue recovers', () async {
    final repo = MemoryPreferencesRepository()..failWrite = true;
    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    final controller = container.read(preferencesProvider.notifier);
    await expectLater(controller.finishOnboarding('en'), throwsStateError);
    expect(
      container.read(preferencesProvider).requireValue.onboardingComplete,
      isFalse,
    );
    repo.failWrite = false;
    await controller.finishOnboarding('ar');
    expect(
      container.read(preferencesProvider).requireValue.onboardingComplete,
      isTrue,
    );
  });
}
