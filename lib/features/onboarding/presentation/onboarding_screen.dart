import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/brand_mark.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/preferences_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.preview = false});
  final bool preview;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;
  bool _saving = false;
  Future<void> _persist(Future<void> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final titles = [
      l.onboardTitle1,
      l.onboardTitle2,
      l.onboardTitle3,
      l.onboardTitle4,
    ];
    final bodies = [
      l.onboardBody1,
      l.onboardBody2,
      l.onboardBody3,
      l.onboardBody4,
    ];
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 540,
                  minHeight: bounds.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BrandMark(),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'FreshKeep',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.preview)
                            IconButton(
                              tooltip: l.close,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            )
                          else
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _page = 4),
                              child: Text(l.skip),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_page < 4) ...[
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: bounds.maxHeight < 650 ? 220 : 310,
                            ),
                            child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              child: ClipRRect(
                                key: ValueKey(_page),
                                borderRadius: BorderRadius.circular(24),
                                child: AspectRatio(
                                  aspectRatio: 3 / 2,
                                  child: Image.asset(
                                    const [
                                      'assets/images/foods/generic.jpg',
                                      'assets/images/foods/apple.jpg',
                                      'assets/images/recipes/tomato-pasta.jpg',
                                      'assets/images/recipes/chickpea-salad.jpg',
                                    ][_page],
                                    fit: BoxFit.cover,
                                    cacheWidth: 720,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          titles[_page],
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(bodies[_page], style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 24),
                        Semantics(
                          label: l.introProgress(_page + 1, 4),
                          child: ExcludeSemantics(
                            child: Row(
                              children: List.generate(
                                4,
                                (index) => AnimatedContainer(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 180),
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 6,
                                  ),
                                  width: index == _page ? 30 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index == _page
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('onboarding-next'),
                          onPressed: () => setState(() => _page++),
                          child: Text(l.next),
                        ),
                        if (_page > 0)
                          TextButton(
                            onPressed: () => setState(() => _page--),
                            child: Text(l.back),
                          ),
                      ] else ...[
                        const SizedBox(height: 40),
                        const Center(child: BrandMark(size: 80)),
                        const SizedBox(height: 32),
                        Text(
                          l.chooseLanguage,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(l.languageIntro, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 24),
                        for (final code in ['ar', 'en'])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: ListTile(
                                key: Key('language-$code'),
                                minVerticalPadding: 18,
                                title: Text(
                                  code == 'ar' ? 'العربية' : 'English',
                                ),
                                trailing: Icon(
                                  language == code
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: theme.colorScheme.primary,
                                ),
                                selected: language == code,
                                onTap: _saving
                                    ? null
                                    : () => _persist(
                                        () => ref
                                            .read(preferencesProvider.notifier)
                                            .setLanguage(code),
                                      ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('finish-onboarding'),
                          onPressed: _saving
                              ? null
                              : () {
                                  if (widget.preview) {
                                    Navigator.pop(context);
                                  } else {
                                    _persist(
                                      () => ref
                                          .read(preferencesProvider.notifier)
                                          .finishOnboarding(language),
                                    );
                                  }
                                },
                          child: Text(
                            _saving
                                ? l.loading
                                : widget.preview
                                ? l.close
                                : l.getStarted,
                          ),
                        ),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _page = 3),
                          child: Text(l.back),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        l.localFirst,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
