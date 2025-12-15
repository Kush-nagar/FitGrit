import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Search bar widget with voice input and filter button
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onVoiceSearch;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onVoiceSearch,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.clear();
                            onChanged('');
                          },
                        )
                      : IconButton(
                          icon: CustomIconWidget(
                            iconName: 'mic',
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            onVoiceSearch();
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),

          // Filter Button
          Container(
            decoration: BoxDecoration(
              color: hasActiveFilters
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasActiveFilters
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomIconWidget(
                    iconName: 'tune',
                    size: 24,
                    color: hasActiveFilters
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onFilterTap();
              },
            ),
          ),
        ],
      ),
    );
  }
}
