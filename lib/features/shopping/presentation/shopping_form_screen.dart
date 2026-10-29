import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/time/clock.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/domain/food_item.dart';
import '../../inventory/presentation/food_labels.dart';
import '../../inventory/presentation/inventory_feedback.dart';
import '../application/shopping_controller.dart';
import '../domain/shopping_item.dart';

class ShoppingFormScreen extends ConsumerStatefulWidget {
  const ShoppingFormScreen({
    super.key,
    this.item,
    this.name,
    this.quantity = 1,
    this.unit = 'pcs',
    this.category = 'other',
  });
  final ShoppingItem? item;
  final String? name;
  final double quantity;
  final String unit, category;
  @override
  ConsumerState<ShoppingFormScreen> createState() => _ShoppingFormState();
}

class _ShoppingFormState extends ConsumerState<ShoppingFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _quantity, _unit;
  late String _category;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? widget.name);
    _quantity = TextEditingController(
      text: (widget.item?.quantity ?? widget.quantity).toString(),
    );
    _unit = TextEditingController(text: widget.item?.unit ?? widget.unit);
    _category = widget.item?.categoryId ?? widget.category;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final item = ShoppingItem(
        id: widget.item?.id ?? const Uuid().v4(),
        name: _name.text.trim(),
        quantity: parseFoodNumber(_quantity.text)!,
        unit: _unit.text.trim(),
        categoryId: _category,
        createdAt: widget.item?.createdAt ?? ref.read(clockProvider)(),
        purchased: widget.item?.purchased ?? false,
        revision: widget.item?.revision ?? 0,
      );
      await ref
          .read(shoppingProvider.notifier)
          .save(item, isNew: widget.item == null);
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) inventoryFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.item == null ? l.addShopping : l.editShopping),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              key: const Key('save-shopping'),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? l.saving : l.saveShopping),
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ContentFrame(
              children: [
                TextFormField(
                  key: const Key('shopping-name'),
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 100,
                  decoration: InputDecoration(labelText: l.foodName),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l.requiredField : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('shopping-quantity'),
                  controller: _quantity,
                  enabled: !_busy,
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
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('shopping-unit'),
                  controller: _unit,
                  enabled: !_busy,
                  maxLength: 24,
                  decoration: InputDecoration(labelText: l.unitField),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l.requiredField : null,
                ),
                const SizedBox(height: 20),
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
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _category = v!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
