# FreshKeep image sources and use notes

Reviewed: 2026-10-21

## Phase 5.9 Fitness Meals

All twenty files matching `assets/images/recipes/fitness-*.webp` are original
AI-generated outputs produced specifically for FreshKeep with OpenAI's built-in
image generation tool. They do not contain downloaded stock photography,
brand packaging, logos, visible text or watermarks. No third-party stock-photo
library was used and there is no stock-photo attribution requirement.

The exact mapping from generated source files to recipe IDs is recorded in
`tool/import_fitness_images.py`. The project stores only the optimized WebP
copies needed for offline display.

The twelve earlier recipe images and common-food assets remain documented in
`assets/images/PROVENANCE.md`.
