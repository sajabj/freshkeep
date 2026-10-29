import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/inventory/domain/inventory_repository.dart';
import 'package:freshkeep/core/time/clock.dart';

class MemoryInventoryRepository implements InventoryRepository {
  MemoryInventoryRepository([List<FoodItem> initial = const []])
    : items = List.of(initial);
  final List<FoodItem> items;
  bool failWrite = false;
  bool failRead = false;
  @override
  Future<List<FoodItem>> load() async {
    if (failRead) throw StateError('read failure');
    return List.of(items);
  }

  @override
  Future<void> save(FoodItem item, {required bool isNew}) async {
    if (failWrite) throw StateError('write failure');
    item.validate();
    if (isNew) {
      items.add(item);
    } else {
      final index = items.indexWhere((i) => i.id == item.id);
      if (index < 0) throw const InventoryConflict();
      items[index] = FoodItem.fromMap(
        item.toMap()..['revision'] = item.revision + 1,
      );
    }
  }

  @override
  Future<void> delete(FoodItem item, DateTime at) async {
    if (failWrite) throw StateError('write failure');
    items.removeWhere((i) => i.id == item.id);
  }

  @override
  Future<void> changeStatus(
    FoodItem item,
    FoodStatus status,
    DateTime at, {
    String? reason,
  }) async {
    if (failWrite) throw StateError('write failure');
    final index = items.indexWhere((i) => i.id == item.id);
    items[index] = FoodItem.fromMap(
      item.toMap()..addAll({
        'status': status.name,
        'status_changed_at': at.toUtc().toIso8601String(),
        'disposal_reason': reason,
        'revision': item.revision + 1,
      }),
    );
  }
}

class TestTodayController extends TodayController {
  @override
  DateTime build() => calendarDate(ref.watch(clockProvider)());
}
