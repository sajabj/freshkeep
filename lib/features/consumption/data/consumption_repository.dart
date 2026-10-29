import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../inventory/domain/food_item.dart';
import '../domain/consumption.dart';

class ConsumptionRepository {
  ConsumptionRepository(this.db);
  final Database db;

  Future<ConsumptionOperation> apply(ConsumptionRequest request) async {
    if (request.id.trim().isEmpty || request.allocations.isEmpty) {
      throw const ConsumptionConflict('empty');
    }
    final merged = <String, double>{};
    for (final allocation in request.allocations) {
      if (!allocation.amount.isFinite || allocation.amount <= 0) {
        throw const ConsumptionConflict('invalid_amount');
      }
      merged.update(
        allocation.foodId,
        (value) => value + allocation.amount,
        ifAbsent: () => allocation.amount,
      );
    }
    return db.transaction((tx) async {
      try {
        await tx.insert('consumption_operations', {
          'id': request.id,
          'kind': request.kind.name,
          'recipe_id': request.recipeId,
          'occurred_at': request.occurredAt.toUtc().toIso8601String(),
          'state': 'applied',
        });
      } on DatabaseException {
        throw const ConsumptionConflict('duplicate_operation');
      }
      final entries = <ConsumptionEntry>[];
      for (final allocation in merged.entries) {
        final rows = await tx.query(
          'food_items',
          where: 'id=?',
          whereArgs: [allocation.key],
        );
        if (rows.length != 1) throw const ConsumptionConflict('missing_batch');
        final row = rows.single;
        final before = (row['quantity'] as num).toDouble();
        final revision = row['revision'] as int;
        if (row['status'] != FoodStatus.available.name ||
            before <= 0 ||
            allocation.value > before + 0.0000001) {
          throw const ConsumptionConflict('insufficient_or_changed');
        }
        final after = (before - allocation.value).abs() < 0.0000001
            ? 0.0
            : before - allocation.value;
        final status = after == 0 ? FoodStatus.used : FoodStatus.available;
        final changed = await tx.update(
          'food_items',
          {
            'quantity': after,
            'status': status.name,
            'status_changed_at': status == FoodStatus.used
                ? request.occurredAt.toUtc().toIso8601String()
                : null,
            'updated_at': request.occurredAt.toUtc().toIso8601String(),
            'revision': revision + 1,
          },
          where: "id=? AND revision=? AND status='available' AND quantity>=?",
          whereArgs: [allocation.key, revision, allocation.value],
        );
        if (changed != 1) throw const ConsumptionConflict('concurrent_change');
        final snapshot = {
          ...row,
          'quantity': after,
          'status': status.name,
          'revision': revision + 1,
        };
        await tx.insert('inventory_events', {
          'id': const Uuid().v4(),
          'food_id': allocation.key,
          'kind': 'consumed',
          'occurred_at': request.occurredAt.toUtc().toIso8601String(),
          'snapshot': jsonEncode(snapshot),
        });
        await tx.insert('consumption_entries', {
          'operation_id': request.id,
          'food_id': allocation.key,
          'food_name': row['name'],
          'amount': allocation.value,
          'unit': row['unit'],
          'quantity_before': before,
          'quantity_after': after,
          'revision_before': revision,
          'revision_after': revision + 1,
          'status_before': row['status'],
          'status_after': status.name,
        });
        entries.add(
          ConsumptionEntry(
            foodId: allocation.key,
            foodName: row['name'] as String,
            amount: allocation.value,
            unit: row['unit'] as String,
            quantityBefore: before,
            quantityAfter: after,
          ),
        );
      }
      return ConsumptionOperation(
        id: request.id,
        kind: request.kind,
        occurredAt: request.occurredAt,
        recipeId: request.recipeId,
        undone: false,
        entries: entries,
      );
    });
  }

  Future<void> undo(String operationId, DateTime at) => db.transaction((
    tx,
  ) async {
    final operations = await tx.query(
      'consumption_operations',
      where: 'id=?',
      whereArgs: [operationId],
    );
    if (operations.length != 1 || operations.single['state'] != 'applied') {
      throw const ConsumptionConflict('already_undone_or_missing');
    }
    final entries = await tx.query(
      'consumption_entries',
      where: 'operation_id=?',
      whereArgs: [operationId],
      orderBy: 'id',
    );
    for (final entry in entries) {
      final rows = await tx.query(
        'food_items',
        where: 'id=?',
        whereArgs: [entry['food_id']],
      );
      if (rows.length != 1) throw const ConsumptionConflict('batch_deleted');
      final current = rows.single;
      if (current['revision'] != entry['revision_after'] ||
          (current['quantity'] as num).toDouble() != entry['quantity_after'] ||
          current['status'] != entry['status_after']) {
        throw const ConsumptionConflict('batch_changed');
      }
    }
    for (final entry in entries) {
      final revisionAfter = entry['revision_after'] as int;
      final changed = await tx.update(
        'food_items',
        {
          'quantity': entry['quantity_before'],
          'status': entry['status_before'],
          'status_changed_at': null,
          'updated_at': at.toUtc().toIso8601String(),
          'revision': revisionAfter + 1,
        },
        where: 'id=? AND revision=?',
        whereArgs: [entry['food_id'], revisionAfter],
      );
      if (changed != 1) throw const ConsumptionConflict('concurrent_change');
      final current = (await tx.query(
        'food_items',
        where: 'id=?',
        whereArgs: [entry['food_id']],
      )).single;
      await tx.insert('inventory_events', {
        'id': const Uuid().v4(),
        'food_id': entry['food_id'],
        'kind': 'consumption_undone',
        'occurred_at': at.toUtc().toIso8601String(),
        'snapshot': jsonEncode(current),
      });
    }
    if (await tx.update(
          'consumption_operations',
          {'state': 'undone', 'undone_at': at.toUtc().toIso8601String()},
          where: "id=? AND state='applied'",
          whereArgs: [operationId],
        ) !=
        1) {
      throw const ConsumptionConflict('already_undone');
    }
  });
}
