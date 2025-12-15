import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget encouraging food scanning
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onScanFood;

  const EmptyStateWidget({
    super.key,
    required this.onScanFood,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'restaurant_menu',
                  size: 15.w,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Recipes Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Scan food items to get personalized recipe suggestions based on your ingredients',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: onScanFood,
              icon: CustomIconWidget(
                iconName: 'camera_alt',
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              label: const Text('Scan Food'),
            ),
          ],
        ),
      ),
    );
  }
}
