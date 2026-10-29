import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/inventory_repository.dart';

void inventoryFailure(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error is InventoryConflict ? l.conflictError : l.operationError,
      ),
    ),
  );
}
