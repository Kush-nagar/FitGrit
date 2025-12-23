  import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/recipe_model.dart';

class RecipeCardWidget extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCardWidget({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(2.5.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe name with accent
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.2.h),

                // Description
                Text(
                  recipe.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),

                // Time and servings info
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.5.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${recipe.totalTimeMinutes} min',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.5.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.tertiary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 16,
                            color: theme.colorScheme.tertiary,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${recipe.servings} servings',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Nutrition summary
                Container(
                  padding: EdgeInsets.all(2.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer.withOpacity(0.3),
                        theme.colorScheme.tertiaryContainer.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutritionItem(
                        'Calories',
                        '${recipe.nutrition.calories.toInt()}',
                        Icons.local_fire_department,
                        Colors.orange,
                        context,
                      ),
                      _buildNutritionItem(
                        'Protein',
                        '${recipe.nutrition.protein.toInt()}g',
                        Icons.fitness_center,
                        Colors.blue,
                        context,
                      ),
                      _buildNutritionItem(
                        'Carbs',
                        '${recipe.nutrition.carbs.toInt()}g',
                        Icons.grain,
                        Colors.green,
                        context,
                      ),
                      _buildNutritionItem(
                        'Fat',
                        '${recipe.nutrition.fat.toInt()}g',
                        Icons.opacity,
                        Colors.purple,
                        context,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),

                // View details button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.2.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Recipe',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionItem(
    String label,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(1.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        SizedBox(height: 0.8.h),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
