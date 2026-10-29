import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/domain/food_item.dart';
import '../domain/reminders.dart';

class ReminderService {
  ReminderService(this.db, this.platform, {this.owner = 'freshkeep-expiry-v1'});
  final String owner;
  bool suspended = false;
  int? _lastRefresh;

  /// Stop queued reconciliation before cancelling alarms. A failed cleanup
  /// deliberately remains suspended until an explicit retry or app restart.
  Future<void> suspendAndCancel() {
    suspended = true;
    final task = _queue.then((_) async {
      await platform.initialize();
      final ids = <int>{
        for (final row in await db.query('reminder_ids')) row['id'] as int,
      };
      for (final pending in await platform.pending()) {
        try {
          if ((jsonDecode(pending.payload ?? '') as Map)['owner'] == owner) {
            ids.add(pending.id);
          }
        } catch (_) {
          /* Other features may own notification payloads. */
        }
      }
      for (final id in ids) {
        await platform.cancel(id);
      }
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  final Database db;
  final ReminderPlatform platform;
  Future<void> _queue = Future.value();
  Future<ReminderSettings> settings() async {
    final rows = await db.query('reminder_settings');
    if (rows.isEmpty) return const ReminderSettings();
    final settings = ReminderSettings.fromJson(
      jsonDecode(rows.single['content'] as String) as Map<String, dynamic>,
    );
    settings.validate();
    return settings;
  }

  Future<void> saveSettings(ReminderSettings value) async {
    value.validate();
    await db.insert('reminder_settings', {
      'id': 1,
      'content': jsonEncode(value.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReminderStatus> reconcile(
    List<FoodItem> items,
    ReminderSettings settings,
    DateTime now,
    String zone,
    AppLocalizations l, {
    int? refresh,
  }) {
    final task = _queue.then(
      (_) => _reconcile(items, settings, now, zone, l, refresh: refresh),
    );
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<ReminderStatus> _reconcile(
    List<FoodItem> items,
    ReminderSettings settings,
    DateTime now,
    String zone,
    AppLocalizations l, {
    int? refresh,
  }) async {
    if (suspended) return const ReminderStatus();
    await platform.initialize();
    final rearm = refresh != null && refresh != _lastRefresh;
    final permitted = await platform.permitted();
    final all = planReminders(items, settings, now);
    // Android OEM implementations may impose an alarm cap. Report the cap,
    // rather than silently exhausting it; earliest dates get priority.
    final plans = permitted ? all.take(400).toList() : <ReminderPlan>[];
    final desired =
        <
          int,
          ({ReminderPlan plan, String payload, String title, String body})
        >{};
    await db.transaction((tx) async {
      for (final plan in plans) {
        await tx.insert('reminder_ids', {
          'food_id': plan.food.id,
          'days': plan.days,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        final rows = await tx.query(
          'reminder_ids',
          where: 'food_id=? AND days=?',
          whereArgs: [plan.food.id, plan.days],
        );
        final id = rows.single['id'] as int;
        final body = l.expiryNotificationBody(
          plan.food.name,
          dateKey(plan.food.expiryDate),
          plan.days,
        );
        final payload = jsonEncode({
          'owner': owner,
          'food': plan.food.id,
          'days': plan.days,
          'date': plan.at.toIso8601String(),
          'zone': zone,
          'body': body,
        });
        desired[id] = (
          plan: plan,
          payload: payload,
          title: l.expiryNotificationTitle,
          body: body,
        );
      }
    });
    final pending = await platform.pending();
    bool ours(String? payload) {
      try {
        return (jsonDecode(payload ?? '') as Map)['owner'] == owner;
      } catch (_) {
        return false;
      }
    }

    final existing = {
      for (final p in pending.where((p) => ours(p.payload))) p.id: p.payload,
    };
    for (final id in existing.keys.where((id) => !desired.containsKey(id))) {
      await platform.cancel(id);
    }
    // IDs from previous runs also cancel notifications already delivered, so a
    // used/deleted batch does not leave a stale entry in the notification tray.
    final allocated = await db.query('reminder_ids');
    for (final row in allocated) {
      final id = row['id'] as int;
      if (!desired.containsKey(id) && !existing.containsKey(id)) {
        await platform.cancel(id);
      }
    }
    for (final entry in desired.entries) {
      if (rearm || existing[entry.key] != entry.value.payload) {
        await platform.cancel(entry.key);
        await platform.schedule(
          id: entry.key,
          localDate: entry.value.plan.at,
          zone: zone,
          title: entry.value.title,
          body: entry.value.body,
          payload: entry.value.payload,
        );
      }
    }
    if (desired.isEmpty) {
      await db.delete('reminder_ids');
    } else {
      await db.delete(
        'reminder_ids',
        where: 'id NOT IN (${List.filled(desired.length, '?').join(',')})',
        whereArgs: desired.keys.toList(),
      );
    }
    _lastRefresh = refresh;
    return ReminderStatus(
      scheduled: desired.length,
      total: all.length,
      blocked: settings.enabled && !permitted,
    );
  }
}
