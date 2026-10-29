import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/food_item.dart';

String categoryLabel(AppLocalizations l, String id) => switch (id) {
  'dairy' => l.dairy,
  'vegetables' => l.vegetables,
  'fruit' => l.fruit,
  'meat' => l.meat,
  'bakery' => l.bakery,
  'canned' => l.canned,
  'drinks' => l.drinks,
  'frozen' => l.frozen,
  'grains' => l.grains,
  _ => l.other,
};
String storageLabel(AppLocalizations l, StoragePlace place) => switch (place) {
  StoragePlace.fridge => l.fridge,
  StoragePlace.freezer => l.freezer,
  StoragePlace.pantry => l.pantry,
  StoragePlace.other => l.other,
};
String statusLabel(AppLocalizations l, FoodStatus status) => switch (status) {
  FoodStatus.available => l.available,
  FoodStatus.used => l.used,
  FoodStatus.discarded => l.discarded,
};
String kindLabel(AppLocalizations l, DateKind kind) => switch (kind) {
  DateKind.expiry => l.expiryKind,
  DateKind.bestBefore => l.bestBeforeKind,
  DateKind.unknown => l.unknownKind,
};
String formattedDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(date);
String remainingLabel(AppLocalizations l, FoodItem item, DateTime today) {
  final days = daysUntil(item.expiryDate, today);
  return days < 0
      ? l.pastDate
      : days == 0
      ? l.todayDate
      : l.remainingDays(days);
}

double? parseFoodNumber(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var normalized = value.trim();
  for (var i = 0; i < 10; i++) {
    normalized = normalized
        .replaceAll(arabic[i], '$i')
        .replaceAll(persian[i], '$i');
  }
  normalized = normalized.replaceAll('٫', '.').replaceAll(',', '.');
  return double.tryParse(normalized);
}
