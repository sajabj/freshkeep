import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../inventory/presentation/inventory_feedback.dart';
import '../../shopping/presentation/shopping_form_screen.dart';
import '../application/recipe_controller.dart';
import '../domain/recipe.dart';
import 'recipe_art.dart';
import 'custom_recipe_form_screen.dart';
import '../data/recipe_photo_store.dart';
import '../../cooking_timers/presentation/cooking_timers_screen.dart';
import '../../consumption/presentation/cook_recipe_screen.dart';

String ingredientStatus(AppLocalizations l, IngredientAvailability status) =>
    switch (status) {
      IngredientAvailability.enough => l.recipeEnough,
      IngredientAvailability.partial => l.recipePartial,
      IngredientAvailability.unmeasured => l.recipeUnmeasured,
      IngredientAvailability.missing => l.recipeMissing,
    };
String ingredientCategory(String key) => switch (key) {
  'milk' || 'yogurt' || 'cheese' => 'dairy',
  'banana' ||
  'apple' ||
  'lemon' ||
  'strawberry' ||
  'blueberry' ||
  'avocado' ||
  'dates' => 'fruit',
  'oats' ||
  'rice' ||
  'pasta' ||
  'couscous' ||
  'lentils' ||
  'bulgur' ||
  'bread' => 'grains',
  'oil' => 'other',
  'chickpeas' => 'canned',
  'egg' || 'chicken' || 'beef' || 'salmon' || 'tuna' => 'meat',
  'water' => 'drinks',
  _ => 'vegetables',
};

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});
  final Recipe recipe;
  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends ConsumerState<RecipeDetailScreen> {
  bool _busy = false;
  Future<void> _favorite(Recipe recipe) async {
    setState(() => _busy = true);
    try {
      await ref.read(recipesProvider.notifier).favorite(recipe);
    } catch (e) {
      if (mounted) inventoryFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final language = l.localeName;
    final recipe =
        ref
            .watch(recipesProvider)
            .asData
            ?.value
            .where((r) => r.id == widget.recipe.id)
            .firstOrNull ??
        widget.recipe;
    final stock = ref.watch(inventoryProvider).asData?.value;
    final today = ref.watch(todayProvider);
    final matches = stock == null ? null : matchRecipe(recipe, stock, today);
    final number = NumberFormat.decimalPattern(language);
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name(language)),
        actions: [
          IconButton(
            key: const Key('favorite-recipe'),
            tooltip: recipe.favorite
                ? l.recipeFavoriteRemove
                : l.recipeFavoriteAdd,
            onPressed: _busy ? null : () => _favorite(recipe),
            icon: Icon(
              recipe.favorite ? Icons.favorite : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ContentFrame(
          children: [
            RecipeArt(
              recipeId: recipe.id,
              label: recipe.name(language),
              height: 240,
              imagePath: recipe.imagePath,
            ),
            if (recipe.localizedDescription(language).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(recipe.localizedDescription(language)),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: language == 'ar'
                      ? 'تحضير ${recipe.prepMinutes} د'
                      : 'Prep ${recipe.prepMinutes} min',
                ),
                if (recipe.cookMinutes case final cook?)
                  _InfoChip(
                    icon: Icons.soup_kitchen_outlined,
                    label: language == 'ar' ? 'طبخ $cook د' : 'Cook $cook min',
                  ),
                _InfoChip(
                  icon: Icons.people_outline,
                  label: language == 'ar'
                      ? '${recipe.servings} حصص'
                      : '${recipe.servings} servings',
                ),
              ],
            ),
            if (recipe.nutrition case final nutrition?) ...[
              const SizedBox(height: 20),
              _NutritionCard(nutrition: nutrition, language: language),
            ],
            if (recipe.allergens(language).isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          language == 'ar'
                              ? 'مسببات حساسية معروفة: ${recipe.allergens(language).join('، ')}. تحقّق دائمًا من ملصقات المنتجات لتفادي التلوث التبادلي.'
                              : 'Known allergens: ${recipe.allergens(language).join(', ')}. Always check product labels for cross-contact.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l.recipeIngredients,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (stock == null) Text(l.recipeStockUnavailable),
            for (var index = 0; index < recipe.ingredients.length; index++)
              Builder(
                builder: (context) {
                  final ingredient = recipe.ingredients[index];
                  final match = matches?[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ingredient.name(language)} · ${number.format(ingredient.amount)} ${ingredient.unit}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (match != null) ...[
                          Text(ingredientStatus(l, match.availability)),
                          if (match.foods.isNotEmpty)
                            Text(
                              match.foods
                                  .map((f) => f.name)
                                  .toSet()
                                  .join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (match.availability !=
                              IngredientAvailability.enough)
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) {
                                    final requested = normalizedAmount(
                                      ingredient.unit,
                                      ingredient.amount,
                                    );
                                    final scale = normalizedAmount(
                                      ingredient.unit,
                                      1,
                                    ).$2;
                                    final remaining =
                                        (requested.$2 - match.amount) / scale;
                                    return ShoppingFormScreen(
                                      name: ingredient.name(language),
                                      quantity: remaining > 0
                                          ? remaining
                                          : ingredient.amount,
                                      unit: ingredient.unit,
                                      category: ingredientCategory(
                                        ingredient.key,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: Text(
                                match.availability ==
                                        IngredientAvailability.unmeasured
                                    ? l.recipeReviewAmount
                                    : l.recipeAddMissing,
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            Text(l.recipeSteps, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final entry in recipe.steps(language).indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('${number.format(entry.$1 + 1)}. ${entry.$2}'),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('cooked-recipe'),
              onPressed: stock == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CookRecipeScreen(recipe: recipe),
                      ),
                    ),
              icon: const Icon(Icons.restaurant_outlined),
              label: Text(
                language == 'ar' ? 'طبخت هذه الوصفة' : 'I Cooked This',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('start-cooking-timer'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CookingTimersScreen(suggestedMinutes: recipe.cookMinutes),
                ),
              ),
              icon: const Icon(Icons.timer_outlined),
              label: Text(
                language == 'ar' ? 'ابدأ مؤقت الطبخ' : 'Start Cooking Timer',
              ),
            ),
            if (recipe.personal) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomRecipeFormScreen(recipe: recipe),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  language == 'ar' ? 'تعديل وصفتي' : 'Edit my recipe',
                ),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _delete(recipe),
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  language == 'ar' ? 'حذف وصفتي' : 'Delete my recipe',
                ),
              ),
            ],
            Text(
              l.recipeMatchingNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              l.recipeLibraryNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Recipe recipe) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(ar ? 'حذف الوصفة؟' : 'Delete recipe?'),
        content: Text(
          ar
              ? 'سيبقى مرجعها في مخطط الوجبات واضحًا كـ «الوصفة لم تعد متاحة»، وستُحذف صورتها المحلية.'
              : 'Its meal-plan reference will remain visible as “Recipe no longer available”, and its local photo will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(ar ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    final path = await ref
        .read(recipesProvider.notifier)
        .deleteCustom(recipe.id);
    await RecipePhotoStore().delete(path);
    if (mounted) Navigator.pop(context);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(label));
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.nutrition, required this.language});
  final RecipeNutrition nutrition;
  final String language;

  @override
  Widget build(BuildContext context) {
    final ar = language == 'ar';
    final values = [
      (ar ? 'السعرات' : 'Calories', '${nutrition.calories.round()} kcal'),
      (
        ar ? 'البروتين' : 'Protein',
        '${nutrition.protein.toStringAsFixed(1)} g',
      ),
      (
        ar ? 'الكربوهيدرات' : 'Carbs',
        '${nutrition.carbohydrates.toStringAsFixed(1)} g',
      ),
      (ar ? 'الدهون' : 'Fat', '${nutrition.fat.toStringAsFixed(1)} g'),
    ];
    return Card(
      key: const Key('recipe-nutrition-card'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ar
                        ? 'معلومات غذائية تقديرية · للحصة'
                        : 'Estimated nutrition · per serving',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  for (final value in values)
                    SizedBox(
                      width: constraints.maxWidth >= 280
                          ? (constraints.maxWidth - 8) / 2
                          : constraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.$1,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            value.$2,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nutrition.basis(language),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              ar
                  ? '${nutrition.source} · مراجعة ${nutrition.reviewedOn}. القيم تقريبية وتتغير حسب المكونات وطريقة التحضير.'
                  : '${nutrition.source} · reviewed ${nutrition.reviewedOn}. Values are estimates and vary by ingredients and preparation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
