import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../inventory/domain/food_item.dart';
import '../../inventory/presentation/food_form_screen.dart';
import '../../inventory/presentation/food_labels.dart';
import '../../inventory/presentation/food_photo.dart';
import '../../inventory/presentation/inventory_feedback.dart';
import '../application/shopping_controller.dart';
import '../domain/shopping_item.dart';
import 'shopping_form_screen.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});
  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingState();
}

class _ShoppingState extends ConsumerState<ShoppingScreen> {
  int _filter = 0;
  bool _busy = false;
  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) inventoryFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ShoppingItem item) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteShoppingTitle),
        content: Text(l.deleteShoppingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteShopping),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _action(() => ref.read(shoppingProvider.notifier).delete(item));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final value = ref.watch(shoppingProvider);
    final inventory = ref.watch(inventoryProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: Text(l.shopping)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        key: const Key('add-shopping'),
        onPressed: _busy
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShoppingFormScreen()),
              ),
        icon: const Icon(Icons.add),
        label: Text(l.addShopping),
      ),
      body: SafeArea(
        child: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(shoppingProvider),
              child: Text(l.retry),
            ),
          ),
          data: (items) {
            final rows = items
                .where(
                  (i) =>
                      _filter == 0 ||
                      (_filter == 1 ? !i.purchased : i.purchased),
                )
                .toList();
            final suggestions = inventory == null
                ? <FoodItem>[]
                : restockSuggestions(inventory, items);
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in [
                      (0, l.allItems),
                      (1, l.toBuy),
                      (2, l.purchased),
                    ])
                      ChoiceChip(
                        label: Text(e.$2),
                        selected: _filter == e.$1,
                        onSelected: (_) => setState(() => _filter = e.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l.shoppingEmpty),
                  ),
                for (final item in rows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CheckboxListTile(
                            key: Key('purchased-${item.id}'),
                            contentPadding: EdgeInsets.zero,
                            value: item.purchased,
                            secondary: FoodPhoto(
                              name: item.name,
                              categoryId: item.categoryId,
                              size: 56,
                            ),
                            onChanged: _busy || item.converted
                                ? null
                                : (v) => _action(
                                    () => ref
                                        .read(shoppingProvider.notifier)
                                        .purchased(item, v!),
                                  ),
                            title: Text(item.name),
                            subtitle: Text(
                              '${NumberFormat.decimalPattern(l.localeName).format(item.quantity)} ${item.unit} · ${categoryLabel(l, item.categoryId)}',
                            ),
                          ),
                          if (item.converted) Text(l.convertedToInventory),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (!item.converted)
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ShoppingFormScreen(item: item),
                                          ),
                                        ),
                                  child: Text(l.editShopping),
                                ),
                              if (!item.converted)
                                TextButton(
                                  key: Key('convert-${item.id}'),
                                  onPressed: _busy
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => FoodFormScreen(
                                              shoppingItem: item,
                                            ),
                                          ),
                                        ),
                                  child: Text(l.convertToInventory),
                                ),
                              TextButton(
                                onPressed: _busy ? null : () => _delete(item),
                                child: Text(l.deleteShopping),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    l.restockTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(l.restockNote),
                  const SizedBox(height: 12),
                  for (final food in suggestions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: FoodPhoto(
                        path: food.imagePath,
                        name: food.name,
                        categoryId: food.categoryId,
                        size: 52,
                      ),
                      title: Text(food.name),
                      subtitle: Text(categoryLabel(l, food.categoryId)),
                      trailing: IconButton(
                        tooltip: l.addShopping,
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShoppingFormScreen(
                              name: food.name,
                              quantity: food.quantity,
                              unit: food.unit,
                              category: food.categoryId,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
