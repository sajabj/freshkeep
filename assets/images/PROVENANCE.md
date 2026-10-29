# FreshKeep image provenance

All 21 photographs in this folder were generated specifically for FreshKeep with OpenAI's image generation tool on 2026-10-20. They do not use downloaded stock photography, third-party logos, product packaging, or brand marks.

## Recipe photographs

The twelve files in `recipes/` correspond one-to-one with the recipe ids in `assets/recipes/recipes.json`. Each prompt required only the listed recipe ingredients, warm natural light, a cream surface, a centered 3:2 crop, and no text, logos, packaging, or unrelated garnish.

## Phase 5.9 fitness recipe photography

The twenty `fitness-*.webp` files were generated specifically for FreshKeep on
2026-10-21 with OpenAI's built-in image generation tool. Each image has its own
dish prompt matching the ingredients in `fitness_recipes.json`; all share a
warm daylight, cream-surface, horizontal food-photography direction and forbid
text, logos, packaging, people, watermarks and unrelated garnish. No external
stock photograph or third-party web image is included. The generated PNGs were
resized to 1200 px width and encoded locally as WebP quality 80.

## Food fallback photographs

The files in `foods/` depict apple, banana, tomato, milk, bread, eggs, potato, and carrot. FreshKeep selects these only for a complete Arabic or English name match. `generic.jpg` is an intentionally neutral closed food container and is used when the app cannot identify the food type. A user's local photo remains first priority, followed by a matching Open Food Facts image, then these bundled fallbacks.

## Processing

Generated masters remain outside the application workspace. App copies were resized with high-quality bicubic sampling: recipes to 960×640 and food fallbacks to 512×512, then encoded as JPEG at quality 84. The combined app image library is approximately 1.7 MB.
