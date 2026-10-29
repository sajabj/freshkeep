enum FoodStatus { available, used, discarded }

enum DateKind { expiry, bestBefore, unknown }

enum StoragePlace { fridge, freezer, pantry, other }

const categoryIds = [
  'dairy',
  'vegetables',
  'fruit',
  'meat',
  'bakery',
  'canned',
  'drinks',
  'frozen',
  'grains',
  'other',
];

/// Calendar dates are stored without a timezone. Compare civil days, not
/// elapsed 24-hour periods, so daylight-saving changes do not shift results.
DateTime calendarDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);
int daysUntil(DateTime date, DateTime now) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.brand,
    this.purchaseDate,
    this.dateKind = DateKind.unknown,
    this.storage = StoragePlace.fridge,
    this.price,
    this.imagePath,
    this.sourceUrl,
    this.status = FoodStatus.available,
    this.statusChangedAt,
    this.disposalReason,
    this.revision = 0,
  });
  final String id, name, categoryId, unit;
  final String? barcode, brand, imagePath, disposalReason, sourceUrl;
  final double quantity;

  /// Total purchase price for this batch, in the user's chosen currency.
  final double? price;
  final DateTime expiryDate, createdAt, updatedAt;
  final DateTime? purchaseDate, statusChangedAt;
  final DateKind dateKind;
  final StoragePlace storage;
  final FoodStatus status;
  final int revision;

  void validate() {
    if (id.isEmpty ||
        name.trim().isEmpty ||
        name.trim().length > 100 ||
        !categoryIds.contains(categoryId) ||
        !quantity.isFinite ||
        quantity < 0 ||
        (quantity == 0 && status != FoodStatus.used) ||
        unit.trim().isEmpty ||
        unit.length > 24 ||
        (price != null && (!price!.isFinite || price! < 0)) ||
        revision < 0) {
      throw ArgumentError('Invalid food item');
    }
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name.trim(),
    'category_id': categoryId,
    'quantity': quantity,
    'unit': unit.trim(),
    'expiry_date': dateKey(expiryDate),
    'barcode': barcode,
    'brand': brand,
    'purchase_date': purchaseDate == null ? null : dateKey(purchaseDate!),
    'date_kind': dateKind.name,
    'storage': storage.name,
    'price': price,
    'image_path': imagePath,
    if (sourceUrl != null) 'source_url': sourceUrl,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'status': status.name,
    'status_changed_at': statusChangedAt?.toUtc().toIso8601String(),
    'disposal_reason': disposalReason,
    'revision': revision,
  };
  factory FoodItem.fromMap(Map<String, Object?> m) => FoodItem(
    id: m['id'] as String,
    name: m['name'] as String,
    categoryId: m['category_id'] as String,
    quantity: (m['quantity'] as num).toDouble(),
    unit: m['unit'] as String,
    expiryDate: DateTime.parse(m['expiry_date'] as String),
    barcode: m['barcode'] as String?,
    brand: m['brand'] as String?,
    purchaseDate: m['purchase_date'] == null
        ? null
        : DateTime.parse(m['purchase_date'] as String),
    dateKind: DateKind.values.byName(m['date_kind'] as String),
    storage: StoragePlace.values.byName(m['storage'] as String),
    price: (m['price'] as num?)?.toDouble(),
    imagePath: m['image_path'] as String?,
    sourceUrl: m['source_url'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
    updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
    status: FoodStatus.values.byName(m['status'] as String),
    statusChangedAt: m['status_changed_at'] == null
        ? null
        : DateTime.parse(m['status_changed_at'] as String).toLocal(),
    disposalReason: m['disposal_reason'] as String?,
    revision: m['revision'] as int,
  );
}
