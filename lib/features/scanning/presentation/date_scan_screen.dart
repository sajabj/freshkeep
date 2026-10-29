import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/presentation/food_labels.dart';
import '../data/date_ocr.dart';
import '../domain/date_candidates.dart';

class DateScanScreen extends ConsumerStatefulWidget {
  const DateScanScreen({super.key});
  @override
  ConsumerState<DateScanScreen> createState() => _DateScanScreenState();
}

class _DateScanScreenState extends ConsumerState<DateScanScreen> {
  bool _busy = false;
  String? _error;
  List<DateCandidate>? _dates;
  Future<void> _read(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
      _dates = null;
    });
    try {
      final text = await ref.read(dateOcrProvider).pickAndRead(source);
      if (mounted && text != null) {
        setState(() => _dates = parseDateCandidates(text));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).ocrFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(DateCandidate? candidate) async {
    final date = await showDatePicker(
      context: context,
      helpText: AppLocalizations.of(context).confirmPrintedDate,
      initialDate: candidate?.date ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
    );
    if (!mounted || date == null) return;
    // The date picker is the explicit confirmation/correction boundary.
    Navigator.of(context).pop(
      DateCandidate(
        date,
        candidate?.kind ?? PrintedDateKind.unknown,
        candidate?.evidence ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.readDate)),
        body: SafeArea(
          child: ContentFrame(
            children: [
              Text(l.ocrGuide, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const Key('ocr-camera'),
                    onPressed: _busy ? null : () => _read(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l.captureDate),
                  ),
                  OutlinedButton.icon(
                    key: const Key('ocr-gallery'),
                    onPressed: _busy ? null : () => _read(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l.galleryDate),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_busy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(l.readingDate),
              ],
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_dates != null && _dates!.isEmpty) Text(l.noDates),
              if (_dates != null && _dates!.isNotEmpty) ...[
                Text(
                  l.dateCandidates,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final date in _dates!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate(context, date.date),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(switch (date.kind) {
                              PrintedDateKind.manufacture => l.manufactureDate,
                              PrintedDateKind.unknown => l.unknownDateLabel,
                              _ => kindLabel(l, date.foodKind),
                            }),
                            Text(
                              date.evidence,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (date.ambiguous) Text(l.dateAmbiguous),
                            if (date.kind != PrintedDateKind.manufacture)
                              TextButton(
                                onPressed: _busy ? null : () => _confirm(date),
                                child: Text(l.confirmPrintedDate),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('ocr-manual'),
                onPressed: _busy ? null : () => _confirm(null),
                child: Text(l.manualDate),
              ),
              const SizedBox(height: 24),
              Text(
                l.ocrArabicLimit,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(l.ocrLocal, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
