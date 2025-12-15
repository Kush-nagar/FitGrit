import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Quick action buttons widget
///
/// Provides thumb-reachable action buttons for common tasks
/// Features: Add Water, Log Meal, View Goals
class QuickActionsWidget extends StatelessWidget {
  final VoidCallback? onAddWater;
  final VoidCallback? onLogMeal;
  final VoidCallback? onViewGoals;

  const QuickActionsWidget({
    super.key,
    this.onAddWater,
    this.onLogMeal,
    this.onViewGoals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: 'water_drop',
                  label: 'Add Water',
                  color: theme.colorScheme.tertiary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onAddWater?.call();
                  },
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: 'restaurant',
                  label: 'Log Meal',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onLogMeal?.call();
                  },
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: 'flag',
                  label: 'View Goals',
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onViewGoals?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.08),
                  color.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: color.withValues(alpha: 0.2),
                highlightColor: color.withValues(alpha: 0.1),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 2.5.h, horizontal: 2.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withValues(alpha: 0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CustomIconWidget(
                          iconName: icon,
                          color: theme.colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      SizedBox(height: 1.2.h),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
