import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/food_item.dart';
import '../domain/inventory_repository.dart';

class SqliteInventoryRepository implements InventoryRepository {
  SqliteInventoryRepository(this.db);
  final Database db;
  @override
  Future<List<FoodItem>> load() async => (await db.query(
    'food_items',
    orderBy: 'expiry_date, created_at, id',
  )).map(FoodItem.fromMap).toList();

  Future<void> _event(
    Transaction tx,
    String kind,
    Map<String, Object?> item,
    DateTime at,
  ) => tx
      .insert('inventory_events', {
        'id': const Uuid().v4(),
        'food_id': item['id'],
        'kind': kind,
        'occurred_at': at.toUtc().toIso8601String(),
        'snapshot': jsonEncode(item),
      })
      .then((_) {});

  @override
  Future<void> save(FoodItem item, {required bool isNew}) async {
    item.validate();
    await db.transaction((tx) => saveWithin(tx, item, isNew: isNew));
  }

  /// Used by shopping conversion to commit both records and the audit event
  /// together. No nested transaction or second inventory implementation.
  Future<void> saveWithin(
    Transaction tx,
    FoodItem item, {
    required bool isNew,
  }) async {
    item.validate();
    final data = item.toMap();
    if (isNew) {
      if (item.status != FoodStatus.available || item.revision != 0) {
        throw const InventoryConflict();
      }
      await tx.insert('food_items', data);
    } else {
      final original = await tx.query(
        'food_items',
        where: 'id = ? AND revision = ?',
        whereArgs: [item.id, item.revision],
      );
      if (original.isEmpty || original.single['status'] != 'available') {
        throw const InventoryConflict();
      }
      // Editing cannot change identity, creation date or lifecycle state.
      data['created_at'] = original.single['created_at'];
      data['status'] = original.single['status'];
      data['status_changed_at'] = original.single['status_changed_at'];
      data['disposal_reason'] = original.single['disposal_reason'];
      data['revision'] = item.revision + 1;
      if (await tx.update(
            'food_items',
            data,
            where: 'id = ? AND revision = ?',
            whereArgs: [item.id, item.revision],
          ) !=
          1) {
        throw const InventoryConflict();
      }
    }
    await _event(tx, isNew ? 'created' : 'updated', data, item.updatedAt);
  }

  @override
  Future<void> changeStatus(
    FoodItem item,
    FoodStatus status,
    DateTime at, {
    String? reason,
  }) async {
    await db.transaction((tx) async {
      if (item.status == status) return;
      final data = item.toMap()
        ..addAll({
          'status': status.name,
          'status_changed_at': at.toUtc().toIso8601String(),
          'updated_at': at.toUtc().toIso8601String(),
          'disposal_reason': status == FoodStatus.discarded ? reason : null,
          'revision': item.revision + 1,
        });
      if (await tx.update(
            'food_items',
            data,
            where: 'id = ? AND revision = ?',
            whereArgs: [item.id, item.revision],
          ) !=
          1) {
        throw const InventoryConflict();
      }
      await _event(tx, status.name, data, at);
    });
  }

  @override
  Future<void> delete(FoodItem item, DateTime at) async {
    await db.transaction((tx) async {
      final current = await tx.query(
        'food_items',
        where: 'id = ? AND revision = ?',
        whereArgs: [item.id, item.revision],
      );
      if (current.isEmpty) throw const InventoryConflict();
      await _event(tx, 'deleted', current.single, at);
      await tx.delete('food_items', where: 'id = ?', whereArgs: [item.id]);
    });
  }
}
