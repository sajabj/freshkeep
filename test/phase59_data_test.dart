import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/meal_planner/domain/meal_plan.dart';
import 'package:freshkeep/features/recipes/data/recipe_repository.dart';
import 'package:freshkeep/features/recipes/domain/recipe.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/food_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('bundled fitness library contains 20 unique bilingual recipes in four groups', () async {
    final decoded = jsonDecode(
      await rootBundle.loadString('assets/recipes/fitness_recipes.json'),
    ) as List<dynamic>;
    final recipes = decoded
        .map((row) => Recipe(row as Map<String, dynamic>))
        .toList();
    expect(recipes, hasLength(20));
    expect(recipes.map((r) => r.id).toSet(), hasLength(20));
    expect(
      {for (final r in recipes) r.fitnessGroup},
      {'protein', 'preWorkout', 'postWorkout', 'snacks'},
    );
    for (final group in ['protein', 'preWorkout', 'postWorkout', 'snacks']) {
      expect(recipes.where((r) => r.fitnessGroup == group), hasLength(5));
    }
    for (final recipe in recipes) {
      expect(recipe.ar, isNotEmpty);
      expect(recipe.en, isNotEmpty);
      expect(recipe.descriptionAr, isNotEmpty);
      expect(recipe.descriptionEn, isNotEmpty);
      expect(recipe.ingredients.length, greaterThanOrEqualTo(3));
      expect(recipe.stepsAr.length, recipe.stepsEn.length);
      expect(recipe.nutrition, isNotNull);
      expect(recipe.nutrition!.calories, greaterThan(0));
      expect(recipe.nutrition!.protein, greaterThan(0));
      expect(recipe.nutrition!.source, contains('USDA FoodData Central'));
      expect(recipe.nutrition!.reviewedOn, '2026-10-21');
    }
  });

  test('repository inserts new fitness ids without replacing original or favorite state', () async {
    final db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    addTearDown(db.close);
    final repo = RecipeRepository(db);
    var recipes = await repo.load();
    expect(recipes.where((r) => !r.personal && !r.isFitness), hasLength(12));
    expect(recipes.where((r) => r.isFitness), hasLength(20));
    await repo.favorite('fitness-chicken-rice-veg', true);
    recipes = await RecipeRepository(db).load();
    expect(
      recipes.singleWhere((r) => r.id == 'fitness-chicken-rice-veg').favorite,
      isTrue,
    );
    expect(await db.getVersion(), 7);
  });

  test(
    'fitness recipes reuse inventory matching and exclude expired food',
    () async {
      final decoded = jsonDecode(
        await rootBundle.loadString('assets/recipes/fitness_recipes.json'),
      ) as List<dynamic>;
      final recipe = decoded
          .map((row) => Recipe(row as Map<String, dynamic>))
          .singleWhere((r) => r.id == 'fitness-banana-milk-oatmeal');
      final now = DateTime(2026, 10, 21);
      final matches = matchRecipe(recipe, [
        foodFixture(id: 'oats', name: 'Oats', quantity: 100, unit: 'g'),
        foodFixture(id: 'milk', name: 'Milk', quantity: .4, unit: 'l'),
        foodFixture(
          id: 'banana',
          name: 'Banana',
          quantity: 300,
          unit: 'g',
          expiry: DateTime(2026, 10, 20),
        ),
      ], now);
      expect(
        matches.singleWhere((m) => m.ingredient.key == 'oats').availability,
        IngredientAvailability.enough,
      );
      expect(
        matches.singleWhere((m) => m.ingredient.key == 'milk').availability,
        IngredientAvailability.enough,
      );
      expect(
        matches.singleWhere((m) => m.ingredient.key == 'banana').availability,
        IngredientAvailability.missing,
      );
    },
  );

  test(
    'fitness ids can be referenced by the existing weekly meal planner',
    () async {
      final decoded = jsonDecode(
        await rootBundle.loadString('assets/recipes/fitness_recipes.json'),
      ) as List<dynamic>;
      final recipes = decoded
          .map((row) => Recipe(row as Map<String, dynamic>))
          .toList();
      final plan = MealPlanEntry(
        id: 'fitness-plan',
        date: DateTime(2026, 10, 21),
        slot: MealSlot.lunch,
        recipeId: 'fitness-chicken-rice-veg',
        servings: 2,
        createdAt: DateTime(2026, 10, 21),
        updatedAt: DateTime(2026, 10, 21),
      );
      final requirements = weeklyRequirements(
        [plan],
        recipes,
        const <FoodItem>[],
        DateTime(2026, 10, 21),
      );
      expect(requirements, isNotEmpty);
      expect(requirements.any((r) => r.key.startsWith('chicken|')), isTrue);
    },
  );
}
