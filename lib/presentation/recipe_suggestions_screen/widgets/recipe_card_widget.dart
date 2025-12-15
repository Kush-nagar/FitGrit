import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Recipe card widget displaying recipe information with image, title, time, and difficulty
class RecipeCardWidget extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RecipeCardWidget({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getDifficultyColor(BuildContext context, String difficulty) {
    final theme = Theme.of(context);
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return theme.colorScheme.tertiary;
      case 'medium':
        return theme.colorScheme.secondary;
      case 'hard':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CustomImageWidget(
                imageUrl: recipe['image'] as String,
                width: double.infinity,
                height: 20.h,
                fit: BoxFit.cover,
                semanticLabel: recipe['semanticLabel'] as String,
              ),
            ),

            // Recipe Details
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recipe['title'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),

                  // Time and Difficulty Row
                  Row(
                    children: [
                      // Cooking Time
                      CustomIconWidget(
                        iconName: 'schedule',
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        recipe['cookingTime'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: 3.w),

                      // Difficulty Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(
                                  context, recipe['difficulty'] as String)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          recipe['difficulty'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getDifficultyColor(
                                context, recipe['difficulty'] as String),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Favorite Indicator
                  if (recipe['isFavorite'] == true) ...[
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'favorite',
                          size: 14,
                          color: theme.colorScheme.error,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Saved',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
