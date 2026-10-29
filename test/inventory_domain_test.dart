import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/inventory/domain/inventory_query.dart';
import 'package:freshkeep/features/inventory/presentation/food_labels.dart';

import 'support/food_fixture.dart';

void main() {
  test('use first does not suggest past dates or archived food', () {
    final today = DateTime(2026, 10, 20);
    final result = useFirstItems([
      foodFixture(id: 'past', expiry: DateTime(2026, 10, 19)),
      foodFixture(id: 'today', expiry: today),
      foodFixture(id: 'used', status: FoodStatus.used),
    ], today);
    expect(result.map((i) => i.id), ['today']);
  });
  test(
    'calendar differences ignore time of day and daylight-saving boundaries',
    () {
      expect(
        daysUntil(DateTime(2026, 10, 26), DateTime(2026, 10, 24, 23, 59)),
        2,
      );
      expect(daysUntil(DateTime(2026, 3, 30), DateTime(2026, 3, 28)), 2);
      expect(daysUntil(DateTime(2028, 3, 1), DateTime(2028, 2, 28)), 2);
      expect(daysUntil(DateTime(2026, 10, 20), DateTime(2026, 10, 20, 23)), 0);
      expect(daysUntil(DateTime(2026, 10, 19), DateTime(2026, 10, 20)), -1);
    },
  );
  test('Arabic, Persian and decimal input is understood without accepting NaN as quantity', () {
    expect(parseFoodNumber('١٢٫٥'), 12.5);
    expect(parseFoodNumber('۲,۵'), 2.5);
    expect(parseFoodNumber('wrong'), isNull);
    expect(
      () => foodFixture(quantity: double.infinity).validate(),
      throwsArgumentError,
    );
  });
  test('query combines search, category, storage, lifecycle and ordering', () {
    final items = [
      foodFixture(id: 'a', name: 'Milk'),
      foodFixture(id: 'b', name: 'Oat MILK', storage: StoragePlace.pantry),
      foodFixture(id: 'c', name: 'Apple', category: 'fruit'),
      foodFixture(id: 'd', name: 'Milk', status: FoodStatus.used),
    ];
    expect(
      const InventoryQuery(
        search: 'milk',
        storage: StoragePlace.fridge,
        category: 'dairy',
      ).apply(items).map((i) => i.id),
      ['a'],
    );
    expect(
      const InventoryQuery(status: FoodStatus.used).apply(items).single.id,
      'd',
    );
    expect(
      const InventoryQuery(sort: InventorySort.name).apply(items).first.name,
      'Apple',
    );
  });
}
