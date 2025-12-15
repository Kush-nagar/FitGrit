import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Individual food entry card with swipe actions
class FoodEntryCardWidget extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onViewDetails;

  const FoodEntryCardWidget({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(entry['id']),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onDelete();
            },
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.lightImpact();
              onEdit();
            },
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.lightImpact();
              onDuplicate();
            },
            backgroundColor: AppTheme.accentPurple,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.content_copy,
            label: 'Duplicate',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: InkWell(
        onTap: onViewDetails,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showContextMenu(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: entry['image'] as String,
                  width: 15.w,
                  height: 15.w,
                  fit: BoxFit.cover,
                  semanticLabel: entry['semanticLabel'] as String,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      entry['portion'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'local_fire_department',
                          size: 14,
                          color: AppTheme.accentOrange,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${entry['calories']} cal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'chevron_right',
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit_outlined',
                size: 24,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Edit Details',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                size: 24,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Duplicate Meal',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onDuplicate();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                size: 24,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Share Entry',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                _shareEntry(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'info_outline',
                size: 24,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'View Nutrition Breakdown',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                onViewDetails();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete_outline',
                size: 24,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Delete Entry',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _shareEntry(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Shared: ${entry['name']} - ${entry['calories']} cal',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
