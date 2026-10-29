import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class InventoryLoading extends StatelessWidget {
  const InventoryLoading({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 90,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
        ],
      ),
    ),
  );
}
