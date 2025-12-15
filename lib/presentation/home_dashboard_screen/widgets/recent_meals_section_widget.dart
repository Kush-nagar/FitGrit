import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Recent meals section widget
///
/// Displays horizontal scrollable cards with food images, names, and calories
/// Features swipe actions for edit/delete functionality
class RecentMealsSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final Function(Map<String, dynamic>)? onMealTap;
  final Function(Map<String, dynamic>)? onEditMeal;
  final Function(Map<String, dynamic>)? onDeleteMeal;

  const RecentMealsSectionWidget({
    super.key,
    required this.meals,
    this.onMealTap,
    this.onEditMeal,
    this.onDeleteMeal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Meals',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/food-log-history-screen');
                },
                child: Text('View All'),
              ),
            ],
          ),
        ),
        meals.isEmpty
            ? _buildEmptyState(context)
            : SizedBox(
                height: 24.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return _buildMealCard(context, meal);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 24.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'restaurant_menu',
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 48,
            ),
            SizedBox(height: 1.h),
            Text(
              'No meals logged today',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Start tracking your nutrition!',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                    theme.colorScheme.surface.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onMealTap?.call(meal);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 42.w,
                    padding: EdgeInsets.all(2.5.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomImageWidget(
                                imageUrl: meal['image'] as String,
                                width: double.infinity,
                                height: 12.h,
                                fit: BoxFit.cover,
                                semanticLabel: meal['semanticLabel'] as String,
                              ),
                            ),
                            Positioned(
                              top: 1.w,
                              right: 1.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.error
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      color: theme.colorScheme.error,
                                      size: 14,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      '${meal['calories']}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          meal['name'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            meal['mealType'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              meal['time'] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(1.w),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      onEditMeal?.call(meal);
                                    },
                                    child: Icon(
                                      Icons.edit_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                Container(
                                  padding: EdgeInsets.all(1.w),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      onDeleteMeal?.call(meal);
                                    },
                                    child: Icon(
                                      Icons.delete_rounded,
                                      color: theme.colorScheme.error,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
