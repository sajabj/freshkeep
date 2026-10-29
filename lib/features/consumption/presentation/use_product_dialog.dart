import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../inventory/domain/food_item.dart';
import '../../inventory/presentation/inventory_feedback.dart';
import '../../inventory/presentation/food_labels.dart';
import '../application/consumption_controller.dart';
import '../domain/consumption.dart';

Future<void> showUseProductDialog(
  BuildContext context,
  WidgetRef ref,
  FoodItem item,
) async {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  final controller = TextEditingController();
  var busy = false;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final used = parseFoodNumber(controller.text);
        final valid = used != null && used > 0 && used <= item.quantity;
        final remaining = valid ? item.quantity - used : item.quantity;
        final number = NumberFormat.decimalPattern(ar ? 'ar' : 'en');
        return AlertDialog(
          title: Text(ar ? 'استخدمت من المنتج' : 'Use Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ar
                      ? 'المتوفر: ${number.format(item.quantity)} ${item.unit}'
                      : 'Available: ${number.format(item.quantity)} ${item.unit}',
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('consumption-amount'),
                  controller: controller,
                  autofocus: true,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: ar ? 'الكمية المستخدمة' : 'Amount used',
                    suffixText: item.unit,
                    errorText: controller.text.isNotEmpty && !valid
                        ? (ar
                              ? 'أدخل كمية أكبر من صفر ولا تتجاوز المتوفر.'
                              : 'Enter more than zero and no more than available.')
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  ar
                      ? 'المتبقي بعد التأكيد: ${number.format(remaining)} ${item.unit}'
                      : 'Remaining after confirmation: ${number.format(remaining)} ${item.unit}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-consumption'),
              onPressed: !valid || busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final operation = await ref
                            .read(consumptionControllerProvider)
                            .apply(
                              ConsumptionRequest(
                                id: const Uuid().v4(),
                                kind: ConsumptionKind.manual,
                                occurredAt: DateTime.now(),
                                allocations: [
                                  ConsumptionAllocation(
                                    foodId: item.id,
                                    amount: used,
                                  ),
                                ],
                              ),
                            );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ar ? 'تم خصم الكمية.' : 'Amount deducted.',
                            ),
                            action: SnackBarAction(
                              label: ar ? 'تراجع' : 'Undo',
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(consumptionControllerProvider)
                                      .undo(operation.id);
                                } catch (error) {
                                  if (context.mounted) {
                                    inventoryFailure(context, error);
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setState(() => busy = false);
                          inventoryFailure(dialogContext, error);
                        }
                      }
                    },
              child: Text(ar ? 'تأكيد الخصم' : 'Confirm deduction'),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
}
