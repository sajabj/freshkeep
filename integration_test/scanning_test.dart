import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:freshkeep/features/scanning/data/date_ocr.dart';
import 'package:freshkeep/features/scanning/domain/date_candidates.dart';

/// Generated images are explicit test fixtures, never application product data.
Future<File> fixturePng(
  void Function(Canvas) draw,
  int width,
  int height,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(
    '${(await getTemporaryDirectory()).path}/freshkeep-scan-test-${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return file;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native ML Kit reads printed expiry and manufacture image fixture',
    (tester) async {
      final file = await fixturePng(
        (canvas) {
          final painter = TextPainter(
            text: const TextSpan(
              text: 'MFG 15/10/2026\nEXP 20/11/2027',
              style: TextStyle(
                color: Colors.black,
                fontSize: 64,
                fontFamily: 'sans-serif',
                height: 1.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 1100);
          painter.paint(canvas, const Offset(60, 70));
          painter.dispose();
        },
        1200,
        400,
      );
      addTearDown(file.delete);
      final text = await DateOcr().readPath(file.path);
      final dates = parseDateCandidates(text);
      expect(
        dates.any(
          (d) =>
              d.date == DateTime(2027, 11, 20) &&
              d.kind == PrintedDateKind.expiry,
        ),
        isTrue,
        reason: text,
      );
      expect(
        dates.any((d) => d.kind == PrintedDateKind.manufacture),
        isTrue,
        reason: text,
      );
    },
  );
  testWidgets('native mobile_scanner decodes real EAN-13 image fixture', (
    tester,
  ) async {
    // EAN-13 4006381333931, standard L/G/R patterns with quiet zones.
    const code = '4006381333931';
    const left = [
      '0001101',
      '0011001',
      '0010011',
      '0111101',
      '0100011',
      '0110001',
      '0101111',
      '0111011',
      '0110111',
      '0001011',
    ];
    const odd = [
      '0100111',
      '0110011',
      '0011011',
      '0100001',
      '0011101',
      '0111001',
      '0000101',
      '0010001',
      '0001001',
      '0010111',
    ];
    const right = [
      '1110010',
      '1100110',
      '1101100',
      '1000010',
      '1011100',
      '1001110',
      '1010000',
      '1000100',
      '1001000',
      '1110100',
    ];
    const parity = 'LGLLGG'; // leading 4
    var bits = '101';
    for (var i = 0; i < 6; i++) {
      final n = int.parse(code[i + 1]);
      bits += parity[i] == 'L' ? left[n] : odd[n];
    }
    bits += '01010';
    for (var i = 7; i < 13; i++) {
      bits += right[int.parse(code[i])];
    }
    bits += '101';
    final file = await fixturePng(
      (canvas) {
        for (var i = 0; i < bits.length; i++) {
          if (bits[i] == '1') {
            canvas.drawRect(
              Rect.fromLTWH(80 + i * 5.0, 30, 5, 260),
              Paint()..color = Colors.black,
            );
          }
        }
      },
      650,
      340,
    );
    addTearDown(file.delete);
    final scanner = MobileScannerController(autoStart: false);
    addTearDown(scanner.dispose);
    final result = await scanner.analyzeImage(
      file.path,
      formats: [BarcodeFormat.ean13],
    );
    expect(result?.barcodes.any((b) => b.rawValue == code), isTrue);
  });
  testWidgets('native OCR missing image is a recoverable failure', (
    tester,
  ) async {
    await expectLater(
      DateOcr().readPath('/missing/freshkeep-test.png'),
      throwsA(anything),
    );
  });
}
