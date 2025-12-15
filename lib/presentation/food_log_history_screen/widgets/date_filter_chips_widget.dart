import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Date filter chips for quick date range selection
class DateFilterChipsWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const DateFilterChipsWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ['Today', 'Week', 'Month', 'All'];

    return SizedBox(
      height: 6.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return FilterChip(
            label: Text(
              filter,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) => onFilterSelected(filter),
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
