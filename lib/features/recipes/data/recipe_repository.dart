import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/recipe.dart';

class RecipeRepository {
  RecipeRepository(this.db);
  final Database db;
  bool _seeded = false;
  Future<List<Recipe>> load() async {
    if (!_seeded) {
      final bundled = <dynamic>[
        ...jsonDecode(
          await rootBundle.loadString(
            'assets/recipes/recipes.json',
            cache: false,
          ),
        ) as List,
        ...jsonDecode(
          await rootBundle.loadString(
            'assets/recipes/fitness_recipes.json',
            cache: false,
          ),
        ) as List,
      ];
      await db.transaction((tx) async {
        for (final data in bundled) {
          await tx.insert('recipes', {
            'id': data['id'],
            'content': jsonEncode(data),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });
      _seeded = true;
    }
    final bundled = (await db.query('recipes'))
        .map(
          (m) => Recipe(
            jsonDecode(m['content'] as String) as Map<String, dynamic>,
            favorite: m['favorite'] == 1,
          ),
        )
        .toList();
    final custom =
        (await db.query('custom_recipes', orderBy: 'updated_at DESC'))
            .map(
              (m) => Recipe(
                jsonDecode(m['content'] as String) as Map<String, dynamic>,
                favorite: m['favorite'] == 1,
              ),
            )
            .toList();
    return [...bundled, ...custom];
  }

  Future<void> favorite(String id, bool value) async {
    final table = id.startsWith('user:') ? 'custom_recipes' : 'recipes';
    if (await db.update(
          table,
          {'favorite': value ? 1 : 0},
          where: 'id=?',
          whereArgs: [id],
        ) !=
        1) {
      throw StateError('Recipe missing');
    }
  }

  Future<void> saveCustom(
    Map<String, dynamic> content, {
    required bool isNew,
  }) async {
    final recipe = Recipe(content);
    if (!recipe.personal || !recipe.id.startsWith('user:')) {
      throw ArgumentError('Invalid custom recipe');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'id': recipe.id,
      'content': jsonEncode(content),
      'image_path': recipe.imagePath,
      'updated_at': now,
    };
    if (isNew) {
      await db.insert('custom_recipes', {...row, 'created_at': now});
    } else if (await db.update(
          'custom_recipes',
          row..remove('id'),
          where: 'id=?',
          whereArgs: [recipe.id],
        ) !=
        1) {
      throw StateError('Custom recipe missing');
    }
  }

  Future<String?> deleteCustom(String id) async {
    final rows = await db.query(
      'custom_recipes',
      columns: ['image_path'],
      where: 'id=?',
      whereArgs: [id],
    );
    if (rows.isEmpty) throw StateError('Custom recipe missing');
    await db.delete('custom_recipes', where: 'id=?', whereArgs: [id]);
    return rows.single['image_path'] as String?;
  }
}
