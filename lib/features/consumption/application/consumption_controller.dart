import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/clock.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../statistics/application/statistics_provider.dart';
import '../data/consumption_repository.dart';
import '../domain/consumption.dart';

final consumptionRepositoryProvider = FutureProvider<ConsumptionRepository>(
  (ref) async =>
      ConsumptionRepository(await ref.watch(appDatabaseProvider.future)),
);

final consumptionControllerProvider = Provider<ConsumptionController>(
  ConsumptionController.new,
);

class ConsumptionController {
  ConsumptionController(this.ref);
  final Ref ref;
  Future<void> _queue = Future.value();

  Future<ConsumptionOperation> apply(ConsumptionRequest request) {
    late ConsumptionOperation result;
    final task = _queue.then((_) async {
      final repo = await ref.read(consumptionRepositoryProvider.future);
      result = await repo.apply(request);
      ref.invalidate(inventoryProvider);
      ref.invalidate(statisticsProvider);
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task.then((_) => result);
  }

  Future<void> undo(String operationId) {
    final task = _queue.then((_) async {
      final repo = await ref.read(consumptionRepositoryProvider.future);
      await repo.undo(operationId, ref.read(clockProvider)());
      ref.invalidate(inventoryProvider);
      ref.invalidate(statisticsProvider);
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }
}
