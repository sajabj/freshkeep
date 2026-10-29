import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../recipes/application/recipe_controller.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../statistics/application/statistics_provider.dart';
import '../../cooking_timers/application/cooking_timer_controller.dart';
import '../data/personal_data_store.dart';

final personalFilesCleanupProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await PersonalDataStore.deletePhotos(
      await getApplicationDocumentsDirectory(),
    );
    await DefaultCacheManager().emptyCache();
  },
);

const dataExportChannel = MethodChannel('freshkeep/device');

class DataPrivacyScreen extends ConsumerStatefulWidget {
  const DataPrivacyScreen({super.key});
  @override
  ConsumerState<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends ConsumerState<DataPrivacyScreen> {
  bool busy = false;
  Future<void> run(Future<String> Function(AppLocalizations) action) async {
    final l = AppLocalizations.of(context);
    setState(() => busy = true);
    try {
      final message = await action(l);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.dataError)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> erase() async {
    final l = AppLocalizations.of(context);
    var checked = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.deleteLocal),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.deleteLocalNote),
                CheckboxListTile(
                  key: const Key('acknowledge-delete'),
                  contentPadding: EdgeInsets.zero,
                  value: checked,
                  title: Text(l.deleteAcknowledge),
                  onChanged: (v) => setDialogState(() => checked = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              key: const Key('confirm-delete-data'),
              onPressed: checked ? () => Navigator.pop(context, true) : null,
              child: Text(l.deleteLocal),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await run((l) async {
      await (
        ref.read(inventoryProvider.notifier).idle,
        ref.read(shoppingProvider.notifier).idle,
        ref.read(recipesProvider.notifier).idle,
      ).wait;
      // Let initial recipe seeding finish before resetting favorites.
      await ref.read(recipesProvider.future);
      final service = await ref.read(reminderServiceProvider.future);
      await service.suspendAndCancel();
      final db = await ref.read(appDatabaseProvider.future);
      final platform = ref.read(reminderPlatformProvider);
      for (final row in await db.query(
        'cooking_timers',
        columns: ['notification_id'],
      )) {
        await platform.cancel(100000 + (row['notification_id'] as int));
      }
      final store = PersonalDataStore(db);
      try {
        await store.deleteRecords();
        await ref.read(personalFilesCleanupProvider)();
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } finally {
        // The old service remains suspended, including any stale async calls.
        ref.invalidate(inventoryProvider);
        ref.invalidate(shoppingProvider);
        ref.invalidate(recipesProvider);
        ref.invalidate(statisticsProvider);
        ref.invalidate(reminderSettingsProvider);
        ref.invalidate(reminderServiceProvider);
        ref.invalidate(cookingTimersProvider);
      }
      return l.deleteDone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.privacyTools)),
        body: SafeArea(
          child: ContentFrame(
            children: [
              Text(l.privacyDetail),
              const SizedBox(height: 28),
              Text(l.exportData, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l.exportNote),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('export-data'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: busy
                    ? null
                    : () => run((l) async {
                        final now = ref.read(clockProvider)();
                        final json = await PersonalDataStore(
                          await ref.read(appDatabaseProvider.future),
                        ).export(now);
                        final saved = await dataExportChannel.invokeMethod<bool>(
                          'exportJson',
                          {
                            'content': json,
                            'name':
                                'FreshKeep-${now.toIso8601String().substring(0, 10)}.json',
                          },
                        );
                        return saved == true ? l.exportDone : l.exportCancelled;
                      }),
                icon: const Icon(Icons.file_download_outlined),
                label: Text(l.exportData),
              ),
              const SizedBox(height: 32),
              Text(
                l.deleteLocal,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l.deleteLocalNote),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('delete-data'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: busy ? null : erase,
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l.deleteLocal),
              ),
              if (busy) ...[
                const SizedBox(height: 24),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Semantics(liveRegion: true, child: Text(l.dataBusy)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
