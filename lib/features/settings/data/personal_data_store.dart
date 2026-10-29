import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class PersonalDataStore {
  PersonalDataStore(this.db);
  final Database db;
  Future<String> export(DateTime now) => db.transaction((tx) async {
    Map<String, Object?> clean(Map<String, Object?> row) =>
        Map.of(row)..remove('image_path');
    final events = <Map<String, Object?>>[];
    for (final row in await tx.query('inventory_events')) {
      // A malformed historical snapshot must never leak a private path.
      final snapshot = clean(
        Map<String, Object?>.from(jsonDecode(row['snapshot'] as String) as Map),
      );
      events.add({...row, 'snapshot': snapshot});
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'freshkeep-export',
      'format_version': 1,
      'database_version': await tx.getVersion(),
      'exported_at': now.toUtc().toIso8601String(),
      'notes': 'Total batch prices are user estimates, without currency conversion. Photos and private file paths are excluded. This file is not an import format.',
      'product_attribution': 'Open Food Facts data: Open Database License (ODbL). Source URLs are retained. https://world.openfoodfacts.org/terms-of-use',
      'inventory': [for (final row in await tx.query('food_items')) clean(row)],
      'events': events,
      'shopping': await tx.query('shopping_items'),
      'favorite_recipes': [
        for (final row in await tx.query(
          'recipes',
          columns: ['id'],
          where: 'favorite=1',
        ))
          row['id'],
      ],
      'custom_recipes': [
        for (final row in await tx.query('custom_recipes'))
          {
            ...clean(row),
            'content': jsonEncode(
              Map<String, dynamic>.from(
                jsonDecode(row['content'] as String) as Map,
              )..remove('imagePath'),
            ),
          },
      ],
      'cooking_timers': await tx.query('cooking_timers'),
      'reminder_settings': await tx.query('reminder_settings'),
      'meal_plans': await tx.query('meal_plans'),
      'consumption_operations': await tx.query('consumption_operations'),
      'consumption_entries': await tx.query('consumption_entries'),
    });
  });

  /// Child rows go first. No synthetic deletion events or schema recreation.
  /// Notification cancellation must succeed before entering this transaction.
  Future<void> deleteRecords() => db.transaction((tx) async {
    for (final table in [
      'consumption_entries',
      'consumption_operations',
      'cooking_timers',
      'meal_plans',
      'inventory_events',
      'shopping_items',
      'product_cache',
      'reminder_ids',
      'reminder_settings',
      'food_items',
      'custom_recipes',
    ]) {
      await tx.delete(table);
    }
    await tx.update('recipes', {'favorite': 0});
  });

  /// Never follow arbitrary paths from item snapshots (including exports).
  /// Only regular, immediate files inside the app-owned photo folder are erased.
  static Future<void> deletePhotos(Directory documents) async {
    for (final name in ['food_photos', 'recipe_photos']) {
      final folder = Directory(p.join(documents.absolute.path, name));
      if (!await folder.exists()) continue;
      if (await FileSystemEntity.type(folder.path, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw const FileSystemException('Photo folder is not a directory');
      }
      await for (final entity in folder.list(followLinks: false)) {
        if (entity is File &&
            p.isWithin(folder.absolute.path, entity.absolute.path)) {
          await entity.delete();
        }
      }
    }
  }
}
