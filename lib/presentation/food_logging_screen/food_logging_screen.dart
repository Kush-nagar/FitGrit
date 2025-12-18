import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../core/models/nutrition_info.dart';
import '../../services/gemini_service.dart';
import '../../services/firebase_nutrition_service.dart';
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
    if (_nutritionInfo == null) {
      debugPrint('Cannot log food: nutritionInfo is null');
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      // Save to Firebase
      final firebaseService = FirebaseNutritionService();
      debugPrint('Logging food: ${_nutritionInfo!.foodName}');
      debugPrint('Nutrition data: ${_nutritionInfo!.toJson()}');

      await firebaseService.logFood(nutritionInfo: _nutritionInfo!);

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

      // Wait a bit longer to ensure Firestore write is complete
      // Navigate back to dashboard with refresh flag
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/home-dashboard-screen',
          arguments: {'shouldRefresh': true},
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error logging food: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      // Check if it's a permission error
      final errorMessage = e.toString();
      String userMessage = 'Failed to log food';
      String? actionLabel;
      VoidCallback? action;

      if (errorMessage.contains('permission-denied') ||
          errorMessage.contains('PERMISSION_DENIED')) {
        userMessage = '🔒 Permission denied. Update Firestore security rules.';
        actionLabel = 'Help';
        action = () => _showSecurityRulesDialog();
      } else if (errorMessage.contains('NOT_FOUND') ||
          errorMessage.contains('does not exist')) {
        userMessage = '⚠️ Firestore not set up. Create database first.';
        actionLabel = 'Help';
        action = () => _showSecurityRulesDialog();
      } else if (errorMessage.contains('unknown') &&
          errorMessage.contains('null')) {
        userMessage =
            '⚠️ Firebase connection issue. Check internet or update security rules.';
        actionLabel = 'Help';
        action = () => _showSecurityRulesDialog();
      } else {
        userMessage =
            'Failed to log food: ${errorMessage.length > 60 ? errorMessage.substring(0, 60) + '...' : errorMessage}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: action != null && actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: action,
                )
              : null,
        ),
      );
    }
  }

  void _showSecurityRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.security,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 2.w),
            const Text('Update Security Rules'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Firestore security rules need to be updated:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              const Text('1. Go to Firebase Console'),
              const Text('2. Select "Firestore Database" → "Rules" tab'),
              const Text('3. Replace the rules with the code below'),
              const Text('4. Click "Publish"'),
              SizedBox(height: 2.h),
              const Text(
                'Test Mode Rules (allows all read/write for 30 days):',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  '''rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if
        request.time < timestamp.date(2026, 1, 17);
    }
  }
}''',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Console link:\nhttps://console.firebase.google.com/project/presapp-97031/firestore/rules',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      'Note: These rules are for testing only. Add proper authentication before production.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logFood();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
