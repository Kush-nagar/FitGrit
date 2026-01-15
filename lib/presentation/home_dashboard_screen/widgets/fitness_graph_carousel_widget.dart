import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/app_export.dart';
import '../../../services/firebase_fitness_service.dart';
import '../../../models/rep_counter.dart';

/// Fitness graph carousel widget showing weekly fitness data
///
/// Displays horizontal scrollable bar charts for different exercises
/// with Presidential Fitness Test benchmarks
class FitnessGraphCarouselWidget extends StatefulWidget {
  final Map<String, WeeklyFitnessData> weeklyData;
  final VoidCallback? onTap;

  const FitnessGraphCarouselWidget({
    super.key,
    required this.weeklyData,
    this.onTap,
  });

  @override
  State<FitnessGraphCarouselWidget> createState() =>
      _FitnessGraphCarouselWidgetState();
}

class _FitnessGraphCarouselWidgetState
    extends State<FitnessGraphCarouselWidget> {
  int _currentIndex = 0;
  late List<String> _exerciseKeys;

  @override
  void initState() {
    super.initState();
    // Filter out exercises with no data
    _exerciseKeys = widget.weeklyData.entries
        .where((entry) => entry.value.hasData)
        .map((entry) => entry.key)
        .toList();

    // If no data at all, show all exercise types anyway
    if (_exerciseKeys.isEmpty) {
      _exerciseKeys = widget.weeklyData.keys.toList();
    }
  }

  void _nextExercise() {
    if (_exerciseKeys.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _exerciseKeys.length;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _previousExercise() {
    if (_exerciseKeys.isNotEmpty) {
      setState(() {
        _currentIndex =
            (_currentIndex - 1 + _exerciseKeys.length) % _exerciseKeys.length;
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_exerciseKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentKey = _exerciseKeys[_currentIndex];
    final currentData = widget.weeklyData[currentKey]!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and navigation arrows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.bar_chart_rounded,
                                  color: theme.colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Weekly Fitness',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    currentData.exerciseName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_exerciseKeys.length > 1)
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _previousExercise,
                                  icon: Icon(
                                    Icons.chevron_left_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 28,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '${_currentIndex + 1}/${_exerciseKeys.length}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                IconButton(
                                  onPressed: _nextExercise,
                                  icon: Icon(
                                    Icons.chevron_right_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 28,
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 3.h),

                      // Bar chart
                      SizedBox(
                        height: 25.h,
                        child: _buildBarChart(currentData, theme),
                      ),

                      SizedBox(height: 2.h),

                      // Legend
                      if (currentData.benchmarkValue != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomPaint(
                              size: Size(6.w, 0.4.h),
                              painter: DashedLinePainter(
                                color: Colors.orange,
                                dashWidth: 4,
                                dashSpace: 3,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Presidential Fitness Test Baseline',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
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

  Widget _buildBarChart(WeeklyFitnessData data, ThemeData theme) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    // Calculate max value for scaling, ensuring benchmark is always visible
    double maxValue = 0;

    // Consider benchmark value
    if (data.benchmarkValue != null) {
      maxValue = data.benchmarkValue!;
    }

    // Consider all daily values
    for (final value in data.dailyValues) {
      if (value != null && value > maxValue) {
        maxValue = value;
      }
    }

    // Add padding to max value (20% more space above highest point)
    maxValue = maxValue * 1.3;
    if (maxValue == 0) maxValue = 10; // Default if no data

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                theme.colorScheme.primaryContainer.withValues(alpha: 0.95),
            tooltipPadding: EdgeInsets.all(2.w),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = startOfWeek.add(Duration(days: group.x.toInt()));
              final dateStr = '${date.month}/${date.day}';
              final value = rod.toY;
              final hasData = data.dailyValues[group.x.toInt()] != null;

              // Build tooltip text with more information
              String tooltipText = '$dateStr\n';

              if (!hasData || value == 0) {
                tooltipText += 'No data';
              } else {
                tooltipText += '${value.toStringAsFixed(1)} ${data.unit}';

                // Add benchmark comparison if available
                if (data.benchmarkValue != null && data.benchmarkValue! > 0) {
                  final meetsGoal = data.exerciseType == ExerciseType.shuttleRun
                      ? value <= data.benchmarkValue!
                      : value >= data.benchmarkValue!;

                  if (meetsGoal) {
                    tooltipText += '\n✓ Meets Goal';
                  } else {
                    final diff = (value - data.benchmarkValue!).abs();
                    tooltipText +=
                        '\n${diff.toStringAsFixed(1)} ${data.exerciseType == ExerciseType.shuttleRun ? "above" : "below"} goal';
                  }
                }
              }

              return BarTooltipItem(
                tooltipText,
                theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > 6) return const SizedBox.shrink();

                final date = startOfWeek.add(Duration(days: index));
                final dayNames = [
                  'Sun',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat'
                ];

                return Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text(
                    dayNames[date.weekday % 7],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: maxValue / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            left: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        barGroups: List.generate(7, (index) {
          final value = data.dailyValues[index] ?? 0;
          final hasData = data.dailyValues[index] != null;

          // Determine color based on benchmark
          Color barColor;
          if (!hasData) {
            barColor = theme.colorScheme.outline.withValues(alpha: 0.2);
          } else if (data.benchmarkValue != null) {
            // For shuttle run, lower is better
            if (data.exerciseType == ExerciseType.shuttleRun) {
              barColor = value <= data.benchmarkValue!
                  ? theme.colorScheme.primary
                  : theme.colorScheme.tertiary;
            } else {
              barColor = value >= data.benchmarkValue!
                  ? theme.colorScheme.primary
                  : theme.colorScheme.tertiary;
            }
          } else {
            barColor = theme.colorScheme.primary;
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
                width: 6.w,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue,
                  color: theme.colorScheme.outline.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        }),
        // Draw benchmark line - always show if benchmark exists
        extraLinesData: data.benchmarkValue != null && data.benchmarkValue! > 0
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: data.benchmarkValue!,
                    color: Colors.orange,
                    strokeWidth: 3,
                    dashArray: [10, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (line) =>
                          'Goal: ${line.y.toStringAsFixed(0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        backgroundColor:
                            theme.colorScheme.surface.withValues(alpha: 0.95),
                      ),
                      alignment: Alignment.topRight,
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

/// Custom painter to draw a dashed line for the legend
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
