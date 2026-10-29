import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:freshkeep/features/scanning/data/date_ocr.dart';
import 'package:freshkeep/features/scanning/presentation/barcode_scan_screen.dart';
import 'package:freshkeep/features/scanning/presentation/date_scan_screen.dart';

import 'scanning_widget_test.dart' show TestOcr, host, pressScan;
import 'support/test_scanner_platform.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('NotoSansArabic')..addFont(
          Future.value(
            ByteData.sublistView(
              await File('assets/fonts/NotoSansArabic.ttf').readAsBytes(),
            ),
          ),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final language in ['ar', 'en']) {
    testWidgets('camera frame visual $language', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final original = MobileScannerPlatform.instance;
      final platform = TestScannerPlatform();
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
              data: MediaQueryData(
                size: Size(390, 844),
                disableAnimations: true,
              ),
              child: BarcodeScanScreen(),
            ),
            language: language,
            mode: language == 'ar' ? ThemeMode.light : ThemeMode.dark,
          ),
        ),
      );
      await t.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/scan_camera_$language.png'),
      );
    });
  }
  for (final language in ['ar', 'en']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final width in [320.0, 390.0, 768.0]) {
        testWidgets('scan date visual $language ${mode.name} $width', (
          t,
        ) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                dateOcrProvider.overrideWithValue(
                  TestOcr('EXP 03/04/2027\nMFG 15/10/2026'),
                ),
              ],
              child: host(
                const DateScanScreen(),
                language: language,
                mode: mode,
              ),
            ),
          );
          await t.pumpAndSettle();
          await pressScan(t, find.byKey(const Key('ocr-gallery')));
          expect(t.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/scan_date_${language}_${mode.name}_${width.toInt()}.png',
            ),
          );
        });
      }
      testWidgets('barcode manual visual $language ${mode.name}', (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          ProviderScope(
            child: host(
              const BarcodeScanScreen(cameraEnabled: false),
              language: language,
              mode: mode,
            ),
          ),
        );
        await t.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/scan_barcode_${language}_${mode.name}.png',
          ),
        );
      });
    }
  }
}
