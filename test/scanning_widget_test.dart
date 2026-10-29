import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/core/theme/app_theme.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/features/inventory/presentation/food_form_screen.dart';
import 'package:freshkeep/features/scanning/data/date_ocr.dart';
import 'package:freshkeep/features/scanning/data/product_lookup.dart';
import 'package:freshkeep/features/scanning/presentation/barcode_scan_screen.dart';
import 'package:freshkeep/features/scanning/presentation/date_scan_screen.dart';
import 'package:freshkeep/l10n/generated/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/memory_inventory_repository.dart';
import 'support/test_scanner_platform.dart';

class TestOcr extends DateOcr {
  TestOcr(this.text, {this.fail = false});
  final String text;
  final bool fail;
  @override
  Future<String?> pickAndRead(ImageSource source) async {
    if (fail) throw StateError('denied');
    return text;
  }
}

Future<void> pressScan(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.tap(finder);
  await t.pumpAndSettle();
}

Widget host(
  Widget child, {
  String language = 'en',
  ThemeMode mode = ThemeMode.light,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.create(Brightness.light),
  darkTheme: AppTheme.create(Brightness.dark),
  themeMode: mode,
  home: child,
);

void main() {
  sqfliteFfiInit();
  late Database db;
  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() => db.close());
  testWidgets('denied camera shows explanation and manual barcode entry', (
    t,
  ) async {
    final original = MobileScannerPlatform.instance;
    final platform = TestScannerPlatform(denied: true);
    MobileScannerPlatform.instance = platform;
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
      MobileScannerPlatform.instance = original;
      await platform.captures.close();
    });
    await t.pumpWidget(
      ProviderScope(
        child: host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: BarcodeScanScreen(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('Camera unavailable'), findsOneWidget);
    await pressScan(t, find.text('Enter barcode instead'));
    expect(find.byKey(const Key('scan-barcode-input')), findsOneWidget);
  });
  testWidgets('repeated camera frames submit one lookup and stop the camera', (
    t,
  ) async {
    final original = MobileScannerPlatform.instance;
    final platform = TestScannerPlatform();
    MobileScannerPlatform.instance = platform;
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
      MobileScannerPlatform.instance = original;
      await platform.captures.close();
    });
    var calls = 0;
    final response = Completer<http.Response>();
    final client = MockClient((_) {
      calls++;
      return response.future;
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          productLookupProvider.overrideWith(
            (ref) async => ProductLookup(db, client),
          ),
        ],
        child: host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: BarcodeScanScreen(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final capture = BarcodeCapture(
      barcodes: [
        const Barcode(rawValue: '3017620422003', format: BarcodeFormat.ean13),
      ],
    );
    platform.captures.add(capture);
    platform.captures.add(capture);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    response.complete(
      http.Response(
        jsonEncode({
          'product': {'product_name': 'Milk'},
        }),
        200,
      ),
    );
    await t.pumpAndSettle();
    expect(calls, 1);
    expect(platform.stops, greaterThanOrEqualTo(1));
    expect(find.text('Review product'), findsOneWidget);
  });
  Future<void> launchBarcode(
    WidgetTester t,
    http.Client client,
    void Function(ProductData?) result, {
    String language = 'en',
  }) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          productLookupProvider.overrideWith(
            (ref) async => ProductLookup(db, client),
          ),
        ],
        child: host(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result(
                    await Navigator.of(context).push<ProductData>(
                      MaterialPageRoute(
                        builder: (_) =>
                            const BarcodeScanScreen(cameraEnabled: false),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
          language: language,
        ),
      ),
    );
    await pressScan(t, find.text('open'));
    await t.enterText(
      find.byKey(const Key('scan-barcode-input')),
      '3017620422003',
    );
    await pressScan(t, find.byKey(const Key('lookup-barcode')));
  }

  testWidgets(
    'found product requires review and returns editable metadata without saving',
    (t) async {
      ProductData? returned;
      var calls = 0;
      await launchBarcode(
        t,
        MockClient((_) async {
          calls++;
          return http.Response(
            jsonEncode({
              'product': {
                'product_name': 'Milk',
                'brands': 'Farm',
                'quantity': '1 l',
              },
            }),
            200,
          );
        }),
        (p) => returned = p,
      );
      expect(returned, isNull);
      expect(find.text('Review product'), findsOneWidget);
      expect(await db.query('food_items'), isEmpty);
      await pressScan(t, find.byKey(const Key('accept-product')));
      expect(returned!.name, 'Milk');
      expect(returned!.measuredQuantity, (1.0, 'l'));
      expect(calls, 1);
    },
  );
  testWidgets(
    'reviewed barcode fills the existing form and keeps expiry mandatory',
    (t) async {
      final repo = MemoryInventoryRepository([]);
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'product': {
              'product_name': 'Milk',
              'brands': 'Farm',
              'quantity': '250 ml',
            },
          }),
          200,
        ),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            scannerCameraEnabledProvider.overrideWithValue(false),
            productLookupProvider.overrideWith(
              (ref) async => ProductLookup(db, client),
            ),
            inventoryRepositoryProvider.overrideWith((ref) async => repo),
          ],
          child: host(const FoodFormScreen()),
        ),
      );
      await pressScan(t, find.byKey(const Key('scan-product')));
      await t.enterText(
        find.byKey(const Key('scan-barcode-input')),
        '3017620422003',
      );
      await pressScan(t, find.byKey(const Key('lookup-barcode')));
      await pressScan(t, find.byKey(const Key('accept-product')));
      expect(find.widgetWithText(TextFormField, 'Milk'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '250.0'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'ml'), findsOneWidget);
      await pressScan(t, find.byKey(const Key('save-food')));
      expect(find.textContaining('Choose'), findsWidgets);
      expect(await repo.load(), isEmpty);
      await pressScan(t, find.byKey(const Key('choose-expiry')));
      final picker = find.byType(DatePickerDialog);
      await pressScan(
        t,
        find.text(MaterialLocalizations.of(t.element(picker)).okButtonLabel),
      );
      await pressScan(t, find.byKey(const Key('save-food')));
      expect((await repo.load()).single.barcode, '3017620422003');
      expect(
        (await repo.load()).single.sourceUrl,
        contains('/product/3017620422003'),
      );
    },
  );
  testWidgets('unknown product returns barcode to manual form', (t) async {
    ProductData? returned;
    await launchBarcode(
      t,
      MockClient((_) async => http.Response('{}', 404)),
      (p) => returned = p,
    );
    expect(returned!.barcode, '3017620422003');
    expect(returned!.name, isEmpty);
  });
  testWidgets('offline lookup offers manual fallback with barcode retained', (
    t,
  ) async {
    ProductData? returned;
    await launchBarcode(
      t,
      MockClient((_) async => throw http.ClientException('offline')),
      (p) => returned = p,
    );
    expect(find.textContaining('Cannot connect'), findsOneWidget);
    expect(returned, isNull);
    await pressScan(t, find.byKey(const Key('barcode-fallback')));
    expect(returned!.barcode, '3017620422003');
  });
  testWidgets(
    'OCR cannot apply manufacture; expiry is applied only after picker confirmation',
    (t) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            dateOcrProvider.overrideWithValue(
              TestOcr('MFG 15/10/2026\nEXP 20/11/2027'),
            ),
            inventoryRepositoryProvider.overrideWith(
              (ref) async => MemoryInventoryRepository([]),
            ),
          ],
          child: host(const FoodFormScreen()),
        ),
      );
      await pressScan(t, find.byKey(const Key('scan-date')));
      await pressScan(t, find.byKey(const Key('ocr-gallery')));
      expect(find.textContaining('Manufacture date'), findsOneWidget);
      expect(find.text('Confirm or correct date'), findsOneWidget);
      await pressScan(t, find.text('Confirm or correct date'));
      final picker = find.byType(DatePickerDialog);
      await pressScan(
        t,
        find.text(
          MaterialLocalizations.of(t.element(picker)).cancelButtonLabel,
        ),
      );
      expect(find.byType(DateScanScreen), findsOneWidget);
      await pressScan(t, find.text('Confirm or correct date'));
      await pressScan(
        t,
        find.text(MaterialLocalizations.of(t.element(picker)).okButtonLabel),
      );
      expect(find.byType(DateScanScreen), findsNothing);
      expect(find.textContaining('2027'), findsOneWidget);
      expect(await db.query('food_items'), isEmpty);
    },
  );
  testWidgets('OCR failure and cancellation permit manual date entry', (
    t,
  ) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [dateOcrProvider.overrideWithValue(TestOcr('', fail: true))],
        child: host(const DateScanScreen()),
      ),
    );
    await pressScan(t, find.byKey(const Key('ocr-camera')));
    expect(find.textContaining('Could not read'), findsOneWidget);
    await pressScan(t, find.byKey(const Key('ocr-manual')));
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
  for (final language in ['ar', 'en']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'scan controls fit small $language ${mode.name} with large text',
        (t) async {
          t.view.physicalSize = const Size(320, 568);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(
            ProviderScope(
              child: host(
                const MediaQuery(
                  data: MediaQueryData(
                    size: Size(320, 568),
                    textScaler: TextScaler.linear(1.5),
                    disableAnimations: true,
                  ),
                  child: BarcodeScanScreen(cameraEnabled: false),
                ),
                language: language,
                mode: mode,
              ),
            ),
          );
          await t.pumpAndSettle();
          await t.drag(find.byType(ListView), const Offset(0, -400));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
