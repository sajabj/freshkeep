import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/content_frame.dart';
import '../../inventory/presentation/food_photo.dart';
import '../../shopping/domain/shopping_item.dart';
import '../application/storage_guide_provider.dart';
import '../domain/storage_food.dart';

String _t(BuildContext c, String ar, String en) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;

class StorageGuideScreen extends ConsumerStatefulWidget {
  const StorageGuideScreen({super.key});
  @override
  ConsumerState<StorageGuideScreen> createState() => _StorageGuideState();
}

class _StorageGuideState extends ConsumerState<StorageGuideScreen> {
  String query = '', category = 'all';
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final value = ref.watch(storageGuideProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'دليل حفظ الطعام', 'Food Storage Guide')),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(storageGuideProvider),
            child: Text(_t(context, 'إعادة المحاولة', 'Try again')),
          ),
        ),
        data: (foods) {
          final q = normalizedFoodName(query);
          final rows = foods
              .where(
                (f) =>
                    (category == 'all' || f.category == category) &&
                    (q.isEmpty ||
                        normalizedFoodName(
                          '${f.name.ar} ${f.name.en} ${f.aliases.join(' ')}',
                        ).contains(q)),
              )
              .toList();
          return ContentFrame(
            children: [
              Text(
                _t(
                  context,
                  'إرشادات محلية تعمل دون إنترنت. حالة العبوة وتعليمات المُصنّع وتاريخ الملصق لها الأولوية دائمًا.',
                  'Offline guidance. Package condition, manufacturer directions and the label date always take priority.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('storage-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: _t(
                    context,
                    'ابحث بالعربية أو الإنجليزية',
                    'Search in Arabic or English',
                  ),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in const [
                    'all',
                    'fruit',
                    'vegetables',
                    'dairy',
                    'protein',
                    'grains',
                    'canned',
                    'frozen',
                  ])
                    ChoiceChip(
                      selected: category == c,
                      label: Text(_category(context, c)),
                      onSelected: (_) => setState(() => category = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _t(
                      context,
                      'لا توجد إرشادات مطابقة. لا نعرض نصيحة لطعام مختلف.',
                      'No exact guide match. FreshKeep will not substitute advice for another food.',
                    ),
                  ),
                ),
              for (final f in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: FoodPhoto(
                        name: f.id,
                        categoryId: f.category,
                        size: 58,
                      ),
                      title: Text(f.name.get(lang)),
                      subtitle: Text(
                        f.location.get(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StorageFoodDetailScreen(food: f),
                        ),
                      ),
                    ),
                  ),
                ),
              Text(
                _t(
                  context,
                  'المصادر: FDA وFoodSafety.gov (USDA/HHS) • مراجعة المحتوى: 21 أكتوبر 2026',
                  'Sources: FDA and FoodSafety.gov (USDA/HHS) • Content reviewed 21 Oct 2026',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

String _category(BuildContext c, String id) => switch (id) {
  'all' => _t(c, 'الكل', 'All'),
  'fruit' => _t(c, 'فواكه', 'Fruit'),
  'vegetables' => _t(c, 'خضار', 'Vegetables'),
  'dairy' => _t(c, 'ألبان', 'Dairy'),
  'protein' => _t(c, 'بروتين', 'Protein'),
  'grains' => _t(c, 'حبوب ومخبوزات', 'Grains & bakery'),
  'canned' => _t(c, 'معلبات', 'Canned'),
  'frozen' => _t(c, 'مجمد', 'Frozen'),
  _ => id,
};

class StorageFoodDetailScreen extends StatelessWidget {
  const StorageFoodDetailScreen({super.key, required this.food});
  final StorageFood food;
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(food.name.get(lang))),
      body: ContentFrame(
        children: [
          FoodPhoto(
            name: food.id,
            categoryId: food.category,
            size: 150,
            borderRadius: 24,
          ),
          const SizedBox(height: 18),
          _section(
            context,
            _t(context, 'أفضل مكان', 'Best place'),
            food.location.get(lang),
            Icons.kitchen_outlined,
          ),
          _section(
            context,
            _t(context, 'نصائح عملية', 'Practical tips'),
            food.tips.map((e) => '• ${e.get(lang)}').join('\n'),
            Icons.tips_and_updates_outlined,
          ),
          _section(
            context,
            _t(context, 'بعد الفتح أو القطع', 'After opening or cutting'),
            food.opened.get(lang),
            Icons.inventory_2_outlined,
          ),
          _section(
            context,
            _t(context, 'التجميد', 'Freezing'),
            food.freezing.get(lang),
            Icons.ac_unit,
          ),
          _section(
            context,
            _t(context, 'خطأ شائع', 'Common mistake'),
            food.mistakes.get(lang),
            Icons.warning_amber_rounded,
          ),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _t(
                  context,
                  food.safety
                      ? 'هذه الإرشادات تتضمن جانبًا متعلقًا بالسلامة. الثلاجة 4°م أو أقل والمجمّد −18°م أو أقل. عند الشك اتبع الجهة الصحية المحلية.'
                      : 'هذه النصيحة تخص الجودة أساسًا. افحص التلف واتبع الملصق.',
                  food.safety
                      ? 'This entry includes food-safety guidance. Keep the refrigerator at 4°C / 40°F or below and freezer at 0°F / −18°C. When unsure, follow local health advice.'
                      : 'This guidance mainly concerns quality. Check for spoilage and follow the label.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              context,
              'تعليمات العبوة وتاريخ الشركة المصنّعة وحالة الطعام الفعلية تتقدم على هذا الدليل العام.',
              'Package directions, manufacturer date and the food’s actual condition override this general guide.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Widget _section(BuildContext c, String title, String body, IconData icon) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(c).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

class FoodStorageCard extends ConsumerWidget {
  const FoodStorageCard({super.key, required this.foodName});
  final String foodName;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(storageGuideProvider)
      .when(
        loading: () => const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        ),
        error: (_, _) => const SizedBox(),
        data: (foods) {
          final match = exactStorageMatch(foods, foodName);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t(
                      context,
                      'كيف أحفظ هذا المنتج؟',
                      'How to Store This Food',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (match == null)
                    Text(
                      _t(
                        context,
                        'لا توجد مطابقة دقيقة لهذا الاسم. افتح الدليل وابحث يدويًا؛ لن نعرض نصيحة لطعام آخر.',
                        'No exact name match. Open the guide and search manually; advice for another food will not be substituted.',
                      ),
                    )
                  else ...[
                    Text(
                      match.location.get(
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final tip in match.tips.take(2))
                      Text(
                        '• ${tip.get(Localizations.localeOf(context).languageCode)}',
                      ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StorageFoodDetailScreen(food: match),
                        ),
                      ),
                      child: Text(
                        _t(context, 'التفاصيل الكاملة', 'Full details'),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StorageGuideScreen(),
                      ),
                    ),
                    child: Text(
                      _t(context, 'فتح دليل الحفظ', 'Open storage guide'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
