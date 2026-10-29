import '../../inventory/domain/food_item.dart';

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.categoryId,
    required this.createdAt,
    this.purchased = false,
    this.converted = false,
    this.inventoryId,
    this.revision = 0,
  });
  final String id, name, unit, categoryId;
  final double quantity;
  final DateTime createdAt;
  final bool purchased, converted;
  final String? inventoryId;
  final int revision;
  void validate() {
    if (name.trim().isEmpty ||
        name.length > 100 ||
        !quantity.isFinite ||
        quantity <= 0 ||
        unit.trim().isEmpty ||
        unit.length > 24 ||
        !categoryIds.contains(categoryId)) {
      throw ArgumentError('Invalid shopping item');
    }
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name.trim(),
    'quantity': quantity,
    'unit': unit.trim(),
    'category_id': categoryId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'purchased': purchased ? 1 : 0,
    'converted': converted ? 1 : 0,
    'inventory_id': inventoryId,
    'revision': revision,
  };
  factory ShoppingItem.fromMap(Map<String, Object?> m) => ShoppingItem(
    id: m['id'] as String,
    name: m['name'] as String,
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'] as String,
    categoryId: m['category_id'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    purchased: m['purchased'] == 1,
    converted: m['converted'] == 1,
    inventoryId: m['inventory_id'] as String?,
    revision: m['revision'] as int,
  );
}

String normalizedFoodName(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'[\u064B-\u065F\u0640]'), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

/// A consumed batch is a suggestion only when no other available batch with
/// that identity remains. Discarding alone does not prove consumption.
List<FoodItem> restockSuggestions(
  List<FoodItem> foods,
  List<ShoppingItem> shopping,
) {
  String key(FoodItem f) => f.barcode?.isNotEmpty == true
      ? 'barcode:${f.barcode}'
      : 'name:${normalizedFoodName(f.name)}';
  final active = foods
      .where((f) => f.status == FoodStatus.available)
      .map(key)
      .toSet();
  final listed = shopping
      .where((s) => !s.purchased)
      .map((s) => normalizedFoodName(s.name))
      .toSet();
  final used = foods.where((f) => f.status == FoodStatus.used).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final result = <FoodItem>[];
  final seen = <String>{};
  for (final f in used) {
    if (!active.contains(key(f)) &&
        !listed.contains(normalizedFoodName(f.name)) &&
        seen.add(key(f))) {
      result.add(f);
    }
  }
  return result;
}
