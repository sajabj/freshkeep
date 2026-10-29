import '../../inventory/domain/food_item.dart';
import '../../shopping/domain/shopping_item.dart';

class RecipeIngredient {
  RecipeIngredient(Map<String, dynamic> m)
    : key = m['key'] as String,
      ar = m['ar'] as String,
      en = m['en'] as String,
      amount = (m['amount'] as num).toDouble(),
      unit = m['unit'] as String,
      aliases = [
        m['ar'] as String,
        m['en'] as String,
        ...List<String>.from(m['aliases'] as List),
      ];
  final String key, ar, en, unit;
  final double amount;
  final List<String> aliases;
  String name(String language) => language == 'ar' ? ar : en;
}

class RecipeNutrition {
  RecipeNutrition(Map<String, dynamic> m)
    : calories = (m['calories'] as num).toDouble(),
      protein = (m['protein'] as num).toDouble(),
      carbohydrates = (m['carbohydrates'] as num).toDouble(),
      fat = (m['fat'] as num).toDouble(),
      source = m['source'] as String,
      sourceUrl = m['sourceUrl'] as String,
      reviewedOn = m['reviewedOn'] as String,
      basisAr = m['basisAr'] as String,
      basisEn = m['basisEn'] as String;

  final double calories, protein, carbohydrates, fat;
  final String source, sourceUrl, reviewedOn, basisAr, basisEn;
  String basis(String language) => language == 'ar' ? basisAr : basisEn;
}

class Recipe {
  Recipe(Map<String, dynamic> m, {this.favorite = false})
    : id = m['id'] as String,
      ar = m['ar'] as String,
      en = m['en'] as String,
      minutes = m['minutes'] as int,
      prepMinutes = (m['prepMinutes'] as num?)?.toInt() ?? m['minutes'] as int,
      cookMinutes = (m['cookMinutes'] as num?)?.toInt(),
      servings = m['servings'] as int,
      category = m['category'] as String,
      art = (m['art'] as String?) ?? 'custom',
      description = (m['description'] as String?) ?? '',
      descriptionAr =
          (m['descriptionAr'] as String?) ??
          (m['description'] as String?) ??
          '',
      descriptionEn =
          (m['descriptionEn'] as String?) ??
          (m['description'] as String?) ??
          '',
      imagePath = m['imagePath'] as String?,
      personal = m['personal'] == true,
      fitnessGroup = m['fitnessGroup'] as String?,
      nutrition = m['nutrition'] == null
          ? null
          : RecipeNutrition(m['nutrition'] as Map<String, dynamic>),
      allergensAr = List<String>.from(m['allergensAr'] as List? ?? const []),
      allergensEn = List<String>.from(m['allergensEn'] as List? ?? const []),
      ingredients = (m['ingredients'] as List)
          .map((i) => RecipeIngredient(i as Map<String, dynamic>))
          .toList(),
      stepsAr = List<String>.from(m['stepsAr'] as List),
      stepsEn = List<String>.from(m['stepsEn'] as List);
  final String id, ar, en, category, art, description;
  final String descriptionAr, descriptionEn;
  final String? imagePath;
  final String? fitnessGroup;
  final RecipeNutrition? nutrition;
  final int minutes, prepMinutes, servings;
  final int? cookMinutes;
  final bool personal;
  final bool favorite;
  final List<RecipeIngredient> ingredients;
  final List<String> stepsAr, stepsEn;
  final List<String> allergensAr, allergensEn;
  String name(String language) => language == 'ar' ? ar : en;
  String localizedDescription(String language) =>
      language == 'ar' ? descriptionAr : descriptionEn;
  List<String> steps(String language) => language == 'ar' ? stepsAr : stepsEn;
  List<String> allergens(String language) =>
      language == 'ar' ? allergensAr : allergensEn;
  bool get isFitness => fitnessGroup != null;
}

enum IngredientAvailability { enough, partial, unmeasured, missing }

class IngredientMatch {
  IngredientMatch(
    this.ingredient,
    this.foods,
    this.amount,
    this.availability,
    this.urgency,
  );
  final RecipeIngredient ingredient;
  final List<FoodItem> foods;
  final double amount;
  final IngredientAvailability availability;
  final int urgency;
}

(String, double) normalizedAmount(String unit, double quantity) {
  final u = normalizedFoodName(unit);
  return switch (u) {
    'kg' || 'كغ' || 'كجم' || 'كيلوغرام' => ('g', quantity * 1000),
    'g' || 'غ' || 'غرام' || 'جرام' => ('g', quantity),
    'l' || 'ل' || 'لتر' => ('ml', quantity * 1000),
    'cl' => ('ml', quantity * 10),
    'ml' || 'مل' || 'ملليلتر' => ('ml', quantity),
    'pcs' ||
    'pc' ||
    'piece' ||
    'pieces' ||
    'حبة' ||
    'حبات' ||
    'قطعة' ||
    'قطع' => ('pcs', quantity),
    'tbsp' || 'ملعقة كبيرة' => ('tbsp', quantity),
    'tsp' || 'ملعقة صغيرة' => ('tsp', quantity),
    _ => (u, quantity),
  };
}

List<IngredientMatch> matchRecipe(
  Recipe recipe,
  List<FoodItem> inventory,
  DateTime now,
) => recipe.ingredients.map((i) {
  final names = i.aliases.map(normalizedFoodName).toSet();
  final foods = inventory
      .where(
        (f) =>
            f.status == FoodStatus.available &&
            daysUntil(f.expiryDate, now) >= 0 &&
            names.contains(normalizedFoodName(f.name)),
      )
      .toList();
  final target = normalizedAmount(i.unit, i.amount);
  var total = 0.0;
  var urgency = 0;
  for (final food in foods) {
    final value = normalizedAmount(food.unit, food.quantity);
    if (value.$1 == target.$1) {
      total += value.$2;
      final days = daysUntil(food.expiryDate, now);
      if (days <= 7) urgency += 8 - days;
    }
  }
  final status = total >= target.$2
      ? IngredientAvailability.enough
      : total > 0
      ? IngredientAvailability.partial
      : foods.isNotEmpty
      ? IngredientAvailability.unmeasured
      : IngredientAvailability.missing;
  return IngredientMatch(i, foods, total, status, urgency);
}).toList();

List<Recipe> rankedRecipes(
  List<Recipe> recipes,
  List<FoodItem> inventory,
  DateTime now,
) {
  final result = [...recipes];
  final scores = {for (final r in result) r.id: matchRecipe(r, inventory, now)};
  int score(Recipe r) => scores[r.id]!.fold(
    0,
    (n, m) =>
        n +
        m.urgency * 100 +
        (m.availability == IngredientAvailability.enough ? 5 : 0),
  );
  result.sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    return byScore != 0 ? byScore : a.id.compareTo(b.id);
  });
  return result;
}
