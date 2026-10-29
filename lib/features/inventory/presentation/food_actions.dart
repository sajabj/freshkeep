import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/inventory_controller.dart';
import '../domain/food_item.dart';
import 'food_form_screen.dart';

/// Returns true when the batch was deleted. Only the caller handles errors and
/// busy state, so the same behavior serves the list and detail screen.
Future<bool> performFoodAction(
  BuildContext context,
  WidgetRef ref,
  FoodItem item,
  String action,
) async {
  final l = AppLocalizations.of(context);
  if (action == 'edit' || action == 'duplicate') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FoodFormScreen(item: item, duplicate: action == 'duplicate'),
      ),
    );
    return false;
  }
  String? reason;
  final title = switch (action) {
    'delete' => l.deleteFood,
    'discarded' => l.markDiscarded,
    'used' => l.markUsed,
    _ => l.restoreFood,
  };
  final message = switch (action) {
    'delete' => l.deleteConfirm,
    'discarded' => l.discardNote,
    'used' => l.usedConfirm,
    _ => l.restoreConfirm,
  };
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (action == 'discarded') ...[
              const SizedBox(height: 16),
              TextField(
                key: const Key('disposal-reason'),
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.disposalReason),
                onChanged: (v) => reason = v.trim(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('confirm-food-action'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(title),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final controller = ref.read(inventoryProvider.notifier);
  if (action == 'delete') {
    await controller.delete(item);
    return true;
  }
  await controller.changeStatus(
    item,
    action == 'used'
        ? FoodStatus.used
        : action == 'discarded'
        ? FoodStatus.discarded
        : FoodStatus.available,
    reason: reason == '' ? null : reason,
  );
  return false;
}
