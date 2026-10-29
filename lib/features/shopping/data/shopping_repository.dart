import 'package:sqflite/sqflite.dart';

import '../../inventory/data/sqlite_inventory_repository.dart';
import '../../inventory/domain/food_item.dart';
import '../../inventory/domain/inventory_repository.dart';
import '../domain/shopping_item.dart';

class ShoppingRepository {
  ShoppingRepository(this.db);
  final Database db;
  Future<List<ShoppingItem>> load() async => (await db.query(
    'shopping_items',
    orderBy: 'purchased, created_at DESC, id',
  )).map(ShoppingItem.fromMap).toList();
  Future<void> save(ShoppingItem item, {required bool isNew}) async {
    item.validate();
    if (isNew) {
      await db.insert('shopping_items', item.toMap());
      return;
    }
    final data = item.toMap()
      ..remove('id')
      ..remove('created_at')
      ..remove('converted')
      ..remove('inventory_id');
    data['revision'] = item.revision + 1;
    if (await db.update(
          'shopping_items',
          data,
          where: 'id=? AND revision=? AND converted=0',
          whereArgs: [item.id, item.revision],
        ) !=
        1) {
      throw const InventoryConflict();
    }
  }

  Future<void> setPurchased(ShoppingItem item, bool value) async {
    if (await db.update(
          'shopping_items',
          {'purchased': value ? 1 : 0, 'revision': item.revision + 1},
          where: 'id=? AND revision=? AND converted=0',
          whereArgs: [item.id, item.revision],
        ) !=
        1) {
      throw const InventoryConflict();
    }
  }

  Future<void> delete(ShoppingItem item) async {
    if (await db.delete(
          'shopping_items',
          where: 'id=? AND revision=?',
          whereArgs: [item.id, item.revision],
        ) !=
        1) {
      throw const InventoryConflict();
    }
  }

  Future<void> convert(ShoppingItem item, FoodItem food) async {
    await db.transaction((tx) async {
      if (await tx.update(
            'shopping_items',
            {
              'purchased': 1,
              'converted': 1,
              'inventory_id': null,
              'revision': item.revision + 1,
            },
            where: 'id=? AND revision=? AND converted=0',
            whereArgs: [item.id, item.revision],
          ) !=
          1) {
        throw const InventoryConflict();
      }
      await SqliteInventoryRepository(db).saveWithin(tx, food, isNew: true);
      await tx.update(
        'shopping_items',
        {'inventory_id': food.id},
        where: 'id=?',
        whereArgs: [item.id],
      );
    });
  }
}
