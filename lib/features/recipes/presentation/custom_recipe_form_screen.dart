import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/content_frame.dart';
import '../application/recipe_controller.dart';
import '../data/recipe_photo_store.dart';
import '../domain/recipe.dart';
import '../../shopping/domain/shopping_item.dart';

String _r(BuildContext c, String ar, String en) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;

class _IngredientFields {
  _IngredientFields({String name = '', String amount = '', String unit = ''})
    : name = TextEditingController(text: name),
      amount = TextEditingController(text: amount),
      unit = TextEditingController(text: unit);
  final TextEditingController name, amount, unit;
  void dispose() {
    name.dispose();
    amount.dispose();
    unit.dispose();
  }
}

class CustomRecipeFormScreen extends ConsumerStatefulWidget {
  const CustomRecipeFormScreen({super.key, this.recipe});
  final Recipe? recipe;
  @override
  ConsumerState<CustomRecipeFormScreen> createState() =>
      _CustomRecipeFormState();
}

class _CustomRecipeFormState extends ConsumerState<CustomRecipeFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, description, prep, cook, servings;
  late List<_IngredientFields> ingredients;
  late List<TextEditingController> steps;
  String category = 'lunch';
  String? image;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final x = widget.recipe;
    name = TextEditingController(text: x?.en ?? '');
    description = TextEditingController(text: x?.description ?? '');
    prep = TextEditingController(text: x?.prepMinutes.toString() ?? '');
    cook = TextEditingController(text: x?.cookMinutes?.toString() ?? '');
    servings = TextEditingController(text: x?.servings.toString() ?? '');
    category = x?.category ?? 'lunch';
    image = x?.imagePath;
    ingredients =
        x?.ingredients
            .map(
              (i) => _IngredientFields(
                name: i.en,
                amount: i.amount.toString(),
                unit: i.unit,
              ),
            )
            .toList() ??
        [_IngredientFields()];
    steps =
        x?.stepsEn.map((text) => TextEditingController(text: text)).toList() ??
        [TextEditingController()];
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    prep.dispose();
    cook.dispose();
    servings.dispose();
    for (final i in ingredients) {
      i.dispose();
    }
    for (final s in steps) {
      s.dispose();
    }
    super.dispose();
  }

  int? positive(String v) => int.tryParse(v.trim());
  Future<void> save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final lang = Localizations.localeOf(context).languageCode;
    final id = widget.recipe?.id ?? 'user:${const Uuid().v4()}';
    final data = <String, dynamic>{
      'id': id,
      'ar': name.text.trim(),
      'en': name.text.trim(),
      'description': description.text.trim(),
      'category': category,
      'prepMinutes': positive(prep.text)!,
      'cookMinutes': positive(cook.text)!,
      'minutes': positive(prep.text)! + positive(cook.text)!,
      'servings': positive(servings.text)!,
      'art': 'custom',
      'imagePath': image,
      'personal': true,
      'ingredients': [
        for (var n = 0; n < ingredients.length; n++)
          {
            'key': 'user_${normalizedFoodName(ingredients[n].name.text)}',
            'ar': ingredients[n].name.text.trim(),
            'en': ingredients[n].name.text.trim(),
            'aliases': [ingredients[n].name.text.trim()],
            'amount': double.parse(ingredients[n].amount.text),
            'unit': ingredients[n].unit.text.trim().isEmpty
                ? 'unit'
                : ingredients[n].unit.text.trim(),
          },
      ],
      'stepsAr': steps.map((e) => e.text.trim()).toList(),
      'stepsEn': steps.map((e) => e.text.trim()).toList(),
      'inputLanguage': lang,
    };
    try {
      await ref
          .read(recipesProvider.notifier)
          .saveCustom(data, isNew: widget.recipe == null);
      if (widget.recipe?.imagePath != image) {
        await RecipePhotoStore().delete(widget.recipe?.imagePath);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String? requiredText(String? v) =>
      v == null || v.trim().isEmpty ? _r(context, 'مطلوب', 'Required') : null;
  String? positiveInt(String? v) {
    final n = int.tryParse(v ?? '');
    return n == null || n <= 0
        ? _r(
            context,
            'أدخل عددًا صحيحًا أكبر من صفر',
            'Enter a whole number above zero',
          )
        : null;
  }

  String? positiveAmount(String? v) {
    final n = double.tryParse(v ?? '');
    return n == null || !n.isFinite || n <= 0
        ? _r(context, 'أدخل كمية أكبر من صفر', 'Enter an amount above zero')
        : null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.recipe == null
            ? _r(context, 'وصفة شخصية جديدة', 'New personal recipe')
            : _r(context, 'تعديل الوصفة', 'Edit recipe'),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: form,
        child: ContentFrame(
          children: [
            TextFormField(
              controller: name,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: _r(context, 'اسم الوصفة', 'Recipe name'),
              ),
              validator: requiredText,
            ),
            TextFormField(
              controller: description,
              maxLength: 300,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _r(
                  context,
                  'وصف مختصر (اختياري)',
                  'Short description (optional)',
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: InputDecoration(
                labelText: _r(context, 'التصنيف', 'Category'),
              ),
              items:
                  [
                        ('breakfast', _r(context, 'فطور', 'Breakfast')),
                        ('lunch', _r(context, 'غداء', 'Lunch')),
                        ('dinner', _r(context, 'عشاء', 'Dinner')),
                        ('snack', _r(context, 'وجبة خفيفة', 'Snack')),
                        ('salad', _r(context, 'سلطة', 'Salad')),
                      ]
                      .map(
                        (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: prep,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _r(context, 'دقائق التحضير', 'Prep minutes'),
                    ),
                    validator: positiveInt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: cook,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _r(context, 'دقائق الطبخ', 'Cook minutes'),
                    ),
                    validator: positiveInt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: servings,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _r(context, 'عدد الحصص', 'Servings'),
              ),
              validator: positiveInt,
            ),
            const SizedBox(height: 20),
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(image!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: busy ? null : () => pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_r(context, 'المعرض', 'Gallery')),
                ),
                TextButton.icon(
                  onPressed: busy ? null : () => pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(_r(context, 'الكاميرا', 'Camera')),
                ),
                if (image != null)
                  TextButton(
                    onPressed: busy ? null : () => setState(() => image = null),
                    child: Text(_r(context, 'إزالة الصورة', 'Remove photo')),
                  ),
              ],
            ),
            const Divider(height: 32),
            Text(
              _r(context, 'المكونات', 'Ingredients'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (var i = 0; i < ingredients.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: ingredients[i].name,
                        decoration: InputDecoration(
                          labelText: _r(context, 'المكون', 'Ingredient'),
                        ),
                        validator: requiredText,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: ingredients[i].amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: _r(context, 'الكمية', 'Amount'),
                              ),
                              validator: positiveAmount,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: ingredients[i].unit,
                              decoration: InputDecoration(
                                labelText: _r(
                                  context,
                                  'الوحدة (اختيارية)',
                                  'Unit (optional)',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (ingredients.length > 1)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: IconButton(
                            onPressed: () => setState(
                              () => ingredients.removeAt(i).dispose(),
                            ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => ingredients.add(_IngredientFields())),
              icon: const Icon(Icons.add),
              label: Text(_r(context, 'إضافة مكون', 'Add ingredient')),
            ),
            const Divider(height: 32),
            Text(
              _r(context, 'خطوات التحضير', 'Method steps'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (var i = 0; i < steps.length; i++)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: TextFormField(
                    controller: steps[i],
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: _r(context, 'الخطوة', 'Step'),
                    ),
                    validator: requiredText,
                  ),
                  trailing: Column(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: IconButton(
                            onPressed: () => setState(() {
                              final x = steps.removeAt(i);
                              steps.insert(i - 1, x);
                            }),
                            icon: const Icon(Icons.arrow_upward, size: 18),
                          ),
                        ),
                      if (steps.length > 1)
                        Expanded(
                          child: IconButton(
                            onPressed: () =>
                                setState(() => steps.removeAt(i).dispose()),
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => steps.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: Text(_r(context, 'إضافة خطوة', 'Add step')),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                busy
                    ? _r(context, 'جارٍ الحفظ…', 'Saving…')
                    : _r(context, 'حفظ الوصفة', 'Save recipe'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> pick(ImageSource source) async {
    final old = image;
    final next = await RecipePhotoStore().pick(source);
    if (next != null && mounted) {
      setState(() => image = next);
      if (old != widget.recipe?.imagePath) await RecipePhotoStore().delete(old);
    }
  }
}
