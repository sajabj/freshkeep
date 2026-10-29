import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../inventory/application/inventory_controller.dart';
import '../domain/statistics.dart';

final statisticsProvider = FutureProvider<InventoryStatistics>((ref) async {
  // Reload history after every committed inventory change, including deletions.
  final inventory = ref.watch(inventoryProvider.future);
  final database = ref.watch(appDatabaseProvider.future);
  final (_, db) = await (inventory, database).wait;
  return db.transaction(
    (tx) async => InventoryStatistics.fromRows(
      await tx.query('inventory_events', columns: ['snapshot', 'occurred_at']),
      await tx.query(
        'food_items',
        columns: [
          'id',
          'status',
          'status_changed_at',
          'price',
          'revision',
          'updated_at',
        ],
      ),
    ),
  );
});
