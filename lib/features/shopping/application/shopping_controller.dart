import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../inventory/domain/food_item.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_item.dart';

final shoppingRepositoryProvider = FutureProvider<ShoppingRepository>(
  (ref) async =>
      ShoppingRepository(await ref.watch(appDatabaseProvider.future)),
);
final shoppingProvider =
    AsyncNotifierProvider<ShoppingController, List<ShoppingItem>>(
      ShoppingController.new,
    );

class ShoppingController extends AsyncNotifier<List<ShoppingItem>> {
  Future<void> _queue = Future.value();
  Future<void> get idle => _queue;
  @override
  Future<List<ShoppingItem>> build() async =>
      (await ref.watch(shoppingRepositoryProvider.future)).load();
  Future<void> _write(Future<void> Function(ShoppingRepository) action) {
    final task = _queue.then((_) async {
      final repo = await ref.read(shoppingRepositoryProvider.future);
      await action(repo);
      try {
        final rows = await repo.load();
        if (ref.mounted) state = AsyncData(rows);
      } catch (e, s) {
        if (ref.mounted) state = AsyncError(e, s);
      }
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<void> save(ShoppingItem item, {required bool isNew}) =>
      _write((r) => r.save(item, isNew: isNew));
  Future<void> purchased(ShoppingItem item, bool value) =>
      _write((r) => r.setPurchased(item, value));
  Future<void> delete(ShoppingItem item) => _write((r) => r.delete(item));
  Future<void> convert(ShoppingItem item, FoodItem food) async {
    await _write((r) => r.convert(item, food));
    if (ref.mounted) ref.invalidate(inventoryProvider);
  }
}
