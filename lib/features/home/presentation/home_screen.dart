import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/time/clock.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/fresh_entrance.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../inventory/domain/food_item.dart';
import '../../inventory/domain/inventory_query.dart';
import '../../inventory/presentation/food_detail_screen.dart';
import '../../inventory/presentation/food_form_screen.dart';
import '../../inventory/presentation/food_tile.dart';
import '../../inventory/presentation/food_photo.dart';
import '../../inventory/presentation/inventory_loading.dart';
import '../../meal_planner/presentation/meal_planner_screen.dart';
import '../../storage_guide/presentation/storage_guide_screen.dart';
import '../../cooking_timers/presentation/cooking_timers_screen.dart';
import '../../recipes/presentation/custom_recipe_form_screen.dart';
import '../../recipes/presentation/recipes_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.openInventory});
  final VoidCallback openInventory;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hour = ref.watch(clockProvider)().hour;
    final today = ref.watch(todayProvider);
    final inventory = ref.watch(inventoryProvider);
    final items = inventory.asData?.value ?? [];
    final available =
        items.where((i) => i.status == FoodStatus.available).toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    final soon = available.where((i) {
      final days = daysUntil(i.expiryDate, today);
      return days >= 0 && days <= 7;
    }).toList();
    final past = available
        .where((i) => daysUntil(i.expiryDate, today) < 0)
        .length;
    final used = items.where((i) => i.status == FoodStatus.used).length;
    final useFirst = useFirstItems(items, today);
    final numbers = NumberFormat.decimalPattern(l.localeName);
    return ContentFrame(
      children: [
        FreshEntrance(
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainer
                  : const Color(0xFFE7F2DD),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hour < 12
                            ? l.morning
                            : hour < 18
                            ? l.afternoon
                            : l.evening,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l.homeTitle, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      Text(
                        l.homeBody,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('home-add-food'),
                        onPressed: inventory.hasValue
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const FoodFormScreen(),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.add),
                        label: Text(l.addFood),
                      ),
                    ],
                  ),
                ),
                if (MediaQuery.sizeOf(context).width >= 400 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
                  const SizedBox(width: 16),
                  const FoodPhoto(name: '', size: 112, borderRadius: 56),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 21;
            final columns = constraints.maxWidth >= 300 && !largeText ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ToolCard(
                  width: width,
                  icon: Icons.fitness_center,
                  title: l.localeName == 'ar'
                      ? 'وجبات الرياضيين'
                      : 'Fitness Meals',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: Text(
                            l.localeName == 'ar'
                                ? 'وجبات الرياضيين'
                                : 'Fitness Meals',
                          ),
                        ),
                        body: const SafeArea(
                          child: RecipesScreen(initialFitnessOnly: true),
                        ),
                      ),
                    ),
                  ),
                ),
                _ToolCard(
                  width: width,
                  icon: Icons.kitchen_outlined,
                  title: l.localeName == 'ar'
                      ? 'دليل حفظ الطعام'
                      : 'Food Storage Guide',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StorageGuideScreen(),
                    ),
                  ),
                ),
                _ToolCard(
                  width: width,
                  icon: Icons.calendar_month_outlined,
                  title: l.localeName == 'ar'
                      ? 'مخطط وجباتي'
                      : 'My Meal Planner',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MealPlannerScreen(),
                    ),
                  ),
                ),
                _ToolCard(
                  width: width,
                  icon: Icons.restaurant_menu,
                  title: l.localeName == 'ar' ? 'وصفاتي الخاصة' : 'My Recipes',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomRecipeFormScreen(),
                    ),
                  ),
                ),
                _ToolCard(
                  width: width,
                  icon: Icons.timer_outlined,
                  title: l.localeName == 'ar'
                      ? 'مؤقتات الطبخ'
                      : 'Cooking Timers',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CookingTimersScreen(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        if (inventory.isLoading)
          const InventoryLoading()
        else if (inventory.hasError) ...[
          Text(l.inventoryError),
          TextButton(
            onPressed: () {
              ref.invalidate(inventoryRepositoryProvider);
              ref.invalidate(inventoryProvider);
            },
            child: Text(l.retry),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _Counts(
                format: numbers,
                values: [
                  (l.availableCount, available.length),
                  (l.soonCount, soon.length),
                  (l.pastCount, past),
                  (l.usedCount, used),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(l.useFirst, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (available.isEmpty) ...[
            Text(l.emptyInventory),
            const SizedBox(height: 8),
            Text(l.emptyInventoryBody),
          ] else ...[
            if (soon.isEmpty) Text(l.noUrgent),
            for (final item in useFirst)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FoodTile(
                  item: item,
                  today: today,
                  compact: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FoodDetailScreen(id: item.id),
                    ),
                  ),
                ),
              ),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: openInventory,
              child: Text(l.viewInventory),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.dateHelp, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.values, required this.format});
  final List<(String, int)> values;
  final NumberFormat format;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 280 &&
              MediaQuery.textScalerOf(context).scale(16) <= 20
          ? 2
          : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final value in values)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 16) / columns,
              child: columns == 2
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value.$1),
                        Text(
                          format.format(value.$2),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: Text(value.$1)),
                        const SizedBox(width: 16),
                        Text(
                          format.format(value.$2),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
            ),
        ],
      );
    },
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final double width;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 126,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 23,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
