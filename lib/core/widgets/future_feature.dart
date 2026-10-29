import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'content_frame.dart';

class FutureFeature extends StatelessWidget {
  const FutureFeature({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.showAdd = false,
  });
  final String title, description;
  final IconData icon;
  final bool showAdd;
  @override
  Widget build(BuildContext context) => ContentFrame(
    children: [
      const SizedBox(height: 32),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Icon(
          icon,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      Text(description, style: Theme.of(context).textTheme.bodyLarge),
      if (showAdd) ...[
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).addFood),
        ),
      ],
    ],
  );
}
