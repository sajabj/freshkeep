import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/product_lookup.dart';

class SourceCredit extends StatelessWidget {
  const SourceCredit({
    super.key,
    required this.barcode,
    this.saved = false,
    this.sourceUrl,
  });
  final String barcode;
  final String? sourceUrl;
  final bool saved;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (saved) Text(l.offSourceSaved),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Open Food Facts'),
              content: const SingleChildScrollView(
                child: SelectableText(
                  'Database: ODbL 1.0\nhttps://opendatacommons.org/licenses/odbl/1-0/\n\nContents: DbCL 1.0\nhttps://opendatacommons.org/licenses/dbcl/1-0/\n\nImages: CC BY-SA 3.0\nhttps://creativecommons.org/licenses/by-sa/3.0/\n\nTerms:\nhttps://world.openfoodfacts.org/terms-of-use',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ),
              ],
            ),
          ),
          child: Text(l.offAttribution),
        ),
        SelectableText(
          sourceUrl ??
              'https://${ProductLookup.useProduction ? 'world.openfoodfacts.org' : 'world.openfoodfacts.net'}/product/$barcode',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (!ProductLookup.useProduction)
          Text(l.offDevelopment, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
