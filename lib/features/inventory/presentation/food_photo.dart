import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FoodPhoto extends StatelessWidget {
  const FoodPhoto({
    super.key,
    this.path,
    this.name,
    this.categoryId,
    this.size = 64,
    this.borderRadius = 16,
  });
  final String? path;
  final String? name, categoryId;
  final double size;
  final double borderRadius;
  String get _fallbackAsset {
    final value = (name ?? '').toLowerCase().trim();
    const matches = <String, List<String>>{
      'apple': ['apple', 'apples', 'تفاح', 'تفاحة'],
      'banana': ['banana', 'bananas', 'موز', 'موزة'],
      'tomato': ['tomato', 'tomatoes', 'طماطم', 'بندورة'],
      'milk': ['milk', 'fresh milk', 'حليب', 'حليب طازج'],
      'bread': ['bread', 'toast', 'خبز', 'توست'],
      'eggs': ['egg', 'eggs', 'بيض'],
      'potato': ['potato', 'potatoes', 'بطاطا', 'بطاطس'],
      'carrot': ['carrot', 'carrots', 'جزر'],
    };
    for (final entry in matches.entries) {
      if (value.isNotEmpty && entry.value.contains(value)) {
        return 'assets/images/foods/${entry.key}.jpg';
      }
    }
    return 'assets/images/foods/generic.jpg';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: name,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.square(
        dimension: size,
        child: path == null
            ? Image.asset(
                _fallbackAsset,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
              )
            : path!.startsWith('https://images.openfoodfacts.org/')
            ? CachedNetworkImage(
                imageUrl: path!,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                placeholder: (_, _) =>
                    Image.asset(_fallbackAsset, fit: BoxFit.cover),
                errorWidget: (_, _, _) =>
                    Image.asset(_fallbackAsset, fit: BoxFit.cover),
              )
            : Image.file(
                File(path!),
                fit: BoxFit.cover,
                cacheWidth: 300,
                errorBuilder: (_, _, _) =>
                    Image.asset(_fallbackAsset, fit: BoxFit.cover),
              ),
      ),
    ),
  );
}
