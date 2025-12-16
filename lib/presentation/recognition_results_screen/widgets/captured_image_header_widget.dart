import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';

import '../../../widgets/custom_icon_widget.dart';

class CapturedImageHeaderWidget extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onRetake;

  const CapturedImageHeaderWidget({
    super.key,
    this.imagePath,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imagePath != null
                  ? Image.file(
                      File(imagePath!),
                      width: 20.w,
                      height: 20.w,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'broken_image',
                              color: theme.colorScheme.error,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'image',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Captured Image',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'AI recognition complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onRetake,
            icon: CustomIconWidget(
              iconName: 'camera_alt',
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              'Retake',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
