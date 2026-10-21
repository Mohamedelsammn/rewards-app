import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Real participation-growth chart over the trailing 7 days. [dailyGrowth]
/// must always be real backend-derived data -- index 0 is 6 days ago, index
/// 6 is today -- never a fake/static series. Shared by [GiveawayAnalyticsPage]
/// (single giveaway) and the Admin Analysis overall page (aggregated across
/// an admin's own giveaways) so there is one chart implementation, not two.
///
/// Handles every case the responsiveness pass called out explicitly:
/// - **Zero data** -- an honest empty message instead of a flat, unlabeled
///   chart that looks broken.
/// - **One data point** -- a single non-zero day still scales correctly
///   (maxY is derived from whatever the real peak is, floored at 1).
/// - **Large ranges** -- the Y axis picks a readable tick interval instead
///   of a fixed step, so it stays legible whether the peak is 3 or 3,000.
/// - **Readable axes** -- real weekday labels (locale-aware via
///   [DateFormat.E], so Arabic renders actual Arabic weekday abbreviations,
///   not transliterated English) and integer participant-count labels.
/// - **Width** -- fills whatever width its parent gives it (fl_chart lays
///   itself out via its own internal LayoutBuilder); never a fixed pixel
///   width, so it never overflows a narrow screen.
class ParticipationGrowthChart extends StatelessWidget {
  const ParticipationGrowthChart({
    super.key,
    required this.dailyGrowth,
    required this.emptyMessage,
  });

  final List<int> dailyGrowth;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final total = dailyGrowth.fold<int>(0, (sum, v) => sum + v);

    if (total == 0) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            emptyMessage,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final peak = dailyGrowth.reduce((a, b) => a > b ? a : b).toDouble();
    // A readable tick step regardless of magnitude: for a peak of 3 this
    // gives an interval of 1 (labels 0,1,2,3...); for a peak of 3000 it
    // gives 1000 (labels 0, 1000, 2000, 3000) -- always roughly 3-5 ticks.
    final yInterval = (peak / 4).ceil().clamp(1, 1 << 30).toDouble();
    final maxY = ((peak / yInterval).ceil() * yInterval) + yInterval;

    final locale = Localizations.localeOf(context).toString();
    final today = DateTime.now();

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(value.toInt().toString(), style: AppTypography.labelSm);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailyGrowth.length) return const SizedBox.shrink();
                final day = today.subtract(Duration(days: dailyGrowth.length - 1 - index));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat.E(locale).format(day), style: AppTypography.labelSm),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.inverseSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              rod.toY.toInt().toString(),
              AppTypography.labelSm.copyWith(color: AppColors.inverseOnSurface),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < dailyGrowth.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyGrowth[i].toDouble(),
                  color: AppColors.primary,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
