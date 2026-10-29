import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/features/scanning/domain/date_candidates.dart';
import 'package:freshkeep/features/scanning/data/product_lookup.dart';

void main() {
  test('camera UPC-E expands without changing manual EAN-8', () {
    expect(expandUpce('04252614'), '042100005264');
    expect(productBarcode('04252614'), '04252614');
    expect(expandUpce('87654321'), isNull);
  });
  test('Arabic/Persian digits, ISO, leap days and named months', () {
    final dates = parseDateCandidates(
      'EXP ٢٠٢٨/٠٢/٢٩\nBEST BEFORE 31 DEC 2027\nEXP ۲۸.۰۲.۲۰۲۷',
    );
    expect(
      dates.map((d) => d.date),
      containsAll([
        DateTime(2028, 2, 29),
        DateTime(2027, 12, 31),
        DateTime(2027, 2, 28),
      ]),
    );
    expect(dates.first.kind, PrintedDateKind.expiry);
    expect(dates[1].kind, PrintedDateKind.bestBefore);
  });
  test('ambiguous DMY/MDY must expose both choices', () {
    final dates = parseDateCandidates('EXP 03/04/27');
    expect(
      dates.map((d) => d.date),
      containsAll([DateTime(2027, 4, 3), DateTime(2027, 3, 4)]),
    );
    expect(dates.every((d) => d.ambiguous), isTrue);
  });
  test('separate manufacture from expiry on same or adjacent lines', () {
    final dates = parseDateCandidates(
      'MFG 15/10/2026 EXP 20/11/2027\nBEST BEFORE\n31/12/2027',
    );
    expect(
      dates.where((d) => d.kind == PrintedDateKind.manufacture).single.date,
      DateTime(2026, 10, 15),
    );
    expect(
      dates.where((d) => d.kind == PrintedDateKind.expiry).single.date,
      DateTime(2027, 11, 20),
    );
    expect(
      dates.where((d) => d.kind == PrintedDateKind.bestBefore).single.date,
      DateTime(2027, 12, 31),
    );
  });
  test('reject impossible and partial dates, leave unlabeled unknown', () {
    expect(parseDateCandidates('EXP 31/02/2027\n02/2028\n2027-13-30'), isEmpty);
    expect(
      parseDateCandidates('20/11/2027').single.kind,
      PrintedDateKind.unknown,
    );
  });
  test('barcode input and conservative quantity interpretation', () {
    expect(productBarcode(' ٣٠١٧٦٢٠٤٢٢٠٠٣ '), '3017620422003');
    expect(productBarcode('https://example.org'), isNull);
    expect(productBarcode('12345'), isNull);
    expect(
      const ProductData(
        barcode: '12345678',
        quantity: '250 ml',
      ).measuredQuantity,
      (250.0, 'ml'),
    );
    expect(
      const ProductData(
        barcode: '12345678',
        quantity: '6 x 250 ml',
      ).measuredQuantity,
      isNull,
    );
  });
}
