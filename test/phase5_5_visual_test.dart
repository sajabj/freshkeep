import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/core/theme/app_theme.dart';
import 'package:freshkeep/features/inventory/presentation/food_photo.dart';
import 'package:freshkeep/features/recipes/presentation/recipe_art.dart';

void main() {
  testWidgets('food fallbacks match exact Arabic and English names', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.light),
        home: const Row(
          children: [
            FoodPhoto(name: 'Apple'),
            FoodPhoto(name: 'موز'),
            FoodPhoto(name: 'Apple juice'),
            FoodPhoto(name: 'Unknown packaged item'),
          ],
        ),
      ),
    );
    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map(
          (image) => ((image.image as ResizeImage).imageProvider as AssetImage)
              .assetName,
        )
        .toList();
    expect(assets, [
      'assets/images/foods/apple.jpg',
      'assets/images/foods/banana.jpg',
      'assets/images/foods/generic.jpg',
      'assets/images/foods/generic.jpg',
    ]);
  });

  testWidgets('recipe photography is keyed to the recipe id', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.dark),
        home: const RecipeArt(recipeId: 'tomato-pasta', label: 'Tomato pasta'),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
      'assets/images/recipes/tomato-pasta.jpg',
    );
    expect(find.bySemanticsLabel('Tomato pasta'), findsOneWidget);
  });
}
