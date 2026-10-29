import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/application/preferences_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../l10n/generated/app_localizations.dart';

class FreshKeepApp extends ConsumerWidget {
  const FreshKeepApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);
    final current = preferences.asData?.value;
    return MaterialApp(
      title: 'FreshKeep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.create(Brightness.light),
      darkTheme: AppTheme.create(Brightness.dark),
      themeMode: current?.themeMode ?? ThemeMode.system,
      locale: current?.languageCode == null
          ? null
          : Locale(current!.languageCode!),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: preferences.when(
        loading: () => const _StartupScreen(),
        error: (_, _) => const _StartupScreen(failed: true),
        data: (p) =>
            p.onboardingComplete ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }
}

class _StartupScreen extends ConsumerWidget {
  const _StartupScreen({this.failed = false});
  final bool failed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_outlined, size: 56),
                const SizedBox(height: 24),
                Text(
                  failed ? l.loadError : 'FreshKeep',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (failed)
                  FilledButton(
                    onPressed: () => ref.invalidate(preferencesProvider),
                    child: Text(l.retry),
                  )
                else
                  CircularProgressIndicator(semanticsLabel: l.loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
