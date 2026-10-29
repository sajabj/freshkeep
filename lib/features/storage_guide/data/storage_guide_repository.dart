import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/storage_food.dart';

class StorageGuideRepository {
  Future<List<StorageFood>> load() async {
    final json = jsonDecode(
      await rootBundle.loadString(
        'assets/storage/storage_guide.json',
        cache: false,
      ),
    ) as Map<String, dynamic>;
    return (json['foods'] as List)
        .map((e) => StorageFood.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
