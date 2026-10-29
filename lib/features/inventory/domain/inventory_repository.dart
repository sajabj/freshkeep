import 'food_item.dart';

abstract interface class InventoryRepository {
  Future<List<FoodItem>> load();
  Future<void> save(FoodItem item, {required bool isNew});
  Future<void> changeStatus(
    FoodItem item,
    FoodStatus status,
    DateTime at, {
    String? reason,
  });
  Future<void> delete(FoodItem item, DateTime at);
}

class InventoryConflict implements Exception {
  const InventoryConflict();
}
