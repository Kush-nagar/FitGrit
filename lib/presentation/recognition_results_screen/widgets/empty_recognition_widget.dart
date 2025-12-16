import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class EmptyRecognitionWidget extends StatelessWidget {
  final VoidCallback onTryAgain;
  final VoidCallback onAddManually;

  const EmptyRecognitionWidget({
    super.key,
    required this.onTryAgain,
    required this.onAddManually,
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
              width: 35.w,
              height: 35.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'search_off',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 64,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'No Ingredients Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'We couldn\'t identify any ingredients in your photo. Try taking another photo or add ingredients manually.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTryAgain,
                    icon: CustomIconWidget(
                      iconName: 'refresh',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddManually,
                    icon: CustomIconWidget(
                      iconName: 'add',
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      'Add Manually',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
