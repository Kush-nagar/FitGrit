// ignore_for_file: unused_local_variable

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;

/// Daily calorie progress card widget
///
/// Displays circular progress indicator with current/target calories
/// Features smooth animations and lime green accent colors
class DailyCalorieCardWidget extends StatefulWidget {
  final int currentCalories;
  final int targetCalories;
  final VoidCallback? onTap;

  const DailyCalorieCardWidget({
    super.key,
    required this.currentCalories,
    required this.targetCalories,
    this.onTap,
  });

  @override
  State<DailyCalorieCardWidget> createState() => _DailyCalorieCardWidgetState();
}

class _DailyCalorieCardWidgetState extends State<DailyCalorieCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentCalories / widget.targetCalories,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(DailyCalorieCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCalories != widget.currentCalories ||
        oldWidget.targetCalories != widget.targetCalories) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.currentCalories / widget.targetCalories,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        (widget.currentCalories / widget.targetCalories).clamp(0.0, 1.0);
    final remainingCalories = widget.targetCalories - widget.currentCalories;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.03),
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
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.7),
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
                              Icons.local_fire_department_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Calorie Goal',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}% Complete',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Center(
                        child: SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _CircularProgressPainter(
                                  progress: _progressAnimation.value,
                                  primaryColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.surface,
                                  strokeWidth: 12,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.currentCalories.toString(),
                                        style: theme.textTheme.displaySmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'of ${widget.targetCalories}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      Text(
                                        'calories',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                              theme.colorScheme.primary.withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              'Consumed',
                              '${widget.currentCalories} cal',
                              theme.colorScheme.primary,
                            ),
                            Container(
                              width: 1.5,
                              height: 4.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    theme.colorScheme.outline
                                        .withValues(alpha: 0.3),
                                    theme.colorScheme.outline
                                        .withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                            ),
                            _buildStatItem(
                              context,
                              remainingCalories >= 0 ? 'Remaining' : 'Over',
                              '${remainingCalories.abs()} cal',
                              remainingCalories >= 0
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.error,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      // Nutrition Breakdown
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.secondary
                                  .withValues(alpha: 0.05),
                              theme.colorScheme.tertiary
                                  .withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.pie_chart_rounded,
                                  color: theme.colorScheme.secondary,
                                  size: 18,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Nutrition Breakdown',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMacroItem(
                                    context,
                                    'Carbs',
                                    '156g',
                                    '45%',
                                    theme.colorScheme.secondary,
                                    0.45,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: _buildMacroItem(
                                    context,
                                    'Protein',
                                    '89g',
                                    '25%',
                                    theme.colorScheme.primary,
                                    0.25,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: _buildMacroItem(
                                    context,
                                    'Fats',
                                    '48g',
                                    '30%',
                                    theme.colorScheme.tertiary,
                                    0.30,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildMacroItem(
    BuildContext context,
    String label,
    String grams,
    String percentage,
    Color color,
    double progress,
  ) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  percentage,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(
                  height: 6,
                  width: double.infinity,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              grams,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
