import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../reminders/application/reminder_controller.dart';
import '../data/cooking_timer_repository.dart';
import '../domain/cooking_timer.dart';

final cookingTimerRepositoryProvider = FutureProvider(
  (ref) async =>
      CookingTimerRepository(await ref.watch(appDatabaseProvider.future)),
);
final cookingTimersProvider =
    AsyncNotifierProvider<CookingTimerController, List<CookingTimer>>(
      CookingTimerController.new,
    );

class CookingTimerController extends AsyncNotifier<List<CookingTimer>> {
  @override
  Future<List<CookingTimer>> build() async {
    final rows = await (await ref.watch(cookingTimerRepositoryProvider.future))
        .load(DateTime.now());
    await _reconcile(rows);
    return rows;
  }

  Future<void> create(String name, int seconds, {bool start = true}) async {
    if (name.trim().isEmpty || seconds <= 0 || seconds > 359999) {
      throw ArgumentError('Invalid timer');
    }
    final repo = await ref.read(cookingTimerRepositoryProvider.future);
    var timer = await repo.create(
      const Uuid().v4(),
      name,
      seconds,
      DateTime.now(),
    );
    if (start) {
      timer = _running(timer, DateTime.now());
      await repo.update(timer);
    }
    await _reload();
  }

  Future<void> pause(CookingTimer t) async {
    final now = DateTime.now();
    final remaining = t.remainingAt(now);
    await _cancel(t);
    await (await ref.read(cookingTimerRepositoryProvider.future)).update(
      _copy(
        t,
        state: remaining == 0
            ? CookingTimerState.finished
            : CookingTimerState.paused,
        remaining: remaining,
        end: null,
        notified: remaining == 0,
      ),
    );
    await _reload();
  }

  Future<void> resume(CookingTimer t) async {
    final next = _running(t, DateTime.now());
    await (await ref.read(cookingTimerRepositoryProvider.future)).update(next);
    await _reload();
  }

  Future<void> reset(CookingTimer t) async {
    await _cancel(t);
    await (await ref.read(cookingTimerRepositoryProvider.future)).update(
      _copy(
        t,
        state: CookingTimerState.paused,
        remaining: t.durationSeconds,
        end: null,
        notified: false,
      ),
    );
    await _reload();
  }

  Future<void> delete(CookingTimer t) async {
    await _cancel(t);
    await (await ref.read(cookingTimerRepositoryProvider.future)).delete(t.id);
    await _reload();
  }

  Future<void> refresh() => _reload();

  CookingTimer _running(CookingTimer t, DateTime now) => _copy(
    t,
    state: CookingTimerState.running,
    remaining: t.remainingSeconds,
    end: now.add(Duration(seconds: t.remainingSeconds)),
    notified: false,
  );
  CookingTimer _copy(
    CookingTimer t, {
    required CookingTimerState state,
    required int remaining,
    required DateTime? end,
    required bool notified,
  }) => CookingTimer(
    notificationId: t.notificationId,
    id: t.id,
    name: t.name,
    durationSeconds: t.durationSeconds,
    remainingSeconds: remaining,
    endAt: end,
    state: state,
    notified: notified,
    createdAt: t.createdAt,
    updatedAt: DateTime.now(),
  );
  Future<void> _reload() async {
    final rows = await (await ref.read(cookingTimerRepositoryProvider.future))
        .load(DateTime.now());
    await _reconcile(rows);
    if (ref.mounted) state = AsyncData(rows);
  }

  Future<void> _cancel(CookingTimer t) async {
    await ref.read(reminderPlatformProvider).initialize();
    await ref.read(reminderPlatformProvider).cancel(t.notificationId);
  }

  Future<void> _reconcile(List<CookingTimer> rows) async {
    final p = ref.read(reminderPlatformProvider);
    await p.initialize();
    final pending = {for (final n in await p.pending()) n.id: n.payload};
    final zone = await p.timezone();
    for (final t in rows) {
      final payload = jsonEncode({
        'owner': 'freshkeep-timer-v1',
        'timer': t.id,
        'end': t.endAt?.toUtc().toIso8601String(),
      });
      if (t.state == CookingTimerState.running &&
          t.endAt != null &&
          t.endAt!.isAfter(DateTime.now())) {
        if (pending[t.notificationId] != payload && await p.permitted()) {
          await p.cancel(t.notificationId);
          await p.schedule(
            id: t.notificationId,
            localDate: t.endAt!,
            zone: zone,
            title: t.name,
            body: 'FreshKeep · Cooking timer finished',
            payload: payload,
          );
        }
      } else {
        await p.cancel(t.notificationId);
      }
    }
  }
}
