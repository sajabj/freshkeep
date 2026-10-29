import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/content_frame.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../recipes/application/recipe_controller.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../shopping/domain/shopping_item.dart';
import '../application/meal_plan_controller.dart';
import '../domain/meal_plan.dart';

String _m(BuildContext c, String ar, String en) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});
  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerState();
}

class _MealPlannerState extends ConsumerState<MealPlannerScreen> {
  bool ready = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ready) {
      ready = true;
      final start = weekStart(
        DateTime.now(),
        MaterialLocalizations.of(context).firstDayOfWeekIndex,
      );
      Future.microtask(
        () => ref.read(mealPlanWeekProvider.notifier).set(start),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = ref.watch(mealPlanWeekProvider);
    final plans = ref.watch(mealPlansProvider);
    final recipes = ref.watch(recipesProvider).asData?.value ?? [];
    final byId = {for (final r in recipes) r.id: r};
    return Scaffold(
      appBar: AppBar(
        title: Text(_m(context, 'مخطط وجباتي', 'My Meal Planner')),
      ),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(mealPlansProvider),
            child: Text(_m(context, 'إعادة المحاولة', 'Try again')),
          ),
        ),
        data: (entries) => ContentFrame(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: _m(context, 'الأسبوع السابق', 'Previous week'),
                  onPressed: () => _move(-7),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(start)} – ${DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(start.add(const Duration(days: 6)))}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: _today,
                        child: Text(_m(context, 'هذا الأسبوع', 'Current week')),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _m(context, 'الأسبوع التالي', 'Next week'),
                  onPressed: () => _move(7),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Text(
              _m(
                context,
                'يبدأ الأسبوع وفق إعداد اللغة والمنطقة في جهازك.',
                'The week starts according to your device locale.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (var d = 0; d < 7; d++)
              _dayCard(
                context,
                start.add(Duration(days: d)),
                entries,
                byId,
                recipes,
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('weekly-requirements'),
              onPressed: entries.isEmpty
                  ? null
                  : () => _requirements(entries, recipes),
              icon: const Icon(Icons.checklist),
              label: Text(
                _m(context, 'احتياجات الأسبوع', 'Weekly requirements'),
              ),
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _m(
                        context,
                        'أسبوعك فارغ. اختر وصفة لأول وجبة.',
                        'Your week is empty. Choose a recipe for your first meal.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _move(int days) => ref
      .read(mealPlanWeekProvider.notifier)
      .set(ref.read(mealPlanWeekProvider).add(Duration(days: days)));
  void _today() => ref
      .read(mealPlanWeekProvider.notifier)
      .set(
        weekStart(
          DateTime.now(),
          MaterialLocalizations.of(context).firstDayOfWeekIndex,
        ),
      );
  Widget _dayCard(
    BuildContext c,
    DateTime date,
    List<MealPlanEntry> entries,
    Map<String, Recipe> byId,
    List<Recipe> recipes,
  ) {
    final lang = Localizations.localeOf(c).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d', lang).format(date),
                style: Theme.of(c).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final slot in MealSlot.values)
                Builder(
                  builder: (context) {
                    final matches = entries.where(
                      (e) =>
                          e.date.year == date.year &&
                          e.date.month == date.month &&
                          e.date.day == date.day &&
                          e.slot == slot,
                    );
                    final plan = matches.firstOrNull;
                    final recipe = plan == null ? null : byId[plan.recipeId];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(_slotIcon(slot)),
                      title: Text(_slot(c, slot)),
                      subtitle: plan == null
                          ? Text(_m(c, 'اختر وصفة', 'Choose a recipe'))
                          : Text(
                              recipe?.name(lang) ??
                                  _m(
                                    c,
                                    'الوصفة لم تعد متاحة',
                                    'Recipe no longer available',
                                  ),
                            ),
                      onTap: () => _pick(date, slot, plan, recipes),
                      trailing: plan == null
                          ? const Icon(Icons.add_circle_outline)
                          : PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'open' && recipe != null) {
                                  Navigator.push(
                                    c,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RecipeDetailScreen(recipe: recipe),
                                    ),
                                  );
                                }
                                if (v == 'remove') {
                                  removeMealPlan(ref, date, slot);
                                }
                              },
                              itemBuilder: (_) => [
                                if (recipe != null)
                                  PopupMenuItem(
                                    value: 'open',
                                    child: Text(
                                      _m(c, 'فتح الوصفة', 'Open recipe'),
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Text(_m(c, 'إزالة', 'Remove')),
                                ),
                              ],
                            ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(
    DateTime date,
    MealSlot slot,
    MealPlanEntry? existing,
    List<Recipe> recipes,
  ) async {
    final result = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _m(c, 'اختر وصفة', 'Choose a recipe'),
              style: Theme.of(c).textTheme.titleLarge,
            ),
            for (final r in recipes)
              ListTile(
                title: Text(r.name(Localizations.localeOf(c).languageCode)),
                subtitle: Text(
                  _m(c, '${r.servings} حصص', '${r.servings} servings'),
                ),
                onTap: () => Navigator.pop(c, r),
              ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      await saveMealPlan(
        ref,
        existing: existing,
        date: date,
        slot: slot,
        recipeId: result.id,
        servings: result.servings.toDouble(),
      );
    }
  }

  Future<void> _requirements(
    List<MealPlanEntry> plans,
    List<Recipe> recipes,
  ) async {
    final inventory = ref.read(inventoryProvider).asData?.value ?? [];
    final req = weeklyRequirements(plans, recipes, inventory, DateTime.now());
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _RequirementsSheet(requirements: req),
    );
  }
}

String _slot(BuildContext c, MealSlot s) => switch (s) {
  MealSlot.breakfast => _m(c, 'فطور', 'Breakfast'),
  MealSlot.lunch => _m(c, 'غداء', 'Lunch'),
  MealSlot.dinner => _m(c, 'عشاء', 'Dinner'),
};
IconData _slotIcon(MealSlot s) => switch (s) {
  MealSlot.breakfast => Icons.free_breakfast_outlined,
  MealSlot.lunch => Icons.lunch_dining_outlined,
  MealSlot.dinner => Icons.dinner_dining_outlined,
};

class _RequirementsSheet extends ConsumerStatefulWidget {
  const _RequirementsSheet({required this.requirements});
  final List<WeeklyRequirement> requirements;
  @override
  ConsumerState<_RequirementsSheet> createState() => _RequirementsState();
}

class _RequirementsState extends ConsumerState<_RequirementsSheet> {
  late final selected = {
    for (final r in widget.requirements)
      if (r.missing > 0) r.key: true,
  };
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = NumberFormat.decimalPattern(lang);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              _m(
                context,
                'مراجعة احتياجات الأسبوع',
                'Review weekly requirements',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _m(
                context,
                'تُجمع الوحدات المتوافقة فقط. الكميات غير القابلة للمقارنة موضحة كغير مؤكدة. لا يُخصم شيء من المخزون.',
                'Only compatible units are merged. Non-comparable stock is marked uncertain. Inventory is never deducted.',
              ),
            ),
            const SizedBox(height: 12),
            for (final r in widget.requirements)
              CheckboxListTile(
                value: selected[r.key] ?? false,
                onChanged: r.missing <= 0
                    ? null
                    : (v) => setState(() => selected[r.key] = v ?? false),
                title: Text(lang == 'ar' ? r.ar : r.en),
                subtitle: Text(
                  '${_m(context, 'مطلوب', 'Needed')}: ${fmt.format(r.amount)} ${r.unit} · ${_m(context, 'متوفر محسوب', 'Measured stock')}: ${fmt.format(r.stock)} ${r.unit}${r.uncertain ? _m(context, ' · توجد كمية بوحدة غير متوافقة', ' · some stock has an incompatible unit') : ''}',
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _add(),
              child: Text(
                _m(
                  context,
                  'أضف العناصر المحددة إلى المشتريات',
                  'Add selected items to shopping',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add() async {
    final language = Localizations.localeOf(context).languageCode;
    final current = ref.read(shoppingProvider).asData?.value ?? [];
    final existing = current
        .where((e) => !e.purchased)
        .map(
          (e) =>
              '${normalizedFoodName(e.name)}|${normalizedAmount(e.unit, e.quantity).$1}',
        )
        .toSet();
    for (final r in widget.requirements.where(
      (r) => r.missing > 0 && (selected[r.key] ?? false),
    )) {
      final name = language == 'ar' ? r.ar : r.en;
      final key = '${normalizedFoodName(name)}|${r.unit}';
      if (existing.add(key)) {
        await ref
            .read(shoppingProvider.notifier)
            .save(
              ShoppingItem(
                id: const Uuid().v4(),
                name: name,
                quantity: r.missing,
                unit: r.unit,
                categoryId: _categoryFor(r.key),
                createdAt: DateTime.now(),
              ),
              isNew: true,
            );
      }
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _m(
              context,
              'تمت إضافة العناصر الجديدة دون تغيير المخزون.',
              'New items added without changing inventory.',
            ),
          ),
        ),
      );
    }
  }

  String _categoryFor(String key) {
    final k = key.split('|').first;
    if ({'milk', 'yogurt', 'cheese'}.contains(k)) {
      return 'dairy';
    }
    if ({'egg', 'chicken', 'meat', 'fish'}.contains(k)) {
      return 'meat';
    }
    if ({'apple', 'banana', 'lemon'}.contains(k)) {
      return 'fruit';
    }
    if ({'rice', 'pasta', 'oats', 'bread', 'lentils', 'couscous'}.contains(k)) {
      return 'grains';
    }
    return 'vegetables';
  }
}
