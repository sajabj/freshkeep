"""One-off audit helper for Phase 5.9 nutrition references.

Reads the official USDA FoodData Central Foundation 04/2026 and SR Legacy
04/2018 JSON exports and prints matching energy/macronutrient rows.
"""

import json
import sys


QUERIES = {
    "chicken_breast_raw": "Chicken, breast, boneless, skinless, raw",
    "salmon_raw": "Fish, salmon, Atlantic, farm raised, raw",
    "tuna_canned": "Fish, tuna, light, canned in water, drained solids",
    "egg_whole": "Egg, whole, raw, fresh",
    "milk_1pct": "Milk, lowfat, fluid, 1% milkfat",
    "greek_yogurt": "Yogurt, Greek, plain, nonfat",
    "oats_rolled": "Oats, whole grain, rolled, old fashioned",
    "banana": "Bananas, ripe and slightly ripe, raw",
    "potato": "Potatoes, gold, without skin, raw",
    "sweet_potato": "Sweet potatoes, orange flesh, without skin, raw",
    "chickpeas_canned": "Chickpeas (garbanzo beans, bengal gram), canned",
    "spinach": "Spinach, baby",
    "cheddar": "Cheese, cheddar",
    "peanut_butter": "Peanut butter, creamy",
    "avocado": "Avocado, Hass, peeled, raw",
    "rice_cooked": "Rice, white, long-grain, regular, cooked, unenriched",
    "bread_whole_wheat": "Bread, whole-wheat, commercially prepared",
    "dates": "Dates, medjool",
    "strawberries": "Strawberries, raw",
    "pasta_cooked": "Pasta, cooked, unenriched, without added salt",
    "bulgur_cooked": "Bulgur, cooked",
    "peas_cooked": "Peas, green, cooked, boiled, drained, without salt",
    "lentils_cooked": "Lentils, mature seeds, cooked, boiled, without salt",
    "beef_90_cooked": "Beef, ground, 90% lean meat / 10% fat, crumbles, cooked",
    "olive_oil": "Oil, olive, salad or cooking",
    "walnuts": "Nuts, walnuts, english",
    "blueberries": "Blueberries, raw",
    "tomato_sauce": "Tomato sauce, canned, no salt added",
    "carrot": "Carrots, raw",
}


def nutrients(food):
    values = {}
    for row in food.get("foodNutrients", []):
        nutrient = row.get("nutrient", {})
        name = nutrient.get("name", "")
        unit = nutrient.get("unitName", "")
        amount = row.get("amount")
        if amount is None:
            continue
        if name.startswith("Energy") and unit.lower() == "kcal":
            values.setdefault("calories", float(amount))
        elif name == "Protein":
            values["protein"] = float(amount)
        elif name == "Carbohydrate, by difference":
            values["carbohydrates"] = float(amount)
        elif name == "Total lipid (fat)":
            values["fat"] = float(amount)
    return values


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: extract_fdc_reference.py FOUNDATION.json SR_LEGACY.json")
    pools = []
    for path, root in zip(sys.argv[1:], ("FoundationFoods", "SRLegacyFoods")):
        with open(path, encoding="utf-8") as handle:
            pools.extend(json.load(handle)[root])
    result = {}
    for key, query in QUERIES.items():
        candidates = [
            f
            for f in pools
            if isinstance(f, dict)
            and isinstance(f.get("description"), str)
            and query.lower() in f["description"].lower()
        ]
        if not candidates:
            print(f"missing: {key} -> {query}", file=sys.stderr)
            continue
        food = candidates[0]
        result[key] = {
            "fdcId": food["fdcId"],
            "description": food["description"],
            **nutrients(food),
        }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
