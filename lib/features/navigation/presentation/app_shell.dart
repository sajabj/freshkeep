import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/application/reminder_controller.dart';

import '../../../core/widgets/brand_mark.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/home_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../recipes/presentation/recipes_screen.dart';
import '../../statistics/presentation/statistics_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shopping/presentation/shopping_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  final _visited = <int>{0};
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(reminderRefreshProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
    final l = AppLocalizations.of(context);
    final titles = [l.home, l.inventory, l.recipes, l.statistics];
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 30),
              const SizedBox(width: 8),
              Flexible(child: Text(_index == 0 ? 'FreshKeep' : titles[_index])),
            ],
          ),
          actions: [
            IconButton(
              key: const Key('open-shopping'),
              tooltip: l.shopping,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ShoppingScreen()),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
            IconButton(
              key: const Key('open-settings'),
              tooltip: l.settings,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.tune_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              HomeScreen(
                openInventory: () => setState(() {
                  _visited.add(1);
                  _index = 1;
                }),
              ),
              _visited.contains(1) ? const InventoryScreen() : const SizedBox(),
              _visited.contains(2) ? const RecipesScreen() : const SizedBox(),
              _visited.contains(3)
                  ? const StatisticsScreen()
                  : const SizedBox(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() {
            _visited.add(value);
            _index = value;
          }),
          destinations: [
            NavigationDestination(
              key: const Key('nav-home'),
              icon: const Icon(Icons.home_outlined),
              label: l.home,
            ),
            NavigationDestination(
              key: const Key('nav-inventory'),
              icon: const Icon(Icons.kitchen_outlined),
              label: l.inventory,
            ),
            NavigationDestination(
              key: const Key('nav-recipes'),
              icon: const Icon(Icons.menu_book_outlined),
              label: l.recipes,
            ),
            NavigationDestination(
              key: const Key('nav-statistics'),
              icon: const Icon(Icons.insights_outlined),
              label: l.statistics,
            ),
          ],
        ),
      ),
    );
  }
}
