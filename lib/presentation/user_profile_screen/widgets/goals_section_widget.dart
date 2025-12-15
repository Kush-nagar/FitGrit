import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Goals section displaying calorie, water, and weight targets
class GoalsSectionWidget extends StatelessWidget {
  final int calorieTarget;
  final double waterIntakeGoal;
  final String weightGoal;
  final VoidCallback onEditCalorieTarget;
  final VoidCallback onEditWaterGoal;
  final VoidCallback onEditWeightGoal;

  const GoalsSectionWidget({
    super.key,
    required this.calorieTarget,
    required this.waterIntakeGoal,
    required this.weightGoal,
    required this.onEditCalorieTarget,
    required this.onEditWaterGoal,
    required this.onEditWeightGoal,
  });

  Widget _buildGoalItem({
    required BuildContext context,
    required String label,
    required String value,
    required String iconName,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Goals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        _buildGoalItem(
          context: context,
          label: 'Daily Calorie Target',
          value: '$calorieTarget kcal',
          iconName: 'restaurant',
          onTap: onEditCalorieTarget,
        ),
        SizedBox(height: 1.h),
        _buildGoalItem(
          context: context,
          label: 'Water Intake Goal',
          value: '${waterIntakeGoal.toStringAsFixed(1)} L',
          iconName: 'water_drop',
          onTap: onEditWaterGoal,
        ),
        SizedBox(height: 1.h),
        _buildGoalItem(
          context: context,
          label: 'Weight Goal',
          value: weightGoal,
          iconName: 'monitor_weight',
          onTap: onEditWeightGoal,
        ),
      ],
    );
  }
}
