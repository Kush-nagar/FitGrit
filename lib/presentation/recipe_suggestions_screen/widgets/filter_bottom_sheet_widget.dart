import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

/// Bottom sheet for recipe filtering options
class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, List<String>> filterOptions;
  final Map<String, String> selectedFilters;
  final Function(Map<String, String>) onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.filterOptions,
    required this.selectedFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, String> _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.selectedFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: EdgeInsets.only(top: 2.h),
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Recipes',
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _tempFilters.clear();
                      });
                    },
                    child: Text(
                      'Reset',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.dividerColor),

            // Filter Options
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.filterOptions.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: entry.value.map((option) {
                            final isSelected =
                                _tempFilters[entry.key] == option;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (isSelected) {
                                    _tempFilters.remove(entry.key);
                                  } else {
                                    _tempFilters[entry.key] = option;
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 2.h),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            // Apply Button
            Padding(
              padding: EdgeInsets.all(4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onApplyFilters(_tempFilters);
                    Navigator.pop(context);
                  },
                  child: Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
