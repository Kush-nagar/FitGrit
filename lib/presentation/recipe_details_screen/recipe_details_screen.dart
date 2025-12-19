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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with description
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(2.h),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.schedule,
                        'Prep: ${recipe.prepTimeMinutes} min',
                        context,
                      ),
                      SizedBox(width: 2.w),
                      _buildInfoChip(
                        Icons.access_time,
                        'Cook: ${recipe.cookTimeMinutes} min',
                        context,
                      ),
                      SizedBox(width: 2.w),
                      _buildInfoChip(
                        Icons.restaurant,
                        '${recipe.servings} servings',
                        context,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),

            // Nutrition Facts section
            _buildNutritionSection(recipe.nutrition, context),
            SizedBox(height: 1.h),

            // Ingredients section
            _buildIngredientsSection(recipe.ingredients, context),
            SizedBox(height: 1.h),

            // Steps section
            _buildStepsSection(recipe.steps, context),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          SizedBox(width: 1.w),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
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
      padding: EdgeInsets.all(2.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Facts',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Per serving',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 2.h),

          // Calories - highlighted
          Container(
            padding: EdgeInsets.all(1.5.h),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Calories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${nutrition.calories.toInt()}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Macros section
          Text(
            'Macronutrients',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildNutritionRow(
              'Protein', nutrition.protein, 'g', Colors.blue, context),
          _buildNutritionRow(
              'Carbohydrates', nutrition.carbs, 'g', Colors.green, context),
          _buildNutritionRow('Fat', nutrition.fat, 'g', Colors.purple, context),
          SizedBox(height: 2.h),

          // Other nutrients
          Text(
            'Other Nutrients',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildNutritionRow('Fiber', nutrition.fiber, 'g',
              theme.colorScheme.onSurfaceVariant, context),
          _buildNutritionRow('Sugar', nutrition.sugar, 'g',
              theme.colorScheme.onSurfaceVariant, context),
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
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
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
    );
  }

  Widget _buildIngredientsSection(
      List<String> ingredients, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(2.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_basket,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Ingredients',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...ingredients.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 0.5.h),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
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
      padding: EdgeInsets.all(2.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Text(
                'Instructions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 0.5.h),
                      child: Text(
                        step,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
