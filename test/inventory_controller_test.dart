import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';

import 'support/food_fixture.dart';
import 'support/memory_inventory_repository.dart';

class _FailRefresh extends MemoryInventoryRepository {
  @override
  Future<void> save(FoodItem item, {required bool isNew}) async {
    await super.save(item, isNew: isNew);
    failRead = true;
  }
}

void main() {
  test(
    'failed mutation keeps the last snapshot; queue accepts a retry',
    () async {
      final repo = MemoryInventoryRepository([foodFixture()]);
      final container = ProviderContainer(
        overrides: [
          inventoryRepositoryProvider.overrideWith((ref) async => repo),
        ],
      );
      addTearDown(container.dispose);
      final original = (await container.read(inventoryProvider.future)).single;
      repo.failWrite = true;
      await expectLater(
        container
            .read(inventoryProvider.notifier)
            .changeStatus(original, FoodStatus.used),
        throwsStateError,
      );
      expect(
        container.read(inventoryProvider).requireValue.single.status,
        FoodStatus.available,
      );
      repo.failWrite = false;
      await container
          .read(inventoryProvider.notifier)
          .changeStatus(original, FoodStatus.used);
      expect(
        container.read(inventoryProvider).requireValue.single.status,
        FoodStatus.used,
      );
    },
  );
  test('post-commit refresh error does not ask the caller to duplicate a saved batch', () async {
    final repo = _FailRefresh();
    final container = ProviderContainer(
      overrides: [
        inventoryRepositoryProvider.overrideWith((ref) async => repo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(inventoryProvider.future);
    await container
        .read(inventoryProvider.notifier)
        .save(foodFixture(), isNew: true);
    expect(repo.items.length, 1);
    expect(container.read(inventoryProvider).hasError, isTrue);
    repo.failRead = false;
    container.invalidate(inventoryProvider);
    expect((await container.read(inventoryProvider.future)).length, 1);
  });
}
