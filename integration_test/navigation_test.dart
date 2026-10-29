import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freshkeep/app/freshkeep_app.dart';
import 'package:freshkeep/features/settings/data/local_preferences_repository.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android navigation and native preference persistence', (
    tester,
  ) async {
    final repository = LocalPreferencesRepository(SharedPreferencesAsync());
    // Test emulator only: restore preferences afterwards.
    final original = await repository.read();
    addTearDown(() => repository.write(original));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    await repository.write(const AppPreferences(languageCode: 'en'));
    await tester.pumpWidget(const ProviderScope(child: FreshKeepApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip introduction'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-ar')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('finish-onboarding')));
    await tester.tap(find.byKey(const Key('finish-onboarding')));
    await tester.pumpAndSettle();
    for (final tab in ['inventory', 'recipes', 'statistics', 'home']) {
      await tester.tap(find.byKey(Key('nav-$tab')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const Key('open-shopping')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('theme-dark')));
    await tester.tap(find.byKey(const Key('theme-dark')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ProviderScope(child: FreshKeepApp()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    final persisted = await LocalPreferencesRepository(SharedPreferencesAsync())
        .read();
    expect(persisted.onboardingComplete, isTrue);
    expect(persisted.languageCode, 'ar');
    expect(persisted.themeMode, ThemeMode.dark);
  });
}
