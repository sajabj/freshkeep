import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/time/clock.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shopping/domain/shopping_item.dart';
import '../../shopping/application/shopping_controller.dart';
import '../../scanning/data/product_lookup.dart';
import '../../scanning/domain/date_candidates.dart';
import '../../scanning/presentation/barcode_scan_screen.dart';
import '../../scanning/presentation/date_scan_screen.dart';
import '../../scanning/presentation/source_credit.dart';
import '../application/inventory_controller.dart';
import '../data/food_photo_store.dart';
import '../domain/food_item.dart';
import 'food_labels.dart';
import 'food_photo.dart';
import 'inventory_feedback.dart';

class FoodFormScreen extends ConsumerStatefulWidget {
  const FoodFormScreen({
    super.key,
    this.item,
    this.duplicate = false,
    this.shoppingItem,
  });
  final ShoppingItem? shoppingItem;
  final FoodItem? item;
  final bool duplicate;
  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  final _form = GlobalKey<FormState>();
  final _expiryField = GlobalKey<FormFieldState<DateTime>>();
  final _photos = FoodPhotoStore();
  final _staged = <String>{};
  late final TextEditingController _name,
      _quantity,
      _unit,
      _brand,
      _barcode,
      _price;
  late final String _id;
  late String _category;
  late StoragePlace _storage;
  late DateKind _kind;
  DateTime? _expiry, _purchase;
  String? _image, _source;
  bool _saving = false, _picking = false;
  bool get _new => widget.item == null || widget.duplicate;
  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _id = _new ? const Uuid().v4() : i!.id;
    _name = TextEditingController(text: i?.name ?? widget.shoppingItem?.name);
    _quantity = TextEditingController(
      text:
          i?.quantity.toString() ??
          widget.shoppingItem?.quantity.toString() ??
          '1',
    );
    _unit = TextEditingController(
      text: i?.unit ?? widget.shoppingItem?.unit ?? 'pcs',
    );
    _brand = TextEditingController(text: i?.brand);
    _barcode = TextEditingController(text: i?.barcode);
    _price = TextEditingController(text: i?.price?.toString() ?? '');
    _category = i?.categoryId ?? widget.shoppingItem?.categoryId ?? 'other';
    _storage = i?.storage ?? StoragePlace.fridge;
    _kind = i?.dateKind ?? DateKind.unknown;
    _image = i?.imagePath;
    _source = i?.sourceUrl;
    _expiry = widget.duplicate ? null : i?.expiryDate;
    _purchase = widget.duplicate ? null : i?.purchaseDate;
  }

  @override
  void dispose() {
    for (final c in [_name, _quantity, _unit, _brand, _barcode, _price]) {
      c.dispose();
    }
    unawaited(_photos.discardStaged(_staged));
    super.dispose();
  }

  Future<DateTime?> _date(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? calendarDate(ref.read(clockProvider)()),
    firstDate: DateTime(1900),
    lastDate: DateTime(2200, 12, 31),
  );
  Future<void> _photo() async {
    setState(() => _picking = true);
    try {
      final path = await _photos.pick();
      if (path != null) {
        if (!mounted) {
          await _photos.discardStaged([path]);
          return;
        }
        _staged.add(path);
        setState(() => _image = path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).photoError)),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = ref.read(clockProvider)();
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final item = FoodItem(
      id: _id,
      name: _name.text.trim(),
      categoryId: _category,
      quantity: parseFoodNumber(_quantity.text)!,
      unit: _unit.text.trim(),
      expiryDate: _expiry!,
      createdAt: _new ? now : widget.item!.createdAt,
      updatedAt: now,
      barcode: optional(_barcode),
      brand: optional(_brand),
      purchaseDate: _purchase,
      dateKind: _kind,
      storage: _storage,
      price: optional(_price) == null ? null : parseFoodNumber(_price.text),
      imagePath: _image,
      sourceUrl: _source,
      revision: _new ? 0 : widget.item!.revision,
    );
    try {
      if (widget.shoppingItem != null) {
        await ref
            .read(shoppingProvider.notifier)
            .convert(widget.shoppingItem!, item);
      } else {
        await ref.read(inventoryProvider.notifier).save(item, isNew: _new);
      }
      _staged.remove(_image);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) inventoryFailure(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scanBarcode() async {
    final product = await Navigator.of(context).push<ProductData>(
      MaterialPageRoute(
        builder: (_) => BarcodeScanScreen(
          cameraEnabled: ref.read(scannerCameraEnabledProvider),
        ),
      ),
    );
    if (!mounted || product == null) return;
    setState(() {
      _barcode.text = product.barcode;
      if (product.name.isNotEmpty) _name.text = product.name;
      if (product.brand.isNotEmpty) _brand.text = product.brand;
      final measured = product.measuredQuantity;
      if (measured != null) {
        _quantity.text = measured.$1.toString();
        _unit.text = measured.$2;
      }
      if (product.name.isNotEmpty ||
          product.brand.isNotEmpty ||
          product.quantity.isNotEmpty ||
          product.imageUrl != null) {
        _source =
            'https://${ProductLookup.useProduction ? 'world.openfoodfacts.org' : 'world.openfoodfacts.net'}/product/${product.barcode}';
      }
      if (product.imageUrl != null) _image = product.imageUrl;
    });
  }

  Future<void> _scanDate() async {
    final result = await Navigator.of(context).push<DateCandidate>(
      MaterialPageRoute(builder: (_) => const DateScanScreen()),
    );
    if (!mounted || result == null) return;
    setState(() {
      _expiry = result.date;
      _kind = result.foodKind;
    });
    _expiryField.currentState?.didChange(result.date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = _saving || _picking;
    String? required(String? v) =>
        v == null || v.trim().isEmpty ? l.requiredField : null;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text(_new ? l.addFood : l.editFood)),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: FilledButton(
              key: const Key('save-food'),
              onPressed: busy ? null : _save,
              child: Text(_saving ? l.saving : l.saveFood),
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ContentFrame(
              children: [
                if (widget.shoppingItem != null) ...[
                  Text(l.shoppingConvertNote),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('scan-product'),
                      onPressed: busy ? null : _scanBarcode,
                      icon: const Icon(Icons.barcode_reader),
                      label: Text(l.scanBarcode),
                    ),
                    OutlinedButton.icon(
                      key: const Key('scan-date'),
                      onPressed: busy ? null : _scanDate,
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(l.readDate),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (widget.duplicate) ...[
                  Text(l.newBatchNote),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  key: const Key('food-name'),
                  controller: _name,
                  enabled: !busy,
                  decoration: InputDecoration(labelText: l.foodName),
                  maxLength: 100,
                  validator: required,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                _Fields(
                  children: [
                    TextFormField(
                      key: const Key('food-quantity'),
                      controller: _quantity,
                      enabled: !busy,
                      decoration: InputDecoration(labelText: l.quantityField),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final n = parseFoodNumber(v ?? '');
                        return n == null || !n.isFinite || n <= 0
                            ? l.quantityError
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: _unit,
                      enabled: !busy,
                      decoration: InputDecoration(labelText: l.unitField),
                      maxLength: 24,
                      validator: required,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.categoryField),
                  items: [
                    for (final id in categoryIds)
                      DropdownMenuItem(
                        value: id,
                        child: Text(categoryLabel(l, id)),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<StoragePlace>(
                  initialValue: _storage,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.storageField),
                  items: [
                    for (final v in StoragePlace.values)
                      DropdownMenuItem(
                        value: v,
                        child: Text(storageLabel(l, v)),
                      ),
                  ],
                  onChanged: busy ? null : (v) => setState(() => _storage = v!),
                ),
                const SizedBox(height: 24),
                FormField<DateTime>(
                  key: _expiryField,
                  initialValue: _expiry,
                  validator: (v) => v == null ? l.dateRequired : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('choose-expiry'),
                        onPressed: busy
                            ? null
                            : () async {
                                final date = await _date(_expiry);
                                if (mounted && date != null) {
                                  setState(() => _expiry = date);
                                  field.didChange(date);
                                }
                              },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '${l.expiryField}: ${_expiry == null ? l.chooseDate : formattedDate(context, _expiry!)}',
                          ),
                        ),
                      ),
                      if (field.errorText != null)
                        Text(
                          field.errorText!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.dateHelp, style: theme.textTheme.bodySmall),
                const SizedBox(height: 20),
                DropdownButtonFormField<DateKind>(
                  key: ValueKey(_kind),
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.dateKindField),
                  items: [
                    for (final v in DateKind.values)
                      DropdownMenuItem(value: v, child: Text(kindLabel(l, v))),
                  ],
                  onChanged: busy ? null : (v) => setState(() => _kind = v!),
                ),
                if (_kind == DateKind.bestBefore) ...[
                  const SizedBox(height: 12),
                  Text(l.bestBeforeNote),
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final date = await _date(_purchase);
                          if (mounted && date != null) {
                            setState(() => _purchase = date);
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${l.purchaseField}: ${_purchase == null ? l.chooseDate : formattedDate(context, _purchase!)}',
                    ),
                  ),
                ),
                if (_purchase != null)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _purchase = null),
                    child: Text(l.clearDate),
                  ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _brand,
                  enabled: !busy,
                  maxLength: 100,
                  decoration: InputDecoration(labelText: l.brandField),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _barcode,
                  enabled: !busy,
                  maxLength: 128,
                  decoration: InputDecoration(labelText: l.barcodeField),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  enabled: !busy,
                  decoration: InputDecoration(
                    labelText: l.priceField,
                    helperText: l.priceHelp,
                    helperMaxLines: 3,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = parseFoodNumber(v);
                    return n == null || !n.isFinite || n < 0
                        ? l.priceError
                        : null;
                  },
                ),
                const SizedBox(height: 28),
                Text(l.photo, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FoodPhoto(path: _image, size: 80),
                    TextButton.icon(
                      onPressed: busy ? null : _photo,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l.choosePhoto),
                    ),
                    if (_image != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() => _image = null),
                        child: Text(l.removePhoto),
                      ),
                  ],
                ),
                if (_source != null) ...[
                  const SizedBox(height: 24),
                  SourceCredit(
                    sourceUrl: _source,
                    barcode: Uri.parse(_source!).pathSegments.last,
                    saved: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 440 &&
              MediaQuery.textScalerOf(context).scale(16) < 22
          ? 2
          : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children)
            SizedBox(
              width: (constraints.maxWidth - 16 * (columns - 1)) / columns,
              child: child,
            ),
        ],
      );
    },
  );
}
