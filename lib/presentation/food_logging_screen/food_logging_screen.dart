import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../core/models/nutrition_info.dart';
import '../../services/gemini_service.dart';
import '../../services/nutrition_storage_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';

class FoodLoggingScreen extends StatefulWidget {
  const FoodLoggingScreen({super.key});

  @override
  State<FoodLoggingScreen> createState() => _FoodLoggingScreenState();
}

class _FoodLoggingScreenState extends State<FoodLoggingScreen> {
  bool _isLoading = true;
  String? _imagePath;
  List<String> _ingredients = [];
  NutritionInfo? _nutritionInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNutritionInfo();
  }

  Future<void> _loadNutritionInfo() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args == null) {
        setState(() {
          _errorMessage = 'No data provided';
          _isLoading = false;
        });
        return;
      }

      _imagePath = args['imagePath'] as String?;
      _ingredients = args['ingredients'] != null
          ? List<String>.from(args['ingredients'])
          : [];

      if (_imagePath == null || _ingredients.isEmpty) {
        setState(() {
          _errorMessage = 'Missing image or ingredients';
          _isLoading = false;
        });
        return;
      }

      try {
        final geminiService = GeminiService(
          apiKey: AppConfig.geminiApiKey,
        );

        final nutritionData = await geminiService.getNutritionInfo(
          imagePath: _imagePath!,
          ingredients: _ingredients,
        );

        setState(() {
          _nutritionInfo = NutritionInfo.fromJson(nutritionData);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to get nutrition info: $e';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _logFood() async {
    if (_nutritionInfo == null) return;

    HapticFeedback.mediumImpact();

    try {
      // Save to local storage
      final storageService = NutritionStorageService();
      await storageService.logFood(_nutritionInfo!);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Logged ${_nutritionInfo!.foodName} - ${_nutritionInfo!.calories.toInt()} cal',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to dashboard
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home-dashboard-screen');
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log food: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Food Nutrition',
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(theme)
          : _errorMessage != null
              ? _buildErrorState(theme)
              : _buildNutritionContent(theme),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 3.h),
          Text(
            'Analyzing nutrition...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: theme.colorScheme.error,
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              'Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionContent(ThemeData theme) {
    if (_nutritionInfo == null) return const SizedBox();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 4.w,
            right: 4.w,
            top: 2.h,
            bottom: 15.h, // Space for log button
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image
              if (_imagePath != null) _buildFoodImage(theme),

              SizedBox(height: 3.h),

              // Food Name
              Text(
                _nutritionInfo!.foodName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 1.h),

              // Serving Size
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'restaurant',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _nutritionInfo!.servingSize,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Calories Card
              _buildCaloriesCard(theme),

              SizedBox(height: 2.h),

              // Macros Card
              _buildMacrosCard(theme),

              SizedBox(height: 2.h),

              // Additional Nutrition Details
              _buildDetailsCard(theme),

              if (_nutritionInfo!.ingredients.isNotEmpty) ...[
                SizedBox(height: 2.h),
                _buildIngredientsCard(theme),
              ],
            ],
          ),
        ),

        // Log Button at Bottom
        Positioned(
          left: 4.w,
          right: 4.w,
          bottom: 3.h,
          child: Container(
            height: 6.5.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50),
                width: 2,
              ),
            ),
            child: ElevatedButton(
              onPressed: _logFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'add_circle',
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Log Food',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodImage(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 30.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Image.file(
          File(_imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: CustomIconWidget(
                iconName: 'image_not_supported',
                color: theme.colorScheme.onSurfaceVariant,
                size: 48,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaloriesCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            Text(
              'Calories',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _nutritionInfo!.calories.toInt().toString(),
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'kcal',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macronutrients',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildMacroRow(
              theme,
              'Protein',
              _nutritionInfo!.protein,
              'g',
              const Color(0xFFE91E63),
              _nutritionInfo!.proteinPercentage,
            ),
            SizedBox(height: 2.h),
            _buildMacroRow(
              theme,
              'Carbs',
              _nutritionInfo!.carbs,
              'g',
              const Color(0xFF2196F3),
              _nutritionInfo!.carbsPercentage,
            ),
            SizedBox(height: 2.h),
            _buildMacroRow(
              theme,
              'Fat',
              _nutritionInfo!.fat,
              'g',
              const Color(0xFFFF9800),
              _nutritionInfo!.fatPercentage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    ThemeData theme,
    String label,
    double value,
    String unit,
    Color color,
    double percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(theme, 'Fiber', _nutritionInfo!.fiber, 'g'),
            Divider(height: 3.h),
            _buildDetailRow(theme, 'Sugar', _nutritionInfo!.sugar, 'g'),
            Divider(height: 3.h),
            _buildDetailRow(theme, 'Sodium', _nutritionInfo!.sodium, 'mg'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    double value,
    String unit,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge,
        ),
        Text(
          '${value.toStringAsFixed(1)}$unit',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredients',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _nutritionInfo!.ingredients.map((ingredient) {
                return Chip(
                  label: Text(ingredient),
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
