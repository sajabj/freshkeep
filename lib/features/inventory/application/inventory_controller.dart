import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/clock.dart';
import '../data/sqlite_inventory_repository.dart';
import '../domain/food_item.dart';
import '../domain/inventory_repository.dart';

final inventoryRepositoryProvider = FutureProvider<InventoryRepository>((
  ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return SqliteInventoryRepository(db);
});
final inventoryProvider =
    AsyncNotifierProvider<InventoryController, List<FoodItem>>(
      InventoryController.new,
    );

class InventoryController extends AsyncNotifier<List<FoodItem>> {
  Future<void> _queue = Future.value();
  Future<void> get idle => _queue;
  @override
  Future<List<FoodItem>> build() async =>
      (await ref.watch(inventoryRepositoryProvider.future)).load();
  Future<void> _write(Future<void> Function(InventoryRepository) action) {
    final result = _queue.then((_) async {
      final repo = await ref.read(inventoryRepositoryProvider.future);
      await action(repo);
      // A committed write stays successful even if the subsequent refresh
      // fails. Show a retryable read error instead of inviting a duplicate save.
      try {
        final items = await repo.load();
        if (ref.mounted) state = AsyncData(items);
      } catch (error, stack) {
        if (ref.mounted) state = AsyncError(error, stack);
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> save(FoodItem item, {required bool isNew}) =>
      _write((r) => r.save(item, isNew: isNew));
  Future<void> changeStatus(
    FoodItem item,
    FoodStatus status, {
    String? reason,
  }) => _write(
    (r) =>
        r.changeStatus(item, status, ref.read(clockProvider)(), reason: reason),
  );
  Future<void> delete(FoodItem item) =>
      _write((r) => r.delete(item, ref.read(clockProvider)()));
}

/// Update date-sensitive labels after midnight and after returning from the
/// background. Use one timer, not a polling loop or elapsed-hours calculation.
final todayProvider = NotifierProvider<TodayController, DateTime>(
  TodayController.new,
);

class TodayController extends Notifier<DateTime> {
  Timer? _timer;
  @override
  DateTime build() {
    final listener = AppLifecycleListener(onResume: _refresh);
    ref.onDispose(() {
      _timer?.cancel();
      listener.dispose();
    });
    final now = ref.watch(clockProvider)();
    _schedule(now);
    return calendarDate(now);
  }

  void _schedule(DateTime now) {
    _timer?.cancel();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), _refresh);
  }

  void _refresh() {
    final now = ref.read(clockProvider)();
    state = calendarDate(now);
    _schedule(now);
  }
}
