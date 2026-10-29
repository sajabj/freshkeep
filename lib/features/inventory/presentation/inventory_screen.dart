import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/inventory_controller.dart';
import '../domain/food_item.dart';
import '../domain/inventory_query.dart';
import 'food_actions.dart';
import 'food_detail_screen.dart';
import 'food_form_screen.dart';
import 'food_labels.dart';
import 'food_tile.dart';
import 'inventory_feedback.dart';
import 'inventory_filters.dart';
import 'inventory_loading.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  InventoryQuery _query = const InventoryQuery();
  bool _compact = false;
  String? _busy;
  Future<void> _action(FoodItem item, String action) async {
    setState(() => _busy = item.id);
    try {
      await performFoodAction(context, ref, item, action);
    } catch (e) {
      if (mounted) inventoryFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final inventory = ref.watch(inventoryProvider);
    final today = ref.watch(todayProvider);
    final visible = _query.apply(inventory.asData?.value ?? []);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const Key('add-food'),
                      onPressed: _busy != null
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const FoodFormScreen(),
                              ),
                            ),
                      icon: const Icon(Icons.add),
                      label: Text(l.addFood),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('search-food'),
                            decoration: InputDecoration(
                              labelText: l.searchFood,
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(
                              () => _query = InventoryQuery(
                                search: v,
                                category: _query.category,
                                storage: _query.storage,
                                sort: _query.sort,
                                status: _query.status,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l.filters,
                          onPressed: () async {
                            final query = await showInventoryFilters(
                              context,
                              _query,
                            );
                            if (mounted && query != null) {
                              setState(() => _query = query);
                            }
                          },
                          icon: Icon(
                            Icons.filter_list,
                            color:
                                _query.category != null ||
                                    _query.storage != null
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final status in FoodStatus.values)
                          ChoiceChip(
                            key: Key('status-${status.name}'),
                            label: Text(statusLabel(l, status)),
                            selected: _query.status == status,
                            onSelected: (_) => setState(
                              () => _query = InventoryQuery(
                                search: _query.search,
                                category: _query.category,
                                storage: _query.storage,
                                sort: _query.sort,
                                status: status,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: _compact ? l.cardView : l.listView,
                          onPressed: () => setState(() => _compact = !_compact),
                          icon: Icon(
                            _compact
                                ? Icons.view_agenda_outlined
                                : Icons.view_list_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (inventory.hasValue)
                      Text(
                        l.matchingCount(visible.length),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
            if (inventory.isLoading)
              const SliverPadding(
                padding: EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(child: InventoryLoading()),
              )
            else if (inventory.hasError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(l.inventoryError),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(inventoryRepositoryProvider);
                          ref.invalidate(inventoryProvider);
                        },
                        child: Text(l.retry),
                      ),
                    ],
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        inventory.requireValue.isEmpty
                            ? l.emptyInventory
                            : l.noMatches,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (inventory.requireValue.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text(l.emptyInventoryBody),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = visible[i];
                    return FoodTile(
                      key: ValueKey(item.id),
                      item: item,
                      today: today,
                      compact: _compact,
                      busy: _busy != null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FoodDetailScreen(id: item.id),
                        ),
                      ),
                      onAction: (action) => _action(item, action),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
