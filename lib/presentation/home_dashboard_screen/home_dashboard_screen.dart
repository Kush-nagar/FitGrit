import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/firebase_nutrition_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/daily_calorie_card_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/recent_meals_section_widget.dart';
import './widgets/water_intake_card_widget.dart';

/// Home Dashboard Screen
///
/// Central nutrition tracking hub with daily progress overview
/// Features: calorie tracking, water intake, recent meals, quick actions
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  int _currentCalories = 0;
  int _targetCalories = 2000;
  double _currentProtein = 0;
  double _currentCarbs = 0;
  double _currentFat = 0;
  int _currentWaterGlasses = 0;
  int _targetWaterGlasses = 8;
  List<Map<String, dynamic>> _loggedFoods = [];
  bool _isLoading = true;

  final FirebaseNutritionService _firebaseService = FirebaseNutritionService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should refresh data (e.g., after logging food)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['shouldRefresh'] == true) {
      _loadDailyData();
    } else if (_isLoading) {
      // First load
      _loadDailyData();
    }
  }

  /// Load daily nutrition and water data from Firebase for selected date
  Future<void> _loadDailyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load nutrition data for selected date from Firebase
      final totals = await _firebaseService.getDailyTotals(date: _selectedDate);
      final goals = await _firebaseService.getDailyGoals();
      final foods = await _firebaseService.getLoggedFoods(date: _selectedDate);

      setState(() {
        _currentCalories = totals['calories']?.toInt() ?? 0;
        _targetCalories = goals['targetCalories']?.toInt() ?? 2000;
        _currentProtein = totals['protein'] ?? 0;
        _currentCarbs = totals['carbs'] ?? 0;
        _currentFat = totals['fat'] ?? 0;
        _currentWaterGlasses = totals['waterGlasses'] ?? 0;
        _targetWaterGlasses = goals['targetWaterGlasses'] ?? 8;
        _loggedFoods = foods;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading daily data: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Check if it's a Firestore setup issue
        final errorMessage = e.toString();
        String userFriendlyMessage = 'Error loading data';
        String? actionLabel;
        VoidCallback? action;

        if (errorMessage.contains('NOT_FOUND') ||
            errorMessage.contains('does not exist')) {
          userFriendlyMessage =
              '⚠️ Firestore database not set up. Please create it in Firebase Console.';
          actionLabel = 'Instructions';
          action = () => _showFirestoreSetupDialog();
        } else if (errorMessage.contains('unavailable') ||
            errorMessage.contains('UNAVAILABLE')) {
          userFriendlyMessage =
              '📡 Firestore is unavailable. Check your internet connection and Firebase setup.';
          actionLabel = 'Retry';
          action = () => _loadDailyData();
        } else if (errorMessage.contains('permission-denied') ||
            errorMessage.contains('PERMISSION_DENIED')) {
          userFriendlyMessage =
              '🔒 Permission denied. Please update Firestore security rules.';
          actionLabel = 'Show Rules';
          action = () => _showSecurityRulesDialog();
        } else {
          userFriendlyMessage = 'Error: ${e.toString().substring(0, 100)}...';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyMessage),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: action != null && actionLabel != null
                ? SnackBarAction(
                    label: actionLabel,
                    onPressed: action,
                  )
                : null,
          ),
        );
      }
    }
  }

  void _showFirestoreSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.cloud_off,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(width: 2.w),
            const Text('Firestore Setup Required'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Firebase Firestore database needs to be set up:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              const Text('1. Go to Firebase Console'),
              const Text('2. Select your project (presapp-97031)'),
              const Text('3. Go to "Build" → "Firestore Database"'),
              const Text('4. Click "Create Database"'),
              const Text('5. Choose "Test mode" for now'),
              const Text('6. Select your region'),
              const Text('7. Wait for initialization'),
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
                  'Quick link:\nhttps://console.firebase.google.com/project/presapp-97031/firestore',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
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
              _loadDailyData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
              _loadDailyData();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAddWater() async {
    try {
      await _firebaseService.addWaterGlass(date: _selectedDate);

      // Reload data to reflect changes
      await _loadDailyData();

      if (!mounted) return;

      if (_currentWaterGlasses >= _targetWaterGlasses) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily water goal achieved! 🎉'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Water glass added! $_currentWaterGlasses/$_targetWaterGlasses'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding water: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleLogMeal() {
    Navigator.pushNamed(context, '/camera-scan-screen');
  }

  void _handleViewGoals() {
    Navigator.pushNamed(context, '/user-profile-screen');
  }

  void _handleMealTap(Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMealDetailsSheet(meal),
    );
  }

  void _handleEditMeal(Map<String, dynamic> meal) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit meal: ${meal['name']}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDeleteMeal(Map<String, dynamic> meal) async {
    // Find the index of the meal in logged foods
    final index = _loggedFoods.indexWhere(
        (m) => m['foodName'] == meal['foodName'] || m['name'] == meal['name']);

    if (index == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal not found'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text(
            'Are you sure you want to delete ${meal['name'] ?? meal['foodName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _firebaseService.deleteFood(
                  index: index,
                  date: _selectedDate,
                );

                // Reload data
                await _loadDailyData();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meal deleted successfully'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting meal: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealDetailsSheet(Map<String, dynamic> meal) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(5.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomImageWidget(
              imageUrl: meal['image'] as String,
              width: double.infinity,
              height: 25.h,
              fit: BoxFit.cover,
              semanticLabel: meal['semanticLabel'] as String,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            meal['name'] as String,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'schedule',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                meal['time'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  meal['mealType'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientInfo(
                  context,
                  'Calories',
                  '${meal['calories']}',
                  'local_fire_department',
                  theme.colorScheme.error,
                ),
                Container(
                  width: 1,
                  height: 5.h,
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                _buildNutrientInfo(
                  context,
                  'Protein',
                  '25g',
                  'fitness_center',
                  theme.colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 5.h,
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                _buildNutrientInfo(
                  context,
                  'Carbs',
                  '30g',
                  'grain',
                  theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleEditMeal(meal);
                  },
                  icon: CustomIconWidget(
                    iconName: 'edit',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  label: const Text('Edit'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleDeleteMeal(meal);
                  },
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildNutrientInfo(
    BuildContext context,
    String label,
    String value,
    String icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: color,
          size: 24,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Reload data for the new date
      await _loadDailyData();
    }
  }

  /// Navigate to previous day
  Future<void> _goToPreviousDay() async {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    await _loadDailyData();
  }

  /// Navigate to next day
  Future<void> _goToNextDay() async {
    final tomorrow = _selectedDate.add(const Duration(days: 1));
    if (tomorrow.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      setState(() {
        _selectedDate = tomorrow;
      });
      await _loadDailyData();
    }
  }

  Widget _buildAnimatedCard({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'NutriScan',
        centerTitle: false,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 2.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/fitness-screen'),
              icon: CustomIconWidget(
                iconName: 'fitness_center',
                color: theme.colorScheme.primary,
                size: 22,
              ),
              tooltip: 'Fitness',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              _animationController.reset();
              _animationController.forward();
              await Future.delayed(const Duration(milliseconds: 600));
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern date header with navigation
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                          theme.colorScheme.primary.withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Previous day button
                        IconButton(
                          onPressed: _goToPreviousDay,
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Previous day',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: 2.w),

                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomIconWidget(
                            iconName: 'calendar_today',
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE').format(_selectedDate),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                DateFormat('MMMM d, y').format(_selectedDate),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Next day button (disabled if today)
                        IconButton(
                          onPressed: _selectedDate.day == DateTime.now().day &&
                                  _selectedDate.month == DateTime.now().month &&
                                  _selectedDate.year == DateTime.now().year
                              ? null
                              : _goToNextDay,
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: _selectedDate.day == DateTime.now().day &&
                                    _selectedDate.month ==
                                        DateTime.now().month &&
                                    _selectedDate.year == DateTime.now().year
                                ? theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3)
                                : theme.colorScheme.primary,
                          ),
                          tooltip: 'Next day',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Animated Cards with stagger
                  _buildAnimatedCard(
                    delay: 0,
                    child: DailyCalorieCardWidget(
                      currentCalories: _currentCalories,
                      targetCalories: _targetCalories,
                      currentProtein: _currentProtein,
                      currentCarbs: _currentCarbs,
                      currentFat: _currentFat,
                      onTap: () => Navigator.pushNamed(
                          context, '/food-log-history-screen'),
                    ),
                  ),

                  _buildAnimatedCard(
                    delay: 100,
                    child: WaterIntakeCardWidget(
                      currentGlasses: _currentWaterGlasses,
                      targetGlasses: _targetWaterGlasses,
                      onAddGlass: _handleAddWater,
                      onTap: () =>
                          Navigator.pushNamed(context, '/user-profile-screen'),
                    ),
                  ),

                  SizedBox(height: 1.h),

                  _buildAnimatedCard(
                    delay: 200,
                    child: _isLoading
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(4.h),
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : RecentMealsSectionWidget(
                            meals: _loggedFoods.map((food) {
                              return {
                                'id': food['id'] ??
                                    DateTime.now().millisecondsSinceEpoch,
                                'name': food['foodName'] ??
                                    food['name'] ??
                                    'Unknown',
                                'foodName': food['foodName'] ??
                                    food['name'] ??
                                    'Unknown',
                                'calories': (food['calories'] ?? 0).toInt(),
                                'protein': (food['protein'] ?? 0).toDouble(),
                                'carbs': (food['carbs'] ?? 0).toDouble(),
                                'fat': (food['fat'] ?? 0).toDouble(),
                                'mealType': 'Logged',
                                'time': food['timestamp'] != null
                                    ? DateFormat('h:mm a').format(
                                        DateTime.parse(food['timestamp']),
                                      )
                                    : 'N/A',
                                'image':
                                    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                                'semanticLabel':
                                    'Food item: ${food['foodName'] ?? food['name']}',
                              };
                            }).toList(),
                            onMealTap: _handleMealTap,
                            onEditMeal: _handleEditMeal,
                            onDeleteMeal: _handleDeleteMeal,
                          ),
                  ),

                  SizedBox(height: 1.h),

                  _buildAnimatedCard(
                    delay: 300,
                    child: QuickActionsWidget(
                      onAddWater: _handleAddWater,
                      onLogMeal: _handleLogMeal,
                      onViewGoals: _handleViewGoals,
                    ),
                  ),

                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 24,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.heavyImpact();
              Navigator.pushNamed(context, '/camera-scan-screen');
            },
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withValues(alpha: 0.3),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Scan Food',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/home-dashboard-screen',
        onNavigate: (route) {
          if (route != '/home-dashboard-screen') {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}
