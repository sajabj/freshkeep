import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/presentation/food_photo.dart';
import '../data/product_lookup.dart';
import 'source_credit.dart';

final scannerCameraEnabledProvider = Provider<bool>((ref) => true);

/// Returns a reviewed prefill; never writes inventory.
class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key, this.cameraEnabled = true});
  final bool cameraEnabled;
  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _text = TextEditingController();
  late final AnimationController _motion;
  MobileScannerController? _camera;
  bool _busy = false, _locked = false, _manual = false;
  String? _error, _code;
  ProductResult? _result;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _manual = !widget.cameraEnabled;
    if (widget.cameraEnabled) {
      _camera = MobileScannerController(
        formats: const [
          BarcodeFormat.ean8,
          BarcodeFormat.ean13,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.itf14,
          BarcodeFormat.code128,
        ],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !widget.cameraEnabled) {
      _motion.stop();
      _motion.value = .5;
    } else if (!_motion.isAnimating) {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camera == null || !_camera!.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed && !_locked && !_manual) {
      unawaited(_startCamera());
    } else {
      unawaited(_stopCamera());
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _camera?.stop();
    } catch (_) {
      /* Camera may already be stopped. */
    }
  }

  Future<void> _startCamera() async {
    try {
      await _camera?.start();
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).cameraProblem);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    _text.dispose();
    if (_camera != null) unawaited(_camera!.dispose());
    super.dispose();
  }

  Future<void> _lookup(String raw) async {
    if (_busy || _locked) return;
    final code = productBarcode(raw);
    if (code == null) {
      setState(() => _error = AppLocalizations.of(context).barcodeInvalid);
      return;
    }
    // Lock synchronously before any await: a camera frame cannot submit twice.
    setState(() {
      _locked = true;
      _busy = true;
      _code = code;
      _error = null;
      _result = null;
    });
    await _stopCamera();
    try {
      final service = await ref.read(productLookupProvider.future);
      if (!mounted) return;
      final result = await service.lookup(
        code,
        Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      if (result.product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).productMissing)),
        );
        Navigator.of(context).pop(ProductData(barcode: code));
      } else {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(
          () => _error = switch (e) {
            LookupException(issue: LookupIssue.offline) => l.lookupOffline,
            LookupException(issue: LookupIssue.rateLimited) => l.lookupLimited,
            _ => l.lookupUnavailable,
          },
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = _result?.product;
    return Scaffold(
      appBar: AppBar(title: Text(p == null ? l.scanBarcode : l.reviewProduct)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            if (p != null) ...[
              Center(
                child: FoodPhoto(
                  path: p.imageUrl,
                  name: p.name,
                  size: 176,
                  borderRadius: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                p.name.isEmpty ? l.noProductName : p.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (p.brand.isNotEmpty) Text(p.brand),
              if (p.quantity.isNotEmpty)
                Text('${l.quantityField}: ${p.quantity}'),
              SelectableText(p.barcode),
              const SizedBox(height: 16),
              Text(l.productReviewNote),
              if (_result!.cached)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _result!.stale ? l.staleProduct : l.cachedProduct,
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('accept-product'),
                onPressed: () => Navigator.of(context).pop(p),
                child: Text(l.continueWithProduct),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(ProductData(barcode: p.barcode)),
                child: Text(l.continueManually),
              ),
              const SizedBox(height: 24),
              SourceCredit(barcode: p.barcode),
            ] else ...[
              Text(
                _manual ? l.barcodeManual : l.scanHint,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (!_manual && widget.cameraEnabled) ...[
                SizedBox(
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final window = Rect.fromCenter(
                          center: Offset(constraints.maxWidth / 2, 130),
                          width: math.min(280, constraints.maxWidth - 40),
                          height: 150,
                        );
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _camera,
                              scanWindow: window,
                              onDetect: (capture) {
                                for (final b in capture.barcodes) {
                                  if (b.rawValue != null &&
                                      productBarcode(b.rawValue!) != null) {
                                    final code = b.format == BarcodeFormat.upcE
                                        ? expandUpce(b.rawValue!)
                                        : b.rawValue;
                                    if (code != null) unawaited(_lookup(code));
                                    break;
                                  }
                                }
                              },
                              overlayBuilder: (context, _) => IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _motion,
                                  builder: (_, _) => CustomPaint(
                                    size: constraints.biggest,
                                    painter: _FramePainter(
                                      window,
                                      _motion.value,
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              errorBuilder: (context, error) => ColoredBox(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(child: Text(l.cameraProblem)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    tooltip: l.flashlight,
                    onPressed: _busy || _locked
                        ? null
                        : () async {
                            try {
                              await _camera?.toggleTorch();
                            } catch (_) {
                              if (mounted) {
                                setState(() => _error = l.cameraProblem);
                              }
                            }
                          },
                    icon: const Icon(Icons.flashlight_on_outlined),
                  ),
                ),
              ],
              if (_busy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(l.lookingUp),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (!_busy && _code != null) ...[
                FilledButton(
                  onPressed: () {
                    _locked = false;
                    unawaited(_lookup(_code!));
                  },
                  child: Text(l.retry),
                ),
                TextButton(
                  key: const Key('barcode-fallback'),
                  onPressed: () =>
                      Navigator.of(context).pop(ProductData(barcode: _code!)),
                  child: Text(l.continueManually),
                ),
              ],
              if (!_busy && !_locked) ...[
                if (!_manual)
                  TextButton(
                    onPressed: () {
                      setState(() => _manual = true);
                      unawaited(_stopCamera());
                    },
                    child: Text(l.barcodeManual),
                  ),
                if (_manual || !widget.cameraEnabled) ...[
                  TextField(
                    key: const Key('scan-barcode-input'),
                    controller: _text,
                    keyboardType: TextInputType.number,
                    maxLength: 14,
                    decoration: InputDecoration(labelText: l.scanBarcode),
                  ),
                  FilledButton(
                    key: const Key('lookup-barcode'),
                    onPressed: () => _lookup(_text.text),
                    child: Text(l.lookupProduct),
                  ),
                ],
                if (widget.cameraEnabled)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _manual = false;
                        _error = null;
                      });
                      unawaited(_startCamera());
                    },
                    child: Text(l.retryCamera),
                  ),
              ],
              const SizedBox(height: 24),
              Text(l.scanPrivacy, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.rect, this.progress, this.color);
  final Rect rect;
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    canvas.drawPath(
      shade,
      Paint()..color = Colors.black.withValues(alpha: .45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final y = rect.top + 12 + (rect.height - 24) * progress;
    canvas.drawLine(
      Offset(rect.left + 12, y),
      Offset(rect.right - 12, y),
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.progress != progress || old.rect != rect || old.color != color;
}
