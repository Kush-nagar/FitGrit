/// Shuttle Run Details Screen
/// Shows detailed statistics and metrics for shuttle run analysis
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/shuttle_run_metrics_calculator.dart';
import '../../services/presidential_fitness_benchmarks.dart';

class ShuttleRunDetailsScreen extends StatefulWidget {
  final ShuttleRunPerformanceMetrics metrics;
  final BenchmarkComparison? benchmarkComparison;

  const ShuttleRunDetailsScreen({
    super.key,
    required this.metrics,
    this.benchmarkComparison,
  });

  @override
  State<ShuttleRunDetailsScreen> createState() =>
      _ShuttleRunDetailsScreenState();
}

class _ShuttleRunDetailsScreenState extends State<ShuttleRunDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'Shuttle Run Analysis',
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(theme),
            const SizedBox(height: 20),
            if (widget.benchmarkComparison != null) ...[
              _buildBenchmarkStatus(theme),
              const SizedBox(height: 20),
            ],
            _buildHighlightCards(theme),
            const SizedBox(height: 24),
            _buildCompactStatsGrid(theme),
            const SizedBox(height: 24),
            _buildSpeedChart(theme),
            const SizedBox(height: 20),
            _buildRunTimesChart(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shuttle Run',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Performance Analysis',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildHeaderStat(
                  icon: Icons.directions_run,
                  label: 'Runs',
                  value: '${widget.metrics.completedRuns}',
                  theme: theme,
                ),
                const SizedBox(width: 16),
                _buildHeaderStat(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: '${widget.metrics.totalTime.toStringAsFixed(1)}s',
                  theme: theme,
                ),
                const SizedBox(width: 16),
                _buildHeaderStat(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${widget.metrics.totalDistance.toStringAsFixed(0)}m',
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCards(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildHighlightCard(
              icon: Icons.flash_on,
              label: 'Max Speed',
              value: '${widget.metrics.maxSpeed.toStringAsFixed(2)}',
              unit: 'm/s',
              color: Colors.orange,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildHighlightCard(
              icon: Icons.trending_up,
              label: 'Avg Speed',
              value: '${widget.metrics.averageSpeed.toStringAsFixed(2)}',
              unit: 'm/s',
              color: Colors.blue,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatsGrid(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Metrics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildStatRow(
                  icon: Icons.av_timer,
                  label: 'Avg Run Time',
                  value:
                      '${widget.metrics.averageRunTime.toStringAsFixed(2)} s',
                  theme: theme,
                  isFirst: true,
                ),
                _buildStatRow(
                  icon: Icons.swap_horiz,
                  label: 'Direction Changes',
                  value: '${widget.metrics.directionChanges}',
                  theme: theme,
                ),
                _buildStatRow(
                  icon: Icons.rotate_90_degrees_ccw,
                  label: 'Avg Turn Time',
                  value:
                      '${widget.metrics.averageTurnTime.toStringAsFixed(2)} s',
                  theme: theme,
                ),
                _buildStatRow(
                  icon: Icons.architecture,
                  label: 'Shuttle Distance',
                  value:
                      '${widget.metrics.shuttleDistance.toStringAsFixed(1)} m',
                  theme: theme,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedChart(ThemeData theme) {
    if (widget.metrics.speedProfile.isEmpty) {
      return const SizedBox.shrink();
    }

    final speedData = widget.metrics.speedProfile
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Speed Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.15),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Time',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: (speedData.length / 5).ceilToDouble(),
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                value.toInt().toString(),
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'm/s',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: speedData.length.toDouble() - 1,
                    minY: 0,
                    maxY: (widget.metrics.maxSpeed * 1.2).ceilToDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: speedData,
                        isCurved: true,
                        curveSmoothness: 0.4,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.4),
                              theme.colorScheme.secondary
                                  .withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunTimesChart(ThemeData theme) {
    if (widget.metrics.runTimes.isEmpty) {
      return const SizedBox.shrink();
    }

    final runTimeData = widget.metrics.runTimes
        .asMap()
        .entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 24,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ))
        .toList();

    final maxTime = widget.metrics.runTimes.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Individual Run Times',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxTime * 1.2).ceilToDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => theme
                            .colorScheme.primaryContainer
                            .withValues(alpha: 0.95),
                        tooltipBorder: BorderSide(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final runNumber = group.x.toInt() + 1;
                          final time = widget.metrics.runTimes[group.x.toInt()];

                          return BarTooltipItem(
                            'Run $runNumber\n${time.toStringAsFixed(2)}s',
                            TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Run Number',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${value.toInt() + 1}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'sec',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.15),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: runTimeData,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkStatus(ThemeData theme) {
    final comparison = widget.benchmarkComparison!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: comparison.passed
              ? [
                  Colors.green.withValues(alpha: 0.15),
                  Colors.green.withValues(alpha: 0.05),
                ]
              : [
                  Colors.red.withValues(alpha: 0.15),
                  Colors.red.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: comparison.passed
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.red.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (comparison.passed ? Colors.green : Colors.red)
                .withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (comparison.passed ? Colors.green : Colors.red)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  comparison.passed ? Icons.emoji_events : Icons.flag,
                  color:
                      comparison.passed ? Colors.green[700] : Colors.red[700],
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presidential Fitness Test',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comparison.passed ? 'PASSED ✅' : 'NOT MET ❌',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: comparison.passed
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBenchmarkStat(
            'Your Time',
            '${comparison.userValue.toStringAsFixed(1)}s',
            theme,
          ),
          const SizedBox(height: 12),
          _buildBenchmarkStat(
            'Required Time',
            '${comparison.benchmarkValue.toStringAsFixed(1)}s',
            theme,
          ),
          const SizedBox(height: 12),
          _buildBenchmarkStat(
            'Difference',
            comparison.differenceText,
            theme,
            color: comparison.passed ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              comparison.passed
                  ? '🎉 Excellent work! You\'re ${comparison.differenceText} faster than the Presidential Fitness Test standard!'
                  : '💪 Keep training! You need to be ${comparison.differenceText} faster to meet the Presidential Fitness Test standard.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkStat(String label, String value, ThemeData theme,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
