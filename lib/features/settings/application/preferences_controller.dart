import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_preferences_repository.dart';
import '../domain/app_preferences.dart';
import '../domain/preferences_repository.dart';

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => LocalPreferencesRepository(SharedPreferencesAsync()),
);
final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

class PreferencesController extends AsyncNotifier<AppPreferences> {
  Future<void> _queue = Future.value();
  @override
  Future<AppPreferences> build() =>
      ref.read(preferencesRepositoryProvider).read();
  // Serialize changes to keep the UI consistent with the persisted snapshot.
  Future<void> _change(AppPreferences Function(AppPreferences) change) {
    final operation = _queue.then((_) async {
      final next = change(state.requireValue);
      await ref.read(preferencesRepositoryProvider).write(next);
      if (ref.mounted) state = AsyncData(next);
    });
    _queue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<void> setLanguage(String code) =>
      _change((p) => p.copyWith(languageCode: code));
  Future<void> setTheme(ThemeMode mode) =>
      _change((p) => p.copyWith(themeMode: mode));
  Future<void> finishOnboarding(String code) =>
      _change((p) => p.copyWith(languageCode: code, onboardingComplete: true));
}
