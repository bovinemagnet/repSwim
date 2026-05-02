import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_providers.dart';
import '../../../pb/domain/entities/personal_best.dart';
import '../../../../core/utils/duration_utils.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          final stats = [
            _StatCard(
              icon: Icons.pool,
              label: 'Sessions',
              value: '${analytics.totalSessions}',
            ),
            _StatCard(
              icon: Icons.straighten,
              label: 'Total Distance',
              value: _formatDistance(analytics.totalDistanceMeters),
            ),
            _StatCard(
              icon: Icons.speed,
              label: 'Avg Pace',
              value: analytics.averagePacePerHundred == Duration.zero
                  ? '--'
                  : DurationUtils.formatDuration(
                      analytics.averagePacePerHundred,
                    ),
              subtitle: '/100m',
            ),
            _StatCard(
              icon: Icons.event_available,
              label: 'Consistency',
              value: '${analytics.consistencyScore}%',
            ),
          ];
          final weeklyChart = _ChartPanel(
            title: 'Last 7 Days',
            child: analytics.weeklyDistances.every((d) => d == 0)
                ? Center(
                    child: Text(
                      'No swim data in the last 7 days',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  )
                : _WeeklyBarChart(distances: analytics.weeklyDistances),
          );
          final paceChart = _ChartPanel(
            title: 'Pace Trend',
            child: analytics.paceTrend.length < 2
                ? Center(
                    child: Text(
                      'Save more sessions to see pace trends',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  )
                : _PaceTrendChart(points: analytics.paceTrend),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.8 : 1.25,
                  children: stats,
                ),
                const SizedBox(height: 24),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: weeklyChart),
                      const SizedBox(width: 16),
                      Expanded(child: paceChart),
                    ],
                  )
                else ...[
                  weeklyChart,
                  const SizedBox(height: 24),
                  paceChart,
                ],
                const SizedBox(height: 24),
                _PbHighlightsSection(pbs: analytics.pbHighlights),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(height: 220, child: child),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

class _PaceTrendChart extends StatelessWidget {
  const _PaceTrendChart({required this.points});

  final List<PaceTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = List.generate(
      points.length,
      (index) => FlSpot(
        index.toDouble(),
        points[index].pacePerHundred.inSeconds.toDouble(),
      ),
    );
    final values = spots.map((spot) => spot.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minY = (minValue - 10).clamp(0, double.infinity).toDouble();
    final maxY = maxValue == minValue ? maxValue + 10 : maxValue + 10;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    DurationUtils.formatDuration(
                      Duration(seconds: spot.y.round()),
                    ),
                    TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value == minY || value == maxY) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DurationUtils.formatDuration(
                    Duration(seconds: value.round()),
                  ),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d MMM').format(points[index].date),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _PbHighlightsSection extends StatelessWidget {
  const _PbHighlightsSection({required this.pbs});

  final List<PersonalBest> pbs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('PB Highlights'),
        const SizedBox(height: 12),
        if (pbs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Save swim sessions with lap times to build PB highlights',
                style: TextStyle(color: colorScheme.outline),
              ),
            ),
          )
        else
          ...pbs.map((pb) => _PbHighlightTile(pb: pb)),
      ],
    );
  }
}

class _PbHighlightTile extends StatelessWidget {
  const _PbHighlightTile({required this.pb});

  final PersonalBest pb;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(pb.achievedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.amber),
        title: Text('${pb.stroke} ${pb.distance}m'),
        subtitle: Text(date),
        trailing: Text(
          DurationUtils.formatDuration(pb.bestTime),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.distances});

  final List<int> distances;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxVal = distances
        .reduce((a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1.0, double.infinity);

    // Day labels: oldest is index 0, today is index 6
    final today = DateTime.now();
    final dayLabels = List.generate(
      7,
      (i) => DateFormat('E').format(
        today.subtract(Duration(days: 6 - i)),
      ),
    );

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()}m',
                TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxVal * 1.2) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}m',
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= dayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dayLabels[i],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outlineVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          7,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: distances[i].toDouble(),
                color: distances[i] > 0
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
