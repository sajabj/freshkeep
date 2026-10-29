import '../../inventory/domain/food_item.dart';
import '../../recipes/domain/recipe.dart';
import '../../shopping/domain/shopping_item.dart';

enum ConsumptionKind { manual, recipe }

class ConsumptionAllocation {
  const ConsumptionAllocation({required this.foodId, required this.amount});
  final String foodId;
  final double amount;
}

class ConsumptionRequest {
  const ConsumptionRequest({
    required this.id,
    required this.kind,
    required this.occurredAt,
    required this.allocations,
    this.recipeId,
  });
  final String id;
  final ConsumptionKind kind;
  final DateTime occurredAt;
  final String? recipeId;
  final List<ConsumptionAllocation> allocations;
}

class ConsumptionEntry {
  const ConsumptionEntry({
    required this.foodId,
    required this.foodName,
    required this.amount,
    required this.unit,
    required this.quantityBefore,
    required this.quantityAfter,
  });
  final String foodId, foodName, unit;
  final double amount, quantityBefore, quantityAfter;
}

class ConsumptionOperation {
  const ConsumptionOperation({
    required this.id,
    required this.kind,
    required this.occurredAt,
    required this.undone,
    required this.entries,
    this.recipeId,
  });
  final String id;
  final ConsumptionKind kind;
  final DateTime occurredAt;
  final bool undone;
  final String? recipeId;
  final List<ConsumptionEntry> entries;
}

class ConsumptionConflict implements Exception {
  const ConsumptionConflict(this.reason);
  final String reason;
  @override
  String toString() => 'ConsumptionConflict: $reason';
}

/// Converts only within dimensions that do not require ingredient density.
/// Returns null for incompatible or unknown units.
double? convertAmount(double amount, String from, String to) {
  if (!amount.isFinite || amount < 0) return null;
  final source = normalizedAmount(from, amount);
  final targetUnit = normalizedAmount(to, 1);
  if (source.$1 != targetUnit.$1 || targetUnit.$2 == 0) return null;
  return source.$2 / targetUnit.$2;
}

List<ConsumptionAllocation> suggestAllocations({
  required RecipeIngredient ingredient,
  required double servings,
  required int recipeServings,
  required List<FoodItem> inventory,
  required DateTime today,
}) {
  if (!servings.isFinite || servings <= 0 || recipeServings <= 0) {
    return const [];
  }
  final aliases = ingredient.aliases.map(normalizedFoodName).toSet();
  var remaining = ingredient.amount * servings / recipeServings;
  final candidates =
      inventory
          .where(
            (f) =>
                f.status == FoodStatus.available &&
                f.quantity > 0 &&
                daysUntil(f.expiryDate, today) >= 0 &&
                aliases.contains(normalizedFoodName(f.name)) &&
                convertAmount(1, f.unit, ingredient.unit) != null,
          )
          .toList()
        ..sort((a, b) {
          final byDate = a.expiryDate.compareTo(b.expiryDate);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
  final result = <ConsumptionAllocation>[];
  for (final food in candidates) {
    if (remaining <= 0) break;
    final available = convertAmount(food.quantity, food.unit, ingredient.unit)!;
    final takeInIngredientUnit = remaining < available ? remaining : available;
    final takeInFoodUnit = convertAmount(
      takeInIngredientUnit,
      ingredient.unit,
      food.unit,
    )!;
    if (takeInFoodUnit > 0) {
      result.add(
        ConsumptionAllocation(foodId: food.id, amount: takeInFoodUnit),
      );
      remaining -= takeInIngredientUnit;
    }
  }
  return result;
}
