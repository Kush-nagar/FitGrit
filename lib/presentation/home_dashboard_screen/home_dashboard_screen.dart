import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  int _currentCalories = 1450;
  final int _targetCalories = 2000;
  int _currentWaterGlasses = 5;
  final int _targetWaterGlasses = 8;

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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _recentMeals = [
    {
      "id": 1,
      "name": "Grilled Chicken Salad",
      "image": "https://images.unsplash.com/photo-1662805523107-ce4d7486bb0b",
      "semanticLabel":
          "Fresh green salad with grilled chicken breast, cherry tomatoes, and mixed greens in a white bowl",
      "calories": 350,
      "mealType": "Lunch",
      "time": "12:30 PM",
    },
    {
      "id": 2,
      "name": "Oatmeal with Berries",
      "image": "https://images.unsplash.com/photo-1624581779023-1cedd60ed853",
      "semanticLabel":
          "Bowl of creamy oatmeal topped with fresh blueberries, strawberries, and sliced almonds",
      "calories": 280,
      "mealType": "Breakfast",
      "time": "8:00 AM",
    },
    {
      "id": 3,
      "name": "Protein Smoothie",
      "image": "https://images.unsplash.com/photo-1494314750614-5bf0ee7eb057",
      "semanticLabel":
          "Purple berry smoothie in a clear glass with a straw, topped with fresh berries",
      "calories": 220,
      "mealType": "Snack",
      "time": "3:15 PM",
    },
    {
      "id": 4,
      "name": "Avocado Toast",
      "image": "https://images.unsplash.com/photo-1725190595986-8a104475d742",
      "semanticLabel":
          "Whole grain toast topped with mashed avocado, cherry tomatoes, and sesame seeds on a white plate",
      "calories": 320,
      "mealType": "Breakfast",
      "time": "7:45 AM",
    },
    {
      "id": 5,
      "name": "Greek Yogurt Parfait",
      "image": "https://images.unsplash.com/photo-1691455653742-ea1aded33376",
      "semanticLabel":
          "Layered parfait with Greek yogurt, granola, and mixed berries in a clear glass",
      "calories": 280,
      "mealType": "Snack",
      "time": "10:30 AM",
    },
  ];

  void _handleAddWater() {
    if (_currentWaterGlasses < _targetWaterGlasses) {
      setState(() {
        _currentWaterGlasses++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Water glass added! $_currentWaterGlasses/$_targetWaterGlasses'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily water goal achieved! 🎉'),
          duration: Duration(seconds: 2),
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

  void _handleDeleteMeal(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete ${meal['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _recentMeals.removeWhere((m) => m['id'] == meal['id']);
                _currentCalories -= (meal['calories'] as int);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meal deleted successfully'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
              onPressed: () => _selectDate(context),
              icon: CustomIconWidget(
                iconName: 'calendar_today',
                color: theme.colorScheme.primary,
                size: 22,
              ),
              tooltip: 'Select date',
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
                  // Modern date header with gradient
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
                        Icon(
                          Icons.chevron_right_rounded,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.6),
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
                    child: RecentMealsSectionWidget(
                      meals: _recentMeals,
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
