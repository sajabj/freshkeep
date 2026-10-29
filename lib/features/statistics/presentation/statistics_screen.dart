import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/time/clock.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inventory/application/inventory_controller.dart';
import '../application/statistics_provider.dart';
import '../domain/statistics.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  TrendPeriod period = TrendPeriod.weekly;
  @override
  Widget build(BuildContext context) {
    ref.watch(todayProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(locale);
    final money = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    final date = DateFormat.yMMMd(locale);
    final now = ref.watch(clockProvider)();
    return ref
        .watch(statisticsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton.icon(
              onPressed: () => ref.invalidate(statisticsProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l.retryAction),
            ),
          ),
          data: (stats) {
            final totals = stats.totals(now);
            final buckets = stats.trend(now, period);
            final usedColor = theme.brightness == Brightness.dark
                ? const Color(0xFF90D7B0)
                : const Color(0xFF237A57);
            final wasteColor = theme.brightness == Brightness.dark
                ? const Color(0xFFFFB4AA)
                : const Color(0xFFA6372E);
            final maxCount = buckets.fold<int>(
              0,
              (n, b) =>
                  math.max(n, math.max(b.totals.used, b.totals.discarded)),
            );
            Widget metric(String title, String value, IconData icon) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon),
                    const SizedBox(height: 12),
                    Text(value, style: theme.textTheme.headlineMedium),
                    Text(title, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            );
            return ContentFrame(
              children: [
                Text(l.statsIntro, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(l.statsAll),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final children = [
                      metric(
                        l.statsUsed,
                        numbers.format(totals.used),
                        Icons.check_circle_outline,
                      ),
                      metric(
                        l.statsDiscarded,
                        numbers.format(totals.discarded),
                        Icons.delete_outline,
                      ),
                    ];
                    if (c.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(16) > 24) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          children[0],
                          const SizedBox(height: 12),
                          children[1],
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: children[0]),
                          const SizedBox(width: 12),
                          Expanded(child: children[1]),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(l.statsMethod),
                if (stats.invalidEvents > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l.statsInvalid),
                  ),
                const SizedBox(height: 28),
                if (totals.used + totals.discarded == 0) ...[
                  const Icon(Icons.insights_outlined, size: 56),
                  const SizedBox(height: 12),
                  Text(l.statsEmpty, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(l.statsEmptyBody),
                ] else ...[
                  Text(l.statsTrend, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final p in TrendPeriod.values)
                        ChoiceChip(
                          key: Key('trend-${p.name}'),
                          label: Text(
                            p == TrendPeriod.weekly
                                ? l.statsWeek
                                : l.statsMonth,
                          ),
                          selected: period == p,
                          onSelected: (_) => setState(() => period = p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      for (final entry in [
                        (l.statsUsed, usedColor, Icons.circle),
                        (l.statsDiscarded, wasteColor, Icons.square),
                      ])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: Icon(entry.$3, color: entry.$2, size: 12),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                entry.$1,
                                style: TextStyle(
                                  color: entry.$2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (maxCount == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(l.statsRangeEmpty),
                    )
                  else ...[
                    const SizedBox(height: 24),
                    // The complete, labeled data below is also the screen-reader
                    // alternative. Chronological chart axes run left to right in RTL.
                    ExcludeSemantics(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: SizedBox(
                          height: 240,
                          child: BarChart(
                            BarChartData(
                              minY: 0,
                              maxY: math.max(1, maxCount).toDouble() + 1,
                              alignment: BarChartAlignment.spaceAround,
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                drawVerticalLine: false,
                                horizontalInterval: math
                                    .max(1, (maxCount / 4).ceil())
                                    .toDouble(),
                              ),
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: math
                                        .max(1, (maxCount / 4).ceil())
                                        .toDouble(),
                                    getTitlesWidget: (v, meta) => Text(
                                      v == v.roundToDouble()
                                          ? numbers.format(v)
                                          : '',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (v, meta) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        numbers.format(v.toInt() + 1),
                                        style: theme.textTheme.labelMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              barGroups: [
                                for (var i = 0; i < buckets.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barsSpace: 3,
                                    barRods: [
                                      BarChartRodData(
                                        toY: buckets[i].totals.used.toDouble(),
                                        color: usedColor,
                                        width: 10,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      BarChartRodData(
                                        toY: buckets[i].totals.discarded
                                            .toDouble(),
                                        color: wasteColor,
                                        width: 10,
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 250),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ExpansionTile(
                    key: const Key('chart-data'),
                    initiallyExpanded: true,
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.statsData),
                    children: [
                      for (var i = 0; i < buckets.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              '${numbers.format(i + 1)} · ${date.format(buckets[i].start)} – ${date.format(DateTime(buckets[i].end.year, buckets[i].end.month, buckets[i].end.day - 1))}\n${l.statsUsed}: ${numbers.format(buckets[i].totals.used)} · ${l.statsDiscarded}: ${numbers.format(buckets[i].totals.discarded)}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                Text(l.statsValue, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(l.statsValueNote),
                const SizedBox(height: 16),
                for (final entry in [
                  (
                    l.statsUsed,
                    totals.usedValue,
                    totals.usedPriced,
                    totals.used,
                  ),
                  (
                    l.statsDiscarded,
                    totals.discardedValue,
                    totals.discardedPriced,
                    totals.discarded,
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.$1, style: theme.textTheme.titleMedium),
                        Text(
                          entry.$3 == 0
                              ? l.statsNoPrice
                              : money.format(entry.$2),
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          '${l.statsPriced}: ${numbers.format(entry.$3)} / ${numbers.format(entry.$4)}',
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
  }
}
