"""Generate the audited Phase 5.9 bundled fitness recipe library.

Nutrition is calculated from the frozen USDA FoodData Central per-100 g
reference rows in tool/fdc_macros.json. Water, salt, pepper, dried herbs and
spices are intentionally excluded from the totals and disclosed in the app.
"""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = json.loads((ROOT / "tool/fdc_macros.json").read_text(encoding="utf-8-sig"))
SOURCE_URL = "https://fdc.nal.usda.gov/"
REVIEWED_ON = "2026-10-21"


def ingredient(key, ar, en, amount, unit, nutrition_key=None, grams=None, aliases=()):
    return {
        "key": key,
        "ar": ar,
        "en": en,
        "amount": amount,
        "unit": unit,
        "aliases": list(aliases),
        "_nutritionKey": nutrition_key,
        "_grams": grams,
    }


def nutrition(ingredients, servings, raw=True):
    totals = {"calories": 0.0, "protein": 0.0, "carbohydrates": 0.0, "fat": 0.0}
    used = []
    for item in ingredients:
        key, grams = item.get("_nutritionKey"), item.get("_grams")
        if not key or grams is None:
            continue
        row = REFERENCE[key]
        used.append(row["fdcId"])
        for nutrient in totals:
            totals[nutrient] += row[nutrient] * grams / 100 / servings
    return {
        **{key: round(value, 1) for key, value in totals.items()},
        "source": "USDA FoodData Central · Foundation Foods 04/2026 and SR Legacy 04/2018",
        "sourceUrl": SOURCE_URL,
        "reviewedOn": REVIEWED_ON,
        "fdcIds": sorted(set(used)),
        "basisAr": "للحصة الواحدة؛ الأوزان قبل الطبخ ما لم يُذكر أنها مطبوخة أو مصفّاة. الماء والملح والفلفل والأعشاب والتوابل غير محسوبة.",
        "basisEn": "Per serving; weights are before cooking unless marked cooked or drained. Water, salt, pepper, herbs and spices are excluded.",
    }


def recipe(id, ar, en, description_ar, description_en, group, category, prep, cook, servings,
           ingredients, steps_ar, steps_en, allergens_ar=(), allergens_en=()):
    result = {
        "id": id,
        "ar": ar,
        "en": en,
        "descriptionAr": description_ar,
        "descriptionEn": description_en,
        "fitnessGroup": group,
        "category": category,
        "art": "fitness",
        "minutes": prep + cook,
        "prepMinutes": prep,
        "cookMinutes": cook,
        "servings": servings,
        "ingredients": ingredients,
        "stepsAr": steps_ar,
        "stepsEn": steps_en,
        "allergensAr": list(allergens_ar),
        "allergensEn": list(allergens_en),
    }
    result["nutrition"] = nutrition(ingredients, servings)
    for item in ingredients:
        item.pop("_nutritionKey", None)
        item.pop("_grams", None)
    return result


R = []

# Protein-rich meals
R.append(recipe("fitness-chicken-rice-veg", "دجاج مشوي مع الأرز والخضار", "Grilled Chicken with Rice & Vegetables",
    "طبق متوازن بدجاج متبّل وأرز وخضار مشوية.", "A balanced plate of seasoned chicken, rice and roasted vegetables.",
    "protein", "main", 15, 25, 2,
    [ingredient("chicken", "صدر دجاج نيئ", "Raw chicken breast", 360, "g", "chicken_breast_raw", 360, ["دجاج", "chicken"]),
     ingredient("rice", "أرز أبيض مطبوخ", "Cooked white rice", 360, "g", "rice_cooked", 360, ["أرز", "rice"]),
     ingredient("carrot", "جزر", "Carrot", 160, "g", "carrot", 160, ["جزر", "carrots"]),
     ingredient("spinach", "سبانخ", "Spinach", 120, "g", "spinach", 120, ["سبانخ"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 15, "g", "olive_oil", 15, ["زيت"]),
     ingredient("salt", "ملح وفلفل", "Salt and pepper", 1, "tsp")],
    ["تبّل الدجاج بالملح والفلفل ونصف الزيت.", "اشوِ الدجاج حتى ينضج تمامًا ثم اتركه يرتاح.", "شوّح الجزر والسبانخ ببقية الزيت وقدّمها مع الأرز والدجاج."],
    ["Season the chicken with salt, pepper and half the oil.", "Grill until fully cooked, then let it rest.", "Sauté the carrot and spinach in the remaining oil; serve with rice and chicken."]))

R.append(recipe("fitness-baked-salmon-potatoes", "سلمون مشوي مع البطاطا", "Baked Salmon with Potatoes",
    "سلمون بالفرن مع بطاطا ذهبية وتتبيلة بسيطة.", "Oven-baked salmon with golden potatoes and simple seasoning.",
    "protein", "main", 15, 30, 2,
    [ingredient("salmon", "فيليه سلمون نيئ", "Raw salmon fillet", 320, "g", "salmon_raw", 320, ["سلمون", "salmon"]),
     ingredient("potato", "بطاطا نيئة", "Raw potatoes", 500, "g", "potato", 500, ["بطاطا", "potatoes"]),
     ingredient("spinach", "سبانخ", "Spinach", 100, "g", "spinach", 100, ["سبانخ"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 15, "g", "olive_oil", 15, ["زيت"]),
     ingredient("lemon", "ليمون", "Lemon", 1, "pcs", aliases=["ليمون"]),
     ingredient("salt", "ملح وفلفل", "Salt and pepper", 1, "tsp")],
    ["سخّن الفرن إلى 200°م وقطّع البطاطا.", "قلّب البطاطا بالزيت واشوها 15 دقيقة.", "أضف السلمون المتبّل واشوِ 12–15 دقيقة حتى ينضج، ثم قدّم مع السبانخ والليمون."],
    ["Heat the oven to 200°C and cut the potatoes.", "Toss potatoes with oil and roast for 15 minutes.", "Add seasoned salmon and bake 12–15 minutes until done; serve with spinach and lemon."],
    ["السمك"], ["Fish"]))

R.append(recipe("fitness-tuna-chickpea-salad", "سلطة تونة بالحمص", "Tuna & Chickpea Salad",
    "سلطة مشبعة سريعة بالتونة والحمص والخضار.", "A quick, satisfying tuna, chickpea and vegetable salad.",
    "protein", "salad", 15, 0, 2,
    [ingredient("tuna", "تونة بالماء مصفّاة", "Tuna in water, drained", 240, "g", "tuna_canned", 240, ["تونة", "tuna"]),
     ingredient("chickpeas", "حمص معلب مصفّى ومغسول", "Canned chickpeas, drained and rinsed", 300, "g", "chickpeas_canned", 300, ["حمص", "chickpeas"]),
     ingredient("carrot", "جزر مبشور", "Grated carrot", 100, "g", "carrot", 100, ["جزر"]),
     ingredient("spinach", "سبانخ صغيرة", "Baby spinach", 100, "g", "spinach", 100, ["سبانخ"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 10, "g", "olive_oil", 10, ["زيت"]),
     ingredient("lemon", "عصير ليمون", "Lemon juice", 2, "tbsp")],
    ["صفِّ التونة والحمص واغسل الحمص.", "اخلطهما مع الجزر والسبانخ.", "أضف الزيت والليمون وتبّل ثم قدّم."],
    ["Drain the tuna and chickpeas; rinse the chickpeas.", "Combine with carrot and spinach.", "Dress with oil and lemon, season and serve."], ["السمك"], ["Fish"]))

R.append(recipe("fitness-meatballs-bulgur", "كرات لحم منزلية مع البرغل", "Homemade Meatballs with Bulgur",
    "كرات لحم مخبوزة مع برغل مطبوخ وجزر.", "Baked meatballs served with cooked bulgur and carrot.",
    "protein", "main", 20, 25, 3,
    [ingredient("beef", "لحم بقري مفروم مطبوخ 90% قليل الدهن", "Cooked 90% lean ground beef", 360, "g", "beef_90_cooked", 360, ["لحم", "beef"]),
     ingredient("bulgur", "برغل مطبوخ", "Cooked bulgur", 450, "g", "bulgur_cooked", 450, ["برغل", "bulgur"]),
     ingredient("egg", "بيضة", "Egg", 1, "pcs", "egg_whole", 50, ["بيض", "egg"]),
     ingredient("carrot", "جزر", "Carrot", 180, "g", "carrot", 180, ["جزر"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 10, "g", "olive_oil", 10, ["زيت"]),
     ingredient("spices", "بهارات وملح", "Spices and salt", 2, "tsp")],
    ["اخلط اللحم مع البيضة والبهارات وشكّل كرات.", "اخبز الكرات على 200°م حتى تسخن وتنضج جيدًا.", "شوّح الجزر وقدّم الكرات مع البرغل."],
    ["Mix beef with egg and spices; shape into balls.", "Bake at 200°C until heated through and fully cooked.", "Sauté the carrot and serve with bulgur."], ["البيض"], ["Egg"]))

R.append(recipe("fitness-spinach-cheese-omelet", "أومليت البيض والسبانخ والجبنة", "Spinach & Cheese Omelet",
    "أومليت طري بالسبانخ وجبنة الشيدر.", "A tender omelet with spinach and cheddar.",
    "protein", "breakfast", 10, 10, 2,
    [ingredient("egg", "بيض", "Eggs", 4, "pcs", "egg_whole", 200, ["بيض", "eggs"]),
     ingredient("spinach", "سبانخ", "Spinach", 120, "g", "spinach", 120, ["سبانخ"]),
     ingredient("cheese", "جبنة شيدر", "Cheddar cheese", 60, "g", "cheddar", 60, ["جبنة", "cheese"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 5, "g", "olive_oil", 5, ["زيت"]),
     ingredient("salt", "ملح وفلفل", "Salt and pepper", 1, "tsp")],
    ["اخفق البيض وتبّله.", "ذبّل السبانخ في الزيت ثم أضف البيض.", "رش الجبنة واطوِ الأومليت بعد تماسكه."],
    ["Whisk and season the eggs.", "Wilt spinach in oil, then add eggs.", "Scatter cheese and fold when set."], ["البيض", "الحليب"], ["Egg", "Milk"]))

# Pre-workout meals
R.append(recipe("fitness-banana-milk-oatmeal", "شوفان بالموز والحليب", "Banana Milk Oatmeal",
    "شوفان دافئ بالحليب والموز.", "Warm oatmeal with milk and banana.", "preWorkout", "breakfast", 5, 8, 2,
    [ingredient("oats", "شوفان ملفوف جاف", "Dry rolled oats", 100, "g", "oats_rolled", 100, ["شوفان", "oats"]),
     ingredient("milk", "حليب قليل الدسم 1%", "1% low-fat milk", 400, "ml", "milk_1pct", 400, ["حليب", "milk"]),
     ingredient("banana", "موز", "Banana", 240, "g", "banana", 240, ["موز", "banana"]),
     ingredient("cinnamon", "قرفة", "Cinnamon", 0.5, "tsp")],
    ["سخّن الحليب مع الشوفان مع التحريك 6–8 دقائق.", "اهرِس نصف الموز وحرّكه داخل الشوفان.", "قدّم مع بقية الموز والقرفة."],
    ["Heat milk and oats, stirring for 6–8 minutes.", "Mash half the banana into the oats.", "Serve with remaining banana and cinnamon."], ["الحليب", "قد يحتوي الشوفان على الغلوتين"], ["Milk", "Oats may contain gluten"]))

R.append(recipe("fitness-peanut-banana-toast", "توست بزبدة الفول السوداني والموز", "Peanut Butter & Banana Toast",
    "توست حبوب كاملة بطبقة من زبدة الفول السوداني والموز.", "Whole-wheat toast topped with peanut butter and banana.",
    "preWorkout", "breakfast", 8, 2, 2,
    [ingredient("bread", "خبز حبوب كاملة", "Whole-wheat bread", 120, "g", "bread_whole_wheat", 120, ["خبز", "bread"]),
     ingredient("peanutButter", "زبدة فول سوداني", "Peanut butter", 48, "g", "peanut_butter", 48, ["زبدة الفول السوداني", "peanut butter"]),
     ingredient("banana", "موز", "Banana", 200, "g", "banana", 200, ["موز", "banana"]),
     ingredient("cinnamon", "قرفة", "Cinnamon", 0.5, "tsp")],
    ["حمّص الخبز حسب الرغبة.", "وزّع زبدة الفول السوداني بالتساوي.", "أضف شرائح الموز والقرفة وقدّم فورًا."],
    ["Toast the bread if desired.", "Spread peanut butter evenly.", "Top with banana and cinnamon; serve immediately."], ["الفول السوداني", "الغلوتين"], ["Peanuts", "Gluten"]))

R.append(recipe("fitness-yogurt-fruit-oats", "زبادي بالفواكه والشوفان", "Yogurt with Fruit & Oats",
    "كوب زبادي يوناني مع التوت والشوفان.", "Greek yogurt layered with berries and oats.", "preWorkout", "breakfast", 8, 0, 2,
    [ingredient("yogurt", "زبادي يوناني خالي الدسم", "Nonfat Greek yogurt", 400, "g", "greek_yogurt", 400, ["زبادي", "yogurt"]),
     ingredient("oats", "شوفان ملفوف جاف", "Dry rolled oats", 70, "g", "oats_rolled", 70, ["شوفان", "oats"]),
     ingredient("strawberry", "فراولة", "Strawberries", 200, "g", "strawberries", 200, ["فراولة", "strawberries"]),
     ingredient("blueberry", "توت أزرق", "Blueberries", 100, "g", "blueberries", 100, ["توت", "blueberries"])],
    ["اغسل الفاكهة وقطّع الفراولة.", "قسّم الزبادي في وعاءين.", "أضف الشوفان والفواكه قبل التقديم."],
    ["Wash the fruit and slice strawberries.", "Divide yogurt between two bowls.", "Top with oats and fruit just before serving."], ["الحليب", "قد يحتوي الشوفان على الغلوتين"], ["Milk", "Oats may contain gluten"]))

R.append(recipe("fitness-banana-strawberry-smoothie", "سموذي الموز والفراولة والحليب", "Banana Strawberry Milk Smoothie",
    "سموذي كريمي بسيط من الحليب والموز والفراولة.", "A simple creamy smoothie with milk, banana and strawberries.",
    "preWorkout", "drinks", 7, 0, 2,
    [ingredient("milk", "حليب قليل الدسم 1%", "1% low-fat milk", 500, "ml", "milk_1pct", 500, ["حليب", "milk"]),
     ingredient("banana", "موز", "Banana", 240, "g", "banana", 240, ["موز", "banana"]),
     ingredient("strawberry", "فراولة", "Strawberries", 250, "g", "strawberries", 250, ["فراولة", "strawberries"]),
     ingredient("ice", "مكعبات ثلج", "Ice cubes", 6, "pcs")],
    ["اغسل الفراولة وانزع أعناقها.", "ضع كل المكونات في الخلاط.", "اخلط حتى يصبح القوام ناعمًا وقدّم مباشرة."],
    ["Wash and hull the strawberries.", "Place all ingredients in a blender.", "Blend until smooth and serve immediately."], ["الحليب"], ["Milk"]))

R.append(recipe("fitness-cheese-veg-sandwich", "ساندويش جبنة وخضار بخبز الحبوب الكاملة", "Whole-Grain Cheese & Vegetable Sandwich",
    "ساندويش حبوب كاملة بالجبنة والسبانخ والجزر.", "A whole-wheat sandwich with cheese, spinach and carrot.",
    "preWorkout", "snack", 10, 0, 2,
    [ingredient("bread", "خبز حبوب كاملة", "Whole-wheat bread", 160, "g", "bread_whole_wheat", 160, ["خبز", "bread"]),
     ingredient("cheese", "جبنة شيدر", "Cheddar cheese", 70, "g", "cheddar", 70, ["جبنة", "cheese"]),
     ingredient("spinach", "سبانخ", "Spinach", 80, "g", "spinach", 80, ["سبانخ"]),
     ingredient("carrot", "جزر مبشور", "Grated carrot", 100, "g", "carrot", 100, ["جزر"]),
     ingredient("pepper", "فلفل أسود", "Black pepper", 0.25, "tsp")],
    ["ضع الجبنة على شريحتين من الخبز.", "أضف السبانخ والجزر والفلفل.", "أغلق الساندويشين واقطعهما للتقديم."],
    ["Place cheese on two bread slices.", "Add spinach, carrot and pepper.", "Close both sandwiches and cut to serve."], ["الحليب", "الغلوتين"], ["Milk", "Gluten"]))

# Post-workout meals
R.append(recipe("fitness-chicken-sweet-potato", "دجاج مشوي مع البطاطا الحلوة", "Grilled Chicken with Sweet Potatoes",
    "دجاج مشوي مع مكعبات البطاطا الحلوة والسبانخ.", "Grilled chicken with sweet potato cubes and spinach.",
    "postWorkout", "main", 15, 30, 2,
    [ingredient("chicken", "صدر دجاج نيئ", "Raw chicken breast", 380, "g", "chicken_breast_raw", 380, ["دجاج", "chicken"]),
     ingredient("sweetPotato", "بطاطا حلوة نيئة", "Raw sweet potatoes", 500, "g", "sweet_potato", 500, ["بطاطا حلوة", "sweet potato"]),
     ingredient("spinach", "سبانخ", "Spinach", 120, "g", "spinach", 120, ["سبانخ"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 15, "g", "olive_oil", 15, ["زيت"]),
     ingredient("spices", "بابريكا وملح وفلفل", "Paprika, salt and pepper", 2, "tsp")],
    ["سخّن الفرن إلى 200°م وقلّب البطاطا بنصف الزيت والتوابل.", "اشوِ البطاطا 25–30 دقيقة.", "اشوِ الدجاج المتبّل حتى ينضج تمامًا وقدّمه مع البطاطا والسبانخ."],
    ["Heat oven to 200°C; toss sweet potato with half the oil and seasoning.", "Roast for 25–30 minutes.", "Grill seasoned chicken until fully cooked; serve with potato and spinach."]))

R.append(recipe("fitness-chicken-pea-rice", "أرز بالدجاج والبازيلاء", "Chicken & Pea Rice Bowl",
    "وعاء أرز دافئ بالدجاج والبازيلاء.", "A warm rice bowl with chicken and green peas.",
    "postWorkout", "main", 15, 25, 3,
    [ingredient("chicken", "صدر دجاج نيئ", "Raw chicken breast", 420, "g", "chicken_breast_raw", 420, ["دجاج", "chicken"]),
     ingredient("rice", "أرز أبيض مطبوخ", "Cooked white rice", 540, "g", "rice_cooked", 540, ["أرز", "rice"]),
     ingredient("peas", "بازيلاء مطبوخة", "Cooked green peas", 240, "g", "peas_cooked", 240, ["بازيلاء", "peas"]),
     ingredient("carrot", "جزر", "Carrot", 150, "g", "carrot", 150, ["جزر"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 12, "g", "olive_oil", 12, ["زيت"]),
     ingredient("spices", "بهارات وملح", "Spices and salt", 2, "tsp")],
    ["قطّع الدجاج واطهه بالزيت حتى ينضج تمامًا.", "أضف الجزر والبازيلاء وحرّك حتى تسخن.", "قسّم الأرز في أوعية وأضف خليط الدجاج."],
    ["Cut chicken and cook in oil until fully done.", "Add carrot and peas; stir until hot.", "Divide rice into bowls and top with chicken mixture."]))

R.append(recipe("fitness-whole-wheat-tuna-wrap", "راب تونة بالخبز الكامل", "Whole-Wheat Tuna Wrap",
    "لفائف خبز كامل بالتونة والسبانخ والجزر.", "Whole-wheat wraps filled with tuna, spinach and carrot.",
    "postWorkout", "main", 12, 0, 2,
    [ingredient("bread", "خبز تورتيلا كامل", "Whole-wheat wraps", 130, "g", "bread_whole_wheat", 130, ["خبز كامل", "whole wheat wrap"]),
     ingredient("tuna", "تونة بالماء مصفّاة", "Tuna in water, drained", 260, "g", "tuna_canned", 260, ["تونة", "tuna"]),
     ingredient("yogurt", "زبادي يوناني خالي الدسم", "Nonfat Greek yogurt", 80, "g", "greek_yogurt", 80, ["زبادي", "yogurt"]),
     ingredient("spinach", "سبانخ", "Spinach", 80, "g", "spinach", 80, ["سبانخ"]),
     ingredient("carrot", "جزر مبشور", "Grated carrot", 100, "g", "carrot", 100, ["جزر"]),
     ingredient("lemon", "عصير ليمون", "Lemon juice", 1, "tbsp")],
    ["اخلط التونة مع الزبادي والليمون.", "وزّع السبانخ والجزر على الخبز.", "أضف التونة ولف بإحكام ثم اقطع."],
    ["Mix tuna with yogurt and lemon.", "Divide spinach and carrot between wraps.", "Add tuna, roll tightly and cut."], ["السمك", "الحليب", "الغلوتين"], ["Fish", "Milk", "Gluten"]))

R.append(recipe("fitness-lentil-rice-veg-bowl", "عدس مطبوخ مع الأرز والخضار", "Lentil, Rice & Vegetable Bowl",
    "وعاء نباتي من العدس والأرز والخضار.", "A plant-based bowl of lentils, rice and vegetables.",
    "postWorkout", "main", 15, 20, 3,
    [ingredient("lentils", "عدس مطبوخ", "Cooked lentils", 480, "g", "lentils_cooked", 480, ["عدس", "lentils"]),
     ingredient("rice", "أرز أبيض مطبوخ", "Cooked white rice", 420, "g", "rice_cooked", 420, ["أرز", "rice"]),
     ingredient("carrot", "جزر", "Carrot", 180, "g", "carrot", 180, ["جزر"]),
     ingredient("spinach", "سبانخ", "Spinach", 150, "g", "spinach", 150, ["سبانخ"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 15, "g", "olive_oil", 15, ["زيت"]),
     ingredient("spices", "كمون وملح وفلفل", "Cumin, salt and pepper", 2, "tsp")],
    ["شوّح الجزر بالزيت حتى يلين.", "أضف العدس والسبانخ والتوابل وسخّن جيدًا.", "قسّم الأرز في أوعية وأضف خليط العدس."],
    ["Sauté carrot in oil until tender.", "Add lentils, spinach and seasoning; heat through.", "Divide rice into bowls and top with lentils."]))

R.append(recipe("fitness-chicken-tomato-pasta", "معكرونة بالصلصة الحمراء والدجاج", "Chicken Tomato Pasta",
    "معكرونة بصلصة طماطم ودجاج مقطّع.", "Pasta with tomato sauce and sliced chicken.",
    "postWorkout", "main", 15, 25, 3,
    [ingredient("chicken", "صدر دجاج نيئ", "Raw chicken breast", 420, "g", "chicken_breast_raw", 420, ["دجاج", "chicken"]),
     ingredient("pasta", "معكرونة مطبوخة", "Cooked pasta", 600, "g", "pasta_cooked", 600, ["معكرونة", "pasta"]),
     ingredient("tomatoSauce", "صلصة طماطم دون ملح", "No-salt tomato sauce", 360, "g", "tomato_sauce", 360, ["طماطم", "tomato sauce"]),
     ingredient("spinach", "سبانخ", "Spinach", 120, "g", "spinach", 120, ["سبانخ"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 12, "g", "olive_oil", 12, ["زيت"]),
     ingredient("herbs", "أعشاب مجففة وملح وفلفل", "Dried herbs, salt and pepper", 2, "tsp")],
    ["قطّع الدجاج واطهه بالزيت حتى ينضج تمامًا.", "أضف الصلصة والسبانخ والأعشاب واتركها تغلي برفق.", "قلّب المعكرونة المطبوخة مع الصلصة وقدّم."],
    ["Slice chicken and cook in oil until fully done.", "Add sauce, spinach and herbs; simmer gently.", "Toss with cooked pasta and serve."], ["الغلوتين"], ["Gluten"]))

# Fitness snacks
R.append(recipe("fitness-greek-yogurt-berries-nuts", "زبادي يوناني بالتوت والمكسرات", "Greek Yogurt with Berries & Nuts",
    "زبادي يوناني بالتوت والجوز المقرمش.", "Greek yogurt topped with berries and crunchy walnuts.",
    "snacks", "snack", 7, 0, 2,
    [ingredient("yogurt", "زبادي يوناني خالي الدسم", "Nonfat Greek yogurt", 400, "g", "greek_yogurt", 400, ["زبادي", "yogurt"]),
     ingredient("strawberry", "فراولة", "Strawberries", 160, "g", "strawberries", 160, ["فراولة", "strawberries"]),
     ingredient("blueberry", "توت أزرق", "Blueberries", 120, "g", "blueberries", 120, ["توت", "blueberries"]),
     ingredient("walnut", "جوز إنجليزي نيئ", "Raw English walnuts", 40, "g", "walnuts", 40, ["جوز", "walnuts"])],
    ["اغسل الفاكهة وقطّع الفراولة.", "قسّم الزبادي في وعاءين.", "أضف الفاكهة والجوز قبل التقديم."],
    ["Wash fruit and slice strawberries.", "Divide yogurt between two bowls.", "Top with fruit and walnuts just before serving."], ["الحليب", "المكسرات"], ["Milk", "Tree nuts"]))

R.append(recipe("fitness-roasted-chickpeas", "حمص محمص بالفرن", "Oven-Roasted Chickpeas",
    "حمص مقرمش بالفرن مع البابريكا والكمون.", "Crunchy oven-roasted chickpeas with paprika and cumin.",
    "snacks", "snack", 8, 30, 3,
    [ingredient("chickpeas", "حمص معلب مصفّى ومغسول", "Canned chickpeas, drained and rinsed", 480, "g", "chickpeas_canned", 480, ["حمص", "chickpeas"]),
     ingredient("oil", "زيت زيتون", "Olive oil", 15, "g", "olive_oil", 15, ["زيت"]),
     ingredient("spices", "بابريكا وكمون وملح", "Paprika, cumin and salt", 2, "tsp")],
    ["سخّن الفرن إلى 200°م وجفف الحمص جيدًا.", "قلّبه بالزيت والتوابل وافرده على صينية.", "حمّص 25–30 دقيقة مع تحريك الصينية مرة حتى يقرمش."],
    ["Heat oven to 200°C and dry chickpeas thoroughly.", "Toss with oil and spices; spread on a tray.", "Roast 25–30 minutes, shaking once, until crisp."]))

R.append(recipe("fitness-avocado-egg-toast", "توست بالأفوكادو والبيض", "Avocado & Egg Toast",
    "توست حبوب كاملة بالأفوكادو والبيض.", "Whole-wheat toast with avocado and egg.",
    "snacks", "snack", 10, 10, 2,
    [ingredient("bread", "خبز حبوب كاملة", "Whole-wheat bread", 120, "g", "bread_whole_wheat", 120, ["خبز", "bread"]),
     ingredient("avocado", "أفوكادو هاس مقشّر", "Peeled Hass avocado", 160, "g", "avocado", 160, ["أفوكادو", "avocado"]),
     ingredient("egg", "بيض", "Eggs", 2, "pcs", "egg_whole", 100, ["بيض", "eggs"]),
     ingredient("lemon", "عصير ليمون", "Lemon juice", 1, "tbsp"),
     ingredient("salt", "ملح وفلفل", "Salt and pepper", 0.5, "tsp")],
    ["اسلق البيض للدرجة المطلوبة ثم قشّره.", "اهرِس الأفوكادو مع الليمون والملح والفلفل.", "حمّص الخبز ووزّع الأفوكادو ثم أضف شرائح البيض."],
    ["Boil eggs to your preferred doneness and peel.", "Mash avocado with lemon, salt and pepper.", "Toast bread, spread avocado and top with sliced egg."], ["البيض", "الغلوتين"], ["Egg", "Gluten"]))

R.append(recipe("fitness-oat-date-bites", "كرات الشوفان والتمر", "Oat & Date Bites",
    "كرات صغيرة دون خبز من التمر والشوفان وزبدة الفول السوداني.", "No-bake bites made with dates, oats and peanut butter.",
    "snacks", "snack", 20, 0, 8,
    [ingredient("dates", "تمر مجدول منزوع النوى", "Pitted Medjool dates", 240, "g", "dates", 240, ["تمر", "dates"]),
     ingredient("oats", "شوفان ملفوف جاف", "Dry rolled oats", 160, "g", "oats_rolled", 160, ["شوفان", "oats"]),
     ingredient("peanutButter", "زبدة فول سوداني", "Peanut butter", 96, "g", "peanut_butter", 96, ["زبدة الفول السوداني", "peanut butter"]),
     ingredient("water", "ماء عند الحاجة", "Water as needed", 2, "tbsp"),
     ingredient("cinnamon", "قرفة", "Cinnamon", 1, "tsp")],
    ["اخلط التمر والشوفان وزبدة الفول السوداني والقرفة في محضرة الطعام.", "أضف الماء تدريجيًا فقط إذا احتاج الخليط.", "شكّل 16 كرة وبرّدها؛ الحصة كرتان."],
    ["Process dates, oats, peanut butter and cinnamon.", "Add water gradually only if needed.", "Shape 16 bites and chill; one serving is two bites."], ["الفول السوداني", "قد يحتوي الشوفان على الغلوتين"], ["Peanuts", "Oats may contain gluten"]))

R.append(recipe("fitness-fruit-yogurt-salad", "سلطة فواكه بالزبادي", "Fruit & Yogurt Salad",
    "سلطة فاكهة طازجة بصلصة زبادي خفيفة.", "Fresh fruit salad with a light yogurt dressing.",
    "snacks", "snack", 12, 0, 3,
    [ingredient("yogurt", "زبادي يوناني خالي الدسم", "Nonfat Greek yogurt", 360, "g", "greek_yogurt", 360, ["زبادي", "yogurt"]),
     ingredient("banana", "موز", "Banana", 240, "g", "banana", 240, ["موز", "banana"]),
     ingredient("strawberry", "فراولة", "Strawberries", 240, "g", "strawberries", 240, ["فراولة", "strawberries"]),
     ingredient("blueberry", "توت أزرق", "Blueberries", 150, "g", "blueberries", 150, ["توت", "blueberries"]),
     ingredient("cinnamon", "قرفة", "Cinnamon", 0.5, "tsp")],
    ["اغسل الفاكهة وقطّع الفراولة والموز.", "اخلط الفواكه برفق.", "قسّمها في أوعية وأضف الزبادي والقرفة قبل التقديم."],
    ["Wash fruit; slice strawberries and banana.", "Gently combine the fruit.", "Divide into bowls and add yogurt and cinnamon just before serving."], ["الحليب"], ["Milk"]))


if __name__ == "__main__":
    destination = ROOT / "assets/recipes/fitness_recipes.json"
    destination.write_text(json.dumps(R, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(R)} recipes to {destination}")
