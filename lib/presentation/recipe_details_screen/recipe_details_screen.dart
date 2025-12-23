import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../models/recipe_model.dart';
import '../../widgets/custom_app_bar.dart';

class RecipeDetailsScreen extends StatelessWidget {
  const RecipeDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Recipe? recipe = args?['recipe'] as Recipe?;

    if (recipe == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Recipe Details',
        ),
        body: const Center(
          child: Text('No recipe data available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: recipe.name,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with description
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(2.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 2.5.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: [
                        _buildInfoChip(
                          Icons.schedule_outlined,
                          'Prep: ${recipe.prepTimeMinutes} min',
                          context,
                        ),
                        _buildInfoChip(
                          Icons.access_time_outlined,
                          'Cook: ${recipe.cookTimeMinutes} min',
                          context,
                        ),
                        _buildInfoChip(
                          Icons.restaurant_outlined,
                          '${recipe.servings} servings',
                          context,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),

              // Nutrition Facts section
              _buildNutritionSection(recipe.nutrition, context),
              SizedBox(height: 2.h),

              // Ingredients section
              _buildIngredientsSection(recipe.ingredients, context),
              SizedBox(height: 2.h),

              // Steps section
              _buildStepsSection(recipe.steps, context),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: 2.w),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(
      NutritionFacts nutrition, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(2.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Nutrition Facts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Per serving',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),

          // Calories - highlighted
          Container(
            padding: EdgeInsets.all(2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF7F3F).withOpacity(0.2),
                  const Color(0xFFFF7F3F).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF7F3F).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(1.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7F3F).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Color(0xFFFF7F3F),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Calories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${nutrition.calories.toInt()}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF7F3F),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.5.h),

          // Macros section
          Text(
            'Macronutrients',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildNutritionRow('Protein', nutrition.protein, 'g',
              const Color(0xFF6A6AED), context),
          _buildNutritionRow('Carbohydrates', nutrition.carbs, 'g',
              theme.colorScheme.primary, context),
          _buildNutritionRow(
              'Fat', nutrition.fat, 'g', const Color(0xFFD73767), context),
          SizedBox(height: 2.5.h),

          // Other nutrients
          Text(
            'Other Nutrients',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildNutritionRow('Fiber', nutrition.fiber, 'g',
              theme.colorScheme.tertiary, context),
          _buildNutritionRow(
              'Sugar', nutrition.sugar, 'g', const Color(0xFFFF7F3F), context),
          _buildNutritionRow('Sodium', nutrition.sodium, 'mg',
              theme.colorScheme.onSurfaceVariant, context),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, double value, String unit,
      Color color, BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection(
      List<String> ingredients, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(2.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shopping_basket_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'Ingredients',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...ingredients.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Container(
                padding: EdgeInsets.all(1.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 0.5.h),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStepsSection(List<String> steps, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(2.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.format_list_numbered_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'Instructions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...steps.asMap().entries.map((entry) {
            final stepNumber = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Container(
                padding: EdgeInsets.all(2.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$stepNumber',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 0.8.h),
                        child: Text(
                          step,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
