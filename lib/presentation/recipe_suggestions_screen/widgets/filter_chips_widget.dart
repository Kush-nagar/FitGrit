import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Horizontal scrollable filter chips with clear all option
class FilterChipsWidget extends StatelessWidget {
  final List<String> activeFilters;
  final Function(String) onRemoveFilter;
  final VoidCallback onClearAll;

  const FilterChipsWidget({
    super.key,
    required this.activeFilters,
    required this.onRemoveFilter,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 5.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: activeFilters.length + 1,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          if (index == activeFilters.length) {
            // Clear All Button
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onClearAll();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clear All',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    CustomIconWidget(
                      iconName: 'close',
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                  ],
                ),
              ),
            );
          }

          // Filter Chip
          final filter = activeFilters[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 1.w),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onRemoveFilter(filter);
                  },
                  child: CustomIconWidget(
                    iconName: 'close',
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
