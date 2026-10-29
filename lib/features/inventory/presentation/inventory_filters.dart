import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/food_item.dart';
import '../domain/inventory_query.dart';
import 'food_labels.dart';

Future<InventoryQuery?> showInventoryFilters(
  BuildContext context,
  InventoryQuery current,
) {
  final l = AppLocalizations.of(context);
  var category = current.category;
  var storage = current.storage;
  var sort = current.sort;
  return showDialog<InventoryQuery>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, update) => AlertDialog(
        title: Text(l.filters),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category ?? '',
                isExpanded: true,
                decoration: InputDecoration(labelText: l.categoryField),
                items: [
                  DropdownMenuItem(value: '', child: Text(l.allCategories)),
                  for (final id in categoryIds)
                    DropdownMenuItem(
                      value: id,
                      child: Text(categoryLabel(l, id)),
                    ),
                ],
                onChanged: (v) => update(() => category = v == '' ? null : v),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: storage?.name ?? '',
                isExpanded: true,
                decoration: InputDecoration(labelText: l.storageField),
                items: [
                  DropdownMenuItem(value: '', child: Text(l.allStorage)),
                  for (final place in StoragePlace.values)
                    DropdownMenuItem(
                      value: place.name,
                      child: Text(storageLabel(l, place)),
                    ),
                ],
                onChanged: (v) => update(
                  () =>
                      storage = v == '' ? null : StoragePlace.values.byName(v!),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<InventorySort>(
                initialValue: sort,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.filters),
                items: [
                  DropdownMenuItem(
                    value: InventorySort.expiry,
                    child: Text(l.sortExpiry),
                  ),
                  DropdownMenuItem(
                    value: InventorySort.name,
                    child: Text(l.sortName),
                  ),
                  DropdownMenuItem(
                    value: InventorySort.added,
                    child: Text(l.sortAdded),
                  ),
                ],
                onChanged: (v) => update(() => sort = v!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              InventoryQuery(
                search: current.search,
                status: current.status,
                category: category,
                storage: storage,
                sort: sort,
              ),
            ),
            child: Text(l.done),
          ),
        ],
      ),
    ),
  );
}
