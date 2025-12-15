import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Bottom sheet for recipe quick actions
class RecipeActionsBottomSheetWidget extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onSaveToFavorites;
  final VoidCallback onShare;
  final VoidCallback onAddToShoppingList;

  const RecipeActionsBottomSheetWidget({
    super.key,
    required this.recipe,
    required this.onSaveToFavorites,
    required this.onShare,
    required this.onAddToShoppingList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFavorite = recipe['isFavorite'] == true;

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

            // Recipe Info
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: recipe['image'] as String,
                      width: 20.w,
                      height: 20.w,
                      fit: BoxFit.cover,
                      semanticLabel: recipe['semanticLabel'] as String,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${recipe['cookingTime']} • ${recipe['difficulty']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: theme.dividerColor),

            // Action Options
            ListTile(
              leading: CustomIconWidget(
                iconName: isFavorite ? 'favorite' : 'favorite_border',
                size: 24,
                color: isFavorite
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
              title: Text(
                isFavorite ? 'Remove from Favorites' : 'Save to Favorites',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                onSaveToFavorites();
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                'Share Recipe',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                onShare();
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: CustomIconWidget(
                iconName: 'shopping_cart',
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
              title: Text(
                'Add Ingredients to Shopping List',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                onAddToShoppingList();
                Navigator.pop(context);
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
