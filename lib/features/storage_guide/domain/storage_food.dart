import '../../shopping/domain/shopping_item.dart';

class LocalizedText {
  const LocalizedText(this.ar, this.en);
  factory LocalizedText.fromJson(Map<String, dynamic> j) =>
      LocalizedText(j['ar'] as String, j['en'] as String);
  final String ar, en;
  String get(String language) => language == 'ar' ? ar : en;
}

class StorageFood {
  StorageFood.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = LocalizedText.fromJson(j['name'] as Map<String, dynamic>),
      category = j['category'] as String,
      aliases = List<String>.from(j['aliases'] as List),
      location = LocalizedText.fromJson(j['location'] as Map<String, dynamic>),
      tips = (j['tips'] as List)
          .map((e) => LocalizedText.fromJson(e as Map<String, dynamic>))
          .toList(),
      freezing = LocalizedText.fromJson(j['freezing'] as Map<String, dynamic>),
      mistakes = LocalizedText.fromJson(j['mistakes'] as Map<String, dynamic>),
      opened = LocalizedText.fromJson(j['opened'] as Map<String, dynamic>),
      safety = j['safety'] as bool,
      sourceIds = List<String>.from(j['sources'] as List);
  final String id, category;
  final LocalizedText name, location, freezing, mistakes, opened;
  final List<LocalizedText> tips;
  final List<String> aliases, sourceIds;
  final bool safety;
  bool matchesExactly(String value) {
    final n = normalizedFoodName(value);
    return <String>[
      name.ar,
      name.en,
      ...aliases,
    ].map(normalizedFoodName).contains(n);
  }
}

StorageFood? exactStorageMatch(List<StorageFood> foods, String name) {
  final found = foods.where((f) => f.matchesExactly(name)).toList();
  return found.length == 1 ? found.single : null;
}
