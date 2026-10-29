import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/food_item.dart';
import 'food_labels.dart';
import 'food_photo.dart';

class FoodTile extends StatelessWidget {
  const FoodTile({
    super.key,
    required this.item,
    required this.today,
    required this.onTap,
    this.onAction,
    this.compact = false,
    this.busy = false,
  });
  final FoodItem item;
  final DateTime today;
  final VoidCallback onTap;
  final ValueChanged<String>? onAction;
  final bool compact, busy;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final days = daysUntil(item.expiryDate, today);
    final quantity = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    ).format(item.quantity);
    final signal = days < 0
        ? theme.colorScheme.error
        : days <= 7
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FoodPhoto(
                    path: item.imagePath,
                    name: item.name,
                    categoryId: item.categoryId,
                    size: compact ? 58 : 72,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: theme.textTheme.titleMedium),
                        Text(
                          '$quantity ${item.unit} · ${storageLabel(l, item.storage)}',
                        ),
                        if (!compact)
                          Text(
                            categoryLabel(l, item.categoryId),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (onAction != null)
                    PopupMenuButton<String>(
                      tooltip: l.moreActions,
                      enabled: !busy,
                      onSelected: onAction,
                      itemBuilder: (_) => [
                        if (item.status == FoodStatus.available) ...[
                          PopupMenuItem(value: 'edit', child: Text(l.editFood)),
                          PopupMenuItem(value: 'used', child: Text(l.markUsed)),
                          PopupMenuItem(
                            value: 'discarded',
                            child: Text(l.markDiscarded),
                          ),
                        ] else
                          PopupMenuItem(
                            value: 'restore',
                            child: Text(l.restoreFood),
                          ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text(l.duplicateFood),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l.deleteFood),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${kindLabel(l, item.dateKind)} · ${formattedDate(context, item.expiryDate)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                item.status == FoodStatus.available
                    ? remainingLabel(l, item, today)
                    : statusLabel(l, item.status),
                style: TextStyle(
                  color: item.status == FoodStatus.available
                      ? signal
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.disposalReason != null &&
                  item.disposalReason!.isNotEmpty)
                Text(item.disposalReason!),
            ],
          ),
        ),
      ),
    );
  }
}
