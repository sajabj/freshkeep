import '../../inventory/domain/food_item.dart';
import '../../recipes/domain/recipe.dart';
import '../../shopping/domain/shopping_item.dart';

enum MealSlot { breakfast, lunch, dinner }

class MealPlanEntry {
  const MealPlanEntry({
    required this.id,
    required this.date,
    required this.slot,
    required this.recipeId,
    required this.servings,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, recipeId;
  final DateTime date, createdAt, updatedAt;
  final MealSlot slot;
  final double servings;
  Map<String, Object?> toMap() => {
    'id': id,
    'meal_date': _day(date),
    'slot': slot.name,
    'recipe_id': recipeId,
    'servings': servings,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
  factory MealPlanEntry.fromMap(Map<String, Object?> m) => MealPlanEntry(
    id: m['id'] as String,
    date: DateTime.parse(m['meal_date'] as String),
    slot: MealSlot.values.byName(m['slot'] as String),
    recipeId: m['recipe_id'] as String,
    servings: (m['servings'] as num).toDouble(),
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime weekStart(DateTime day, int firstDayIndex) {
  final d = DateTime(day.year, day.month, day.day);
  final dartFirst = firstDayIndex == 0 ? DateTime.sunday : firstDayIndex;
  return d.subtract(Duration(days: (d.weekday - dartFirst + 7) % 7));
}

class WeeklyRequirement {
  const WeeklyRequirement({
    required this.key,
    required this.ar,
    required this.en,
    required this.amount,
    required this.unit,
    required this.stock,
    required this.missing,
    required this.uncertain,
  });
  final String key, ar, en, unit;
  final double amount, stock, missing;
  final bool uncertain;
}

/// Aggregates compatible normalized units, then allocates each inventory batch
/// once across the whole week. Expired and unavailable batches are excluded.
List<WeeklyRequirement> weeklyRequirements(
  List<MealPlanEntry> plans,
  List<Recipe> recipes,
  List<FoodItem> inventory,
  DateTime now,
) {
  final byId = {for (final r in recipes) r.id: r};
  final demand =
      <String, ({RecipeIngredient ingredient, double amount, String unit})>{};
  for (final plan in plans) {
    final recipe = byId[plan.recipeId];
    if (recipe == null) continue;
    final factor = plan.servings / recipe.servings;
    for (final ingredient in recipe.ingredients) {
      final n = normalizedAmount(ingredient.unit, ingredient.amount * factor);
      final k = '${ingredient.key}|${n.$1}';
      final old = demand[k];
      demand[k] = (
        ingredient: ingredient,
        amount: (old?.amount ?? 0) + n.$2,
        unit: n.$1,
      );
    }
  }
  final result = <WeeklyRequirement>[];
  for (final entry in demand.entries) {
    final i = entry.value.ingredient;
    final aliases = i.aliases.map(normalizedFoodName).toSet();
    var stock = 0.0;
    var hasNamedIncompatible = false;
    for (final food in inventory.where(
      (f) =>
          f.status == FoodStatus.available &&
          daysUntil(f.expiryDate, now) >= 0 &&
          aliases.contains(normalizedFoodName(f.name)),
    )) {
      final n = normalizedAmount(food.unit, food.quantity);
      if (n.$1 == entry.value.unit) {
        stock += n.$2;
      } else {
        hasNamedIncompatible = true;
      }
    }
    result.add(
      WeeklyRequirement(
        key: entry.key,
        ar: i.ar,
        en: i.en,
        amount: entry.value.amount,
        unit: entry.value.unit,
        stock: stock,
        missing: (entry.value.amount - stock).clamp(0, double.infinity),
        uncertain: hasNamedIncompatible,
      ),
    );
  }
  result.sort((a, b) => b.missing.compareTo(a.missing));
  return result;
}
