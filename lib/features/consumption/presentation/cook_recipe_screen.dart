import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../inventory/application/inventory_controller.dart';
import '../../inventory/domain/food_item.dart';
import '../../inventory/presentation/inventory_feedback.dart';
import '../../inventory/presentation/food_labels.dart';
import '../../recipes/domain/recipe.dart';
import '../../shopping/domain/shopping_item.dart';
import '../application/consumption_controller.dart';
import '../domain/consumption.dart';

class CookRecipeScreen extends ConsumerStatefulWidget {
  const CookRecipeScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  ConsumerState<CookRecipeScreen> createState() => _CookRecipeScreenState();
}

class _CookRecipeScreenState extends ConsumerState<CookRecipeScreen> {
  late final TextEditingController _servings;
  final Map<String, TextEditingController> _amounts = {};
  final Set<String> _selected = {};
  bool _initialized = false, _busy = false;
  late final String _operationId;

  @override
  void initState() {
    super.initState();
    _servings = TextEditingController(text: widget.recipe.servings.toString());
    _operationId = const Uuid().v4();
  }

  @override
  void dispose() {
    _servings.dispose();
    for (final controller in _amounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _key(int ingredient, String food) => '$ingredient::$food';

  void _initialize(List<FoodItem> stock, DateTime today, {bool force = false}) {
    if (_initialized && !force) return;
    for (final controller in _amounts.values) {
      controller.dispose();
    }
    _amounts.clear();
    _selected.clear();
    final servings =
        parseFoodNumber(_servings.text) ?? widget.recipe.servings.toDouble();
    for (final indexed in widget.recipe.ingredients.indexed) {
      final suggestions = suggestAllocations(
        ingredient: indexed.$2,
        servings: servings,
        recipeServings: widget.recipe.servings,
        inventory: stock,
        today: today,
      );
      for (final food in stock) {
        final aliases = indexed.$2.aliases.map(normalizedFoodName).toSet();
        if (food.status != FoodStatus.available ||
            food.quantity <= 0 ||
            !aliases.contains(normalizedFoodName(food.name)) ||
            convertAmount(1, food.unit, indexed.$2.unit) == null) {
          continue;
        }
        final key = _key(indexed.$1, food.id);
        final amount = suggestions
            .where((value) => value.foodId == food.id)
            .map((value) => value.amount)
            .firstOrNull;
        _amounts[key] = TextEditingController(
          text: amount == null ? '' : _format(amount),
        );
        if (amount != null) _selected.add(key);
      }
    }
    _initialized = true;
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

  List<ConsumptionAllocation> _allocations() {
    final result = <ConsumptionAllocation>[];
    for (final key in _selected) {
      final amount = parseFoodNumber(_amounts[key]!.text);
      if (amount != null && amount > 0) {
        result.add(
          ConsumptionAllocation(foodId: key.split('::').last, amount: amount),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final stockAsync = ref.watch(inventoryProvider);
    final stock = stockAsync.asData?.value;
    final today = ref.watch(todayProvider);
    if (stock != null) _initialize(stock, today);
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'مراجعة خصم الوصفة' : 'Review recipe deduction'),
      ),
      body: stock == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.recipe.name(ar ? 'ar' : 'en'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ar ? 'راجع الدفعات والكميات. لن يُخصم أي مكوّن غير محدد.' : 'Review batches and amounts. Unselected ingredients will not be deducted.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('cooked-servings'),
                    controller: _servings,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: ar ? 'الحصص المحضرة' : 'Servings prepared',
                    ),
                    onSubmitted: (_) =>
                        setState(() => _initialize(stock, today, force: true)),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      key: const Key('recalculate-servings'),
                      onPressed: () => setState(
                        () => _initialize(stock, today, force: true),
                      ),
                      icon: const Icon(Icons.calculate_outlined),
                      label: Text(ar ? 'إعادة الحساب' : 'Recalculate'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final indexed in widget.recipe.ingredients.indexed)
                    _IngredientReview(
                      index: indexed.$1,
                      ingredient: indexed.$2,
                      recipeServings: widget.recipe.servings,
                      preparedServings:
                          parseFoodNumber(_servings.text) ??
                          widget.recipe.servings.toDouble(),
                      stock: stock,
                      today: today,
                      amounts: _amounts,
                      selected: _selected,
                      onChanged: () => setState(() {}),
                      ar: ar,
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('confirm-cooked-recipe'),
                    onPressed: _busy ? null : () => _confirm(ar),
                    icon: const Icon(Icons.restaurant_outlined),
                    label: Text(
                      ar
                          ? 'تأكيد طبخ الوصفة والخصم'
                          : 'Confirm cooking and deduction',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirm(bool ar) async {
    final servings = parseFoodNumber(_servings.text);
    final allocations = _allocations();
    if (servings == null || servings <= 0 || allocations.isEmpty) {
      inventoryFailure(context, const ConsumptionConflict('nothing_selected'));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ar ? 'تأكيد الخصم؟' : 'Confirm deduction?'),
        content: Text(
          ar
              ? 'سيتم الخصم من ${allocations.length} دفعة محددة فقط. يمكن إكمال العملية مع وجود مكونات ناقصة.'
              : 'Only ${allocations.length} selected batches will be deducted. You may continue with missing ingredients.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ar ? 'خصم' : 'Deduct'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final operation = await ref
          .read(consumptionControllerProvider)
          .apply(
            ConsumptionRequest(
              id: _operationId,
              kind: ConsumptionKind.recipe,
              recipeId: widget.recipe.id,
              occurredAt: DateTime.now(),
              allocations: allocations,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'تم خصم المكونات المحددة.' : 'Selected ingredients deducted.',
          ),
          action: SnackBarAction(
            label: ar ? 'تراجع' : 'Undo',
            onPressed: () async {
              try {
                await ref
                    .read(consumptionControllerProvider)
                    .undo(operation.id);
              } catch (error) {
                if (mounted) inventoryFailure(context, error);
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        inventoryFailure(context, error);
      }
    }
  }
}

class _IngredientReview extends StatelessWidget {
  const _IngredientReview({
    required this.index,
    required this.ingredient,
    required this.recipeServings,
    required this.preparedServings,
    required this.stock,
    required this.today,
    required this.amounts,
    required this.selected,
    required this.onChanged,
    required this.ar,
  });
  final int index, recipeServings;
  final double preparedServings;
  final RecipeIngredient ingredient;
  final List<FoodItem> stock;
  final DateTime today;
  final Map<String, TextEditingController> amounts;
  final Set<String> selected;
  final VoidCallback onChanged;
  final bool ar;

  @override
  Widget build(BuildContext context) {
    final keys = amounts.keys
        .where((key) => key.startsWith('$index::'))
        .toList();
    final required = ingredient.amount * preparedServings / recipeServings;
    final chosen = keys.fold<double>(0, (sum, key) {
      if (!selected.contains(key)) return sum;
      final food = stock.firstWhere((item) => item.id == key.split('::').last);
      final value = parseFoodNumber(amounts[key]!.text) ?? 0;
      return sum + (convertAmount(value, food.unit, ingredient.unit) ?? 0);
    });
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ingredient.name(ar ? 'ar' : 'en'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              ar
                  ? 'المطلوب ${_number(required)} ${ingredient.unit} · المحدد ${_number(chosen)} ${ingredient.unit}'
                  : 'Required ${_number(required)} ${ingredient.unit} · selected ${_number(chosen)} ${ingredient.unit}',
            ),
            if (keys.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  ar ? 'ناقص أو لا توجد وحدة متوافقة؛ لن يُخصم.' : 'Missing or no compatible unit; nothing will be deducted.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            for (final key in keys)
              Builder(
                builder: (context) {
                  final food = stock.firstWhere(
                    (item) => item.id == key.split('::').last,
                  );
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected.contains(key),
                    onChanged: (value) {
                      value == true ? selected.add(key) : selected.remove(key);
                      onChanged();
                    },
                    title: Text(
                      '${food.name} · ${_number(food.quantity)} ${food.unit}',
                    ),
                    subtitle: Text(
                      '${ar ? 'الصلاحية' : 'Expiry'} ${DateFormat.yMd(ar ? 'ar' : 'en').format(food.expiryDate)}',
                    ),
                    secondary: SizedBox(
                      width: 92,
                      child: TextField(
                        key: Key('cook-amount-${food.id}-$index'),
                        controller: amounts[key],
                        enabled: selected.contains(key),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(suffixText: food.unit),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _number(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
