import 'food_item.dart';

List<FoodItem> useFirstItems(List<FoodItem> items, DateTime today) {
  final eligible = items
      .where(
        (item) =>
            item.status == FoodStatus.available &&
            daysUntil(item.expiryDate, today) >= 0,
      )
      .toList();
  eligible.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  return eligible.take(3).toList();
}

enum InventorySort { expiry, name, added }

class InventoryQuery {
  const InventoryQuery({
    this.search = '',
    this.category,
    this.storage,
    this.status = FoodStatus.available,
    this.sort = InventorySort.expiry,
  });
  final String search;
  final String? category;
  final StoragePlace? storage;
  final FoodStatus status;
  final InventorySort sort;
  List<FoodItem> apply(List<FoodItem> items) {
    final term = search.trim().toLowerCase();
    final result = items
        .where(
          (i) =>
              i.status == status &&
              (category == null || i.categoryId == category) &&
              (storage == null || i.storage == storage) &&
              i.name.toLowerCase().contains(term),
        )
        .toList();
    result.sort((a, b) {
      final comparison = switch (sort) {
        InventorySort.expiry => a.expiryDate.compareTo(b.expiryDate),
        InventorySort.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        InventorySort.added => b.createdAt.compareTo(a.createdAt),
      };
      return comparison == 0 ? a.id.compareTo(b.id) : comparison;
    });
    return result;
  }
}
