import 'package:flutter/material.dart';

import 'dart:io';

/// Original bundled photography keyed by recipe id, available offline.
class RecipeArt extends StatelessWidget {
  const RecipeArt({
    super.key,
    required this.recipeId,
    required this.label,
    this.height = 160,
    this.imagePath,
  });
  final String recipeId, label;
  final String? imagePath;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: imagePath != null
            ? Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                cacheWidth: 960,
                errorBuilder: (_, _, _) => _fallback(context),
              )
            : Image.asset(
                'assets/images/recipes/$recipeId.${recipeId.startsWith('fitness-') ? 'webp' : 'jpg'}',
                fit: BoxFit.cover,
                cacheWidth: 960,
                errorBuilder: (_, _, _) => _fallback(context),
              ),
      ),
    ),
  );

  Widget _fallback(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(child: Icon(Icons.restaurant_outlined, size: 40)),
  );
}
