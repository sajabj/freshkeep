import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/clock.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../settings/application/preferences_controller.dart';
import '../data/android_reminder_platform.dart';
import '../data/reminder_service.dart';
import '../domain/reminders.dart';

final reminderPlatformProvider = Provider<ReminderPlatform>(
  (ref) => AndroidReminderPlatform(),
);
final reminderServiceProvider = FutureProvider<ReminderService>(
  (ref) async => ReminderService(
    await ref.watch(appDatabaseProvider.future),
    ref.watch(reminderPlatformProvider),
  ),
);
final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderController, ReminderSettings>(
      ReminderController.new,
    );

class ReminderController extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() async =>
      (await ref.watch(reminderServiceProvider.future)).settings();
  Future<void> save(ReminderSettings settings) async {
    settings.validate();
    if (settings.enabled &&
        !(await ref.read(reminderPlatformProvider).permitted())) {
      if (!await ref.read(reminderPlatformProvider).requestPermission()) {
        throw const NotificationPermissionDenied();
      }
    }
    await (await ref.read(reminderServiceProvider.future))
        .saveSettings(settings);
    if (ref.mounted) state = AsyncData(settings);
  }
}

final reminderRefreshProvider = NotifierProvider<ReminderRefresh, int>(
  ReminderRefresh.new,
);

class ReminderRefresh extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

final reminderSyncProvider = FutureProvider<ReminderStatus>((ref) async {
  final refresh = ref.watch(reminderRefreshProvider);
  ref.watch(todayProvider);
  final foodFuture = ref.watch(inventoryProvider.future);
  final settingsFuture = ref.watch(reminderSettingsProvider.future);
  final preferencesFuture = ref.watch(preferencesProvider.future);
  final serviceFuture = ref.watch(reminderServiceProvider.future);
  final clock = ref.watch(clockProvider);
  final platform = ref.watch(reminderPlatformProvider);
  // Resolve the actual device IANA zone, rather than assuming UTC or a fixed
  // offset that would silently shift reminders across daylight-saving changes.
  final (foods, settings, preferences, service, zone) = await (
    foodFuture,
    settingsFuture,
    preferencesFuture,
    serviceFuture,
    platform.timezone(),
  ).wait;
  if (!ref.mounted) return const ReminderStatus();
  return service.reconcile(
    foods,
    settings,
    clock(),
    zone,
    lookupAppLocalizations(Locale(preferences.languageCode ?? 'en')),
    refresh: refresh,
  );
});
