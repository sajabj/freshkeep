import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../reminders/presentation/reminder_settings_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../application/preferences_controller.dart';
import 'data_privacy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  Future<void> _save(Future<void> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(preferencesProvider).requireValue;
    final controller = ref.read(preferencesProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: SafeArea(
        child: ContentFrame(
          children: [
            Text(l.preferencesNote),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('open-reminders'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l.reminders),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReminderSettingsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l.language, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (final code in ['ar', 'en'])
                    ListTile(
                      key: Key('settings-language-$code'),
                      minVerticalPadding: 14,
                      title: Text(code == 'ar' ? 'العربية' : 'English'),
                      trailing: Icon(
                        Localizations.localeOf(context).languageCode == code
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      selected:
                          Localizations.localeOf(context).languageCode == code,
                      onTap: _saving
                          ? null
                          : () => _save(() => controller.setLanguage(code)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(l.appearance, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (final entry in [
                    (
                      ThemeMode.system,
                      l.systemTheme,
                      Icons.brightness_auto_outlined,
                    ),
                    (ThemeMode.light, l.lightTheme, Icons.light_mode_outlined),
                    (ThemeMode.dark, l.darkTheme, Icons.dark_mode_outlined),
                  ])
                    ListTile(
                      key: Key('theme-${entry.$1.name}'),
                      minVerticalPadding: 14,
                      leading: Icon(entry.$3),
                      title: Text(entry.$2),
                      selected: p.themeMode == entry.$1,
                      trailing: p.themeMode == entry.$1
                          ? const Icon(Icons.check)
                          : null,
                      onTap: _saving
                          ? null
                          : () => _save(() => controller.setTheme(entry.$1)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(l.privacyTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l.privacyBody),
            ListTile(
              key: const Key('open-data-privacy'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l.privacyTools),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DataPrivacyScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l.about, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l.version),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OnboardingScreen(preview: true),
                  ),
                ),
                child: Text(l.reviewIntro),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
