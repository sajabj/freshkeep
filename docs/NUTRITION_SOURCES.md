# Phase 5.9 nutrition methodology

Reviewed: 2026-10-21

FreshKeep displays calories, protein, carbohydrate and fat **per serving** as
estimates. The values are calculated from each recipe's declared ingredient
weights and serving count; they are not laboratory measurements or personal
dietary targets.

## Data source

- USDA FoodData Central Foundation Foods, April 2026 JSON release.
- USDA FoodData Central SR Legacy, April 2018 final release.
- Official source and downloads: https://fdc.nal.usda.gov/download-datasets/

`tool/fdc_macros.json` freezes the exact FoodData Central IDs, descriptions and
per-100 g macronutrient rows used by Phase 5.9. `tool/extract_fdc_reference.py`
recreates that audited subset from the two official JSON exports.
`tool/build_fitness_recipes.py` multiplies each per-100 g value by the declared
ingredient weight, sums the recipe, divides by the number of servings, and
rounds each displayed result to one decimal place.

Weights are raw/pre-cooking unless the ingredient explicitly says cooked,
drained or rinsed. Milk is treated as 1 g per ml for this estimate. One shell
egg is represented as 50 g edible portion. Water, salt, pepper, dried herbs and
spices are excluded from the macro totals. Every nutrition card states these
limits and explains that brands, ingredients and preparation can change the
result.
