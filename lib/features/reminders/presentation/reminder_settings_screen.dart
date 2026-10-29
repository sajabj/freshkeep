import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/presentation/food_labels.dart';
import '../application/reminder_controller.dart';
import '../domain/reminders.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});
  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsState();
}

class _ReminderSettingsState extends ConsumerState<ReminderSettingsScreen> {
  bool _busy = false;
  Future<void> _save(ReminderSettings settings) async {
    setState(() => _busy = true);
    try {
      await ref.read(reminderSettingsProvider.notifier).save(settings);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is NotificationPermissionDenied
                  ? l.notificationDenied
                  : e is ArgumentError
                  ? l.offsetError
                  : l.saveError,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(ReminderSettings settings) async {
    String value = '';
    final l = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.addOffset),
        content: TextField(
          key: const Key('custom-reminder-days'),
          keyboardType: TextInputType.number,
          onChanged: (v) => value = v,
          decoration: InputDecoration(
            helperText: l.offsetHelp,
            helperMaxLines: 4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value),
            child: Text(l.addOffset),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final n = parseFoodNumber(result);
    if (n == null ||
        !n.isFinite ||
        n != n.roundToDouble() ||
        n < 0 ||
        n > 365 ||
        settings.days.contains(n.toInt()) ||
        settings.days.length >= 8) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.offsetError)));
      return;
    }
    await _save(
      settings.copy(
        days: [...settings.days, n.toInt()]..sort((a, b) => b.compareTo(a)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(reminderSettingsProvider);
    final sync = ref.watch(reminderSyncProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.reminders)),
      body: SafeArea(
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(reminderSettingsProvider),
              child: Text(l.retry),
            ),
          ),
          data: (s) => ContentFrame(
            children: [
              Text(l.remindersIntro),
              const SizedBox(height: 16),
              SwitchListTile(
                key: const Key('enable-reminders'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.enableReminders),
                value: s.enabled,
                onChanged: _busy ? null : (v) => _save(s.copy(enabled: v)),
              ),
              const SizedBox(height: 16),
              ListTile(
                key: const Key('reminder-time'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.reminderTime),
                subtitle: Text(
                  TimeOfDay(hour: s.hour, minute: s.minute).format(context),
                ),
                trailing: const Icon(Icons.schedule),
                onTap: _busy
                    ? null
                    : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: s.hour,
                            minute: s.minute,
                          ),
                        );
                        if (time != null && mounted) {
                          await _save(
                            s.copy(hour: time.hour, minute: time.minute),
                          );
                        }
                      },
              ),
              const SizedBox(height: 24),
              Text(
                l.reminderOffsets,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in {
                    ...s.days,
                    7,
                    3,
                    1,
                    0,
                  }.toList()..sort((a, b) => b.compareTo(a)))
                    FilterChip(
                      key: Key('reminder-day-$day'),
                      label: Text(l.daysBeforeDate(day)),
                      selected: s.days.contains(day),
                      onSelected: _busy
                          ? null
                          : (v) => _save(
                              s.copy(
                                days: v
                                    ? [...s.days, day]
                                    : s.days.where((d) => d != day).toList(),
                              ),
                            ),
                    ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _busy ? null : () => _add(s),
                  icon: const Icon(Icons.add),
                  label: Text(l.addOffset),
                ),
              ),
              const SizedBox(height: 20),
              sync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(
                  l.reminderFailure,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                data: (status) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (status.blocked) Text(l.notificationDenied),
                    Text(l.reminderCount(status.scheduled, status.total)),
                    if (status.total > status.scheduled && !status.blocked)
                      Text(l.reminderCap),
                  ],
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () =>
                          ref.read(reminderRefreshProvider.notifier).refresh(),
                child: Text(l.retryReminders),
              ),
              const SizedBox(height: 20),
              Text(l.reminderTimingNote),
            ],
          ),
        ),
      ),
    );
  }
}
