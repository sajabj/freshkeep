import '../../scanning/presentation/source_credit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/inventory_controller.dart';
import '../domain/food_item.dart';
import 'food_actions.dart';
import 'food_labels.dart';
import 'food_photo.dart';
import 'inventory_feedback.dart';
import '../../storage_guide/presentation/storage_guide_screen.dart';
import '../../consumption/presentation/use_product_dialog.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  const FoodDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  bool _busy = false;
  Future<void> _action(FoodItem item, String action) async {
    setState(() => _busy = true);
    try {
      final deleted = await performFoodAction(context, ref, item, action);
      if (deleted && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) inventoryFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(inventoryProvider);
    final item = items.asData?.value
        .where((i) => i.id == widget.id)
        .firstOrNull;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(item?.name ?? l.inventory)),
      body: SafeArea(
        child: item == null
            ? Center(
                child: Text(items.hasError ? l.inventoryError : l.noMatches),
              )
            : ContentFrame(
                children: [
                  if (item.imagePath != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FoodPhoto(
                        path: item.imagePath,
                        name: item.name,
                        categoryId: item.categoryId,
                        size: 180,
                        borderRadius: 24,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(item.name, style: theme.textTheme.headlineMedium),
                  if (item.sourceUrl != null) ...[
                    const SizedBox(height: 16),
                    SourceCredit(
                      sourceUrl: item.sourceUrl,
                      barcode: Uri.parse(item.sourceUrl!).pathSegments.last,
                      saved: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(statusLabel(l, item.status)),
                  const SizedBox(height: 24),
                  for (final entry in [
                    (
                      l.quantityField,
                      '${NumberFormat.decimalPattern(l.localeName).format(item.quantity)} ${item.unit}',
                    ),
                    (l.categoryField, categoryLabel(l, item.categoryId)),
                    (l.storageField, storageLabel(l, item.storage)),
                    (l.dateKindField, kindLabel(l, item.dateKind)),
                    (l.expiryField, formattedDate(context, item.expiryDate)),
                    if (item.purchaseDate != null)
                      (
                        l.purchaseField,
                        formattedDate(context, item.purchaseDate!),
                      ),
                    if (item.brand != null) (l.brandField, item.brand!),
                    if (item.barcode != null) (l.barcodeField, item.barcode!),
                    if (item.price != null)
                      (
                        l.priceField,
                        NumberFormat.decimalPattern(l.localeName)
                            .format(item.price),
                      ),
                    if (item.disposalReason != null)
                      (l.disposalReason, item.disposalReason!),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.$1, style: theme.textTheme.bodySmall),
                          Text(entry.$2, style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  Text(
                    item.dateKind == DateKind.bestBefore
                        ? l.bestBeforeNote
                        : l.dateHelp,
                  ),
                  const SizedBox(height: 16),
                  FoodStorageCard(foodName: item.name),
                  const SizedBox(height: 24),
                  if (item.status == FoodStatus.available) ...[
                    FilledButton.icon(
                      key: const Key('use-product'),
                      onPressed: _busy
                          ? null
                          : () => showUseProductDialog(context, ref, item),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: Text(
                        l.localeName == 'ar'
                            ? 'استخدمت من المنتج'
                            : 'Use Product',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _busy ? null : () => _action(item, 'used'),
                      child: Text(l.markUsed),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _action(item, 'discarded'),
                      child: Text(l.markDiscarded),
                    ),
                    TextButton(
                      key: const Key('edit-food'),
                      onPressed: _busy ? null : () => _action(item, 'edit'),
                      child: Text(l.editFood),
                    ),
                  ] else
                    FilledButton(
                      onPressed: _busy ? null : () => _action(item, 'restore'),
                      child: Text(l.restoreFood),
                    ),
                  TextButton(
                    key: const Key('duplicate-food'),
                    onPressed: _busy ? null : () => _action(item, 'duplicate'),
                    child: Text(l.duplicateFood),
                  ),
                  TextButton(
                    key: const Key('delete-food'),
                    onPressed: _busy ? null : () => _action(item, 'delete'),
                    child: Text(l.deleteFood),
                  ),
                ],
              ),
      ),
    );
  }
}
