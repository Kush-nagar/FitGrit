import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Meal type filter chips for filtering by meal category
class MealTypeFilterWidget extends StatelessWidget {
  final List<String> selectedMealTypes;
  final Function(String) onMealTypeToggle;

  const MealTypeFilterWidget({
    super.key,
    required this.selectedMealTypes,
    required this.onMealTypeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    final mealIcons = {
      'Breakfast': 'free_breakfast',
      'Lunch': 'lunch_dining',
      'Dinner': 'dinner_dining',
      'Snacks': 'cookie',
    };

    return SizedBox(
      height: 6.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: mealTypes.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final mealType = mealTypes[index];
          final isSelected = selectedMealTypes.contains(mealType);

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: mealIcons[mealType] ?? 'restaurant',
                  size: 18,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
                SizedBox(width: 1.w),
                Text(
                  mealType,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) => onMealTypeToggle(mealType),
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 1,
            ),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
