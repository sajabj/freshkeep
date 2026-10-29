import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../shopping/domain/shopping_item.dart';
import '../application/recipe_controller.dart';
import '../domain/recipe.dart';
import 'recipe_art.dart';
import 'recipe_detail_screen.dart';
import 'custom_recipe_form_screen.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key, this.initialFitnessOnly = false});
  final bool initialFitnessOnly;
  @override
  ConsumerState<RecipesScreen> createState() => _RecipesState();
}

class _RecipesState extends ConsumerState<RecipesScreen> {
  String _query = '', _category = 'all', _fitnessGroup = 'all';
  bool _favorites = false, _quick = false, _personalOnly = false;
  late bool _fitnessOnly;

  @override
  void initState() {
    super.initState();
    _fitnessOnly = widget.initialFitnessOnly;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final value = ref.watch(recipesProvider);
    final stock = ref.watch(inventoryProvider).asData?.value;
    final today = ref.watch(todayProvider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(recipesProvider),
          child: Text(l.retry),
        ),
      ),
      data: (recipes) {
        final query = normalizedFoodName(_query);
        final rows = rankedRecipes(recipes, stock ?? [], today)
            .where(
              (r) =>
                  (!_favorites || r.favorite) &&
                  (!_personalOnly || r.personal) &&
                  (!_fitnessOnly || r.isFitness) &&
                  (_fitnessGroup == 'all' || r.fitnessGroup == _fitnessGroup) &&
                  (!_quick || r.minutes <= 20) &&
                  (_category == 'all' || r.category == _category) &&
                  (query.isEmpty ||
                      normalizedFoodName(
                        '${r.ar} ${r.en} ${r.ingredients.map((i) => '${i.ar} ${i.en}').join(' ')}',
                      ).contains(query)),
            )
            .toList();
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('recipe-search'),
                      decoration: InputDecoration(
                        labelText: l.recipeSearch,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 14),
                    _FitnessHero(
                      count: recipes.where((r) => r.isFitness).length,
                      selected: _fitnessOnly,
                      onTap: () => setState(() {
                        _fitnessOnly = !_fitnessOnly;
                        _personalOnly = false;
                        if (!_fitnessOnly) _fitnessGroup = 'all';
                      }),
                    ),
                    if (_fitnessOnly) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final group in [
                              ('all', 'الكل', 'All'),
                              ('protein', 'غنية بالبروتين', 'Protein-rich'),
                              ('preWorkout', 'قبل التمرين', 'Pre-workout'),
                              ('postWorkout', 'بعد التمرين', 'Post-workout'),
                              ('snacks', 'سناكات', 'Snacks'),
                            ])
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: ChoiceChip(
                                  key: Key('fitness-group-${group.$1}'),
                                  selected: _fitnessGroup == group.$1,
                                  label: Text(
                                    l.localeName == 'ar' ? group.$2 : group.$3,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _fitnessGroup = group.$1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(
                          l.localeName == 'ar' ? 'وصفاتي الخاصة' : 'My Recipes',
                        ),
                        subtitle: Text(
                          l.localeName == 'ar'
                              ? '${recipes.where((r) => r.personal).length} وصفة محفوظة محليًا'
                              : '${recipes.where((r) => r.personal).length} saved locally',
                        ),
                        trailing: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CustomRecipeFormScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(l.localeName == 'ar' ? 'إضافة' : 'Add'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          key: const Key('recipes-favorites'),
                          selected: _favorites,
                          label: Text(l.recipeFavorites),
                          onSelected: (v) => setState(() => _favorites = v),
                        ),
                        FilterChip(
                          key: const Key('recipes-personal'),
                          selected: _personalOnly,
                          label: Text(
                            l.localeName == 'ar'
                                ? 'وصفاتي الخاصة'
                                : 'My Recipes',
                          ),
                          onSelected: (v) => setState(() => _personalOnly = v),
                        ),
                        FilterChip(
                          selected: _quick,
                          label: Text(l.recipeQuick),
                          onSelected: (v) => setState(() => _quick = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.categoryField),
                      items: [
                        for (final e in [
                          ('all', l.recipeAll),
                          ('breakfast', l.recipeBreakfast),
                          ('main', l.recipeMain),
                          ('salad', l.recipeSalad),
                          ('soup', l.recipeSoup),
                          ('snack', l.recipeSnack),
                        ])
                          DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                      ],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      stock == null
                          ? l.recipeStockUnavailable
                          : l.recipeRankNote,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.recipeLibraryNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(l.recipeNoResults),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final r = rows[index];
                  final matches = stock == null
                      ? null
                      : matchRecipe(r, stock, today);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: Key('recipe-${r.id}'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipe: r),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RecipeArt(
                                recipeId: r.id,
                                label: r.name(l.localeName),
                                height: 176,
                                imagePath: r.imagePath,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                r.name(l.localeName),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (r.personal)
                                Chip(
                                  label: Text(
                                    l.localeName == 'ar'
                                        ? 'وصفتي الخاصة'
                                        : 'My recipe',
                                  ),
                                  avatar: const Icon(
                                    Icons.person_outline,
                                    size: 18,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Text(l.recipeMeta(r.minutes, r.servings)),
                              if (r.nutrition case final nutrition?) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _MetricPill(
                                      icon:
                                          Icons.local_fire_department_outlined,
                                      label: l.localeName == 'ar'
                                          ? '${nutrition.calories.round()} سعرة/حصة'
                                          : '${nutrition.calories.round()} kcal/serving',
                                    ),
                                    _MetricPill(
                                      icon: Icons.fitness_center,
                                      label: l.localeName == 'ar'
                                          ? '${nutrition.protein.toStringAsFixed(1)} غ بروتين'
                                          : '${nutrition.protein.toStringAsFixed(1)} g protein',
                                    ),
                                  ],
                                ),
                              ],
                              if (matches != null)
                                Text(
                                  l.recipeMatchCount(
                                    matches
                                        .where(
                                          (m) =>
                                              m.availability ==
                                              IngredientAvailability.enough,
                                        )
                                        .length,
                                    matches.length,
                                  ),
                                ),
                              if (r.favorite)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Icon(
                                    Icons.favorite,
                                    semanticLabel: l.recipeFavorites,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FitnessHero extends StatelessWidget {
  const _FitnessHero({
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const Key('fitness-meals-section'),
      color: selected ? colors.primaryContainer : colors.tertiaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colors.surface.withValues(alpha: .88),
                child: Icon(Icons.fitness_center, color: colors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'وجبات الرياضيين' : 'Fitness Meals',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ar
                          ? '$count وصفة ضمن 4 مجموعات مع قيم غذائية تقديرية للحصة'
                          : '$count recipes in 4 groups with estimated per-serving nutrition',
                    ),
                  ],
                ),
              ),
              Icon(selected ? Icons.close : Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(child: Text(label)),
        ],
      ),
    ),
  );
}
