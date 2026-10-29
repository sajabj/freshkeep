import 'package:freshkeep/features/inventory/domain/food_item.dart';

FoodItem foodFixture({
  String id = 'batch-1',
  String name = 'Milk',
  String category = 'dairy',
  String unit = 'L',
  DateTime? expiry,
  double quantity = 1,
  String? barcode = '123456789',
  FoodStatus status = FoodStatus.available,
  StoragePlace storage = StoragePlace.fridge,
  int revision = 0,
}) => FoodItem(
  id: id,
  name: name,
  categoryId: category,
  quantity: quantity,
  unit: unit,
  expiryDate: expiry ?? DateTime(2026, 10, 23),
  barcode: barcode,
  status: status,
  storage: storage,
  revision: revision,
  createdAt: DateTime(2026, 10, 20, 10),
  updatedAt: DateTime(2026, 10, 20, 10),
);
