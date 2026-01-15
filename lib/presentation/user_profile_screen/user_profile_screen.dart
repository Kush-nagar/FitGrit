import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../theme/theme_provider.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/account_section_widget.dart';
import './widgets/app_settings_section_widget.dart';
import './widgets/goals_section_widget.dart';
import './widgets/preferences_section_widget.dart';
import './widgets/privacy_section_widget.dart';
import './widgets/profile_header_widget.dart';
import '../../services/onboarding_service.dart';
import '../../models/user_onboarding_model.dart';

/// User Profile Screen - Manages personal settings and app preferences
///
/// Features:
/// - User avatar with edit functionality
/// - Account information (age, height, weight)
/// - Goals management (calorie, water, weight targets)
/// - Dietary preferences toggles
/// - App settings (notifications, units, theme)
/// - Privacy and security options
/// - Logout functionality
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  UserOnboardingModel? _onboardingData;
  bool _isLoading = true;

  // User profile data
  final Map<String, dynamic> _userData = {
    "name": "User",
    "avatar":
        "https://img.freepik.com/premium-vector/young-man-avatar-character_24877-9475.jpg",
    "avatarSemanticLabel":
        "Profile photo of a man with short hair and a friendly smile.",
    "currentStreak": 12,
    "age": 28,
    "height": "5'6\"",
    "weight": "145 lbs",
    "calorieTarget": 2000,
    "waterIntakeGoal": 2.5,
    "weightGoal": "Maintain current weight",
  };

  // Dietary preferences
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isGlutenFree = true;
  bool _isDairyFree = false;
  bool _isNutFree = false;

  // App settings
  bool _notificationsEnabled = true;
  bool _useMetricUnits = false;
  String _selectedTheme = "Dark";

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    try {
      final data = await _onboardingService.getOnboardingData();
      if (mounted) {
        setState(() {
          _onboardingData = data;
          _isLoading = false;

          // Update user data with onboarding data if available
          if (data != null) {
            _userData['name'] = data.name;
            _userData['age'] = data.age;
            _userData['height'] = '${data.heightCm.toInt()} cm';
            _userData['weight'] = '${data.weightKg.toStringAsFixed(1)} kg';
            _userData['calorieTarget'] = data.recommendedDailyCalories ?? 2000;
            _userData['waterIntakeGoal'] =
                (data.recommendedWaterIntakeGlasses ?? 8) *
                    0.25; // Convert glasses to liters

            // Set weight goal based on overall goal
            switch (data.overallGoal) {
              case OverallGoal.loseWeight:
                _userData['weightGoal'] = 'Lose Weight';
                break;
              case OverallGoal.gainMuscle:
                _userData['weightGoal'] = 'Gain Muscle';
                break;
              case OverallGoal.maintain:
                _userData['weightGoal'] = 'Maintain Weight';
                break;
              case OverallGoal.mentalWellbeing:
                _userData['weightGoal'] = 'Focus on Wellbeing';
                break;
            }

            // Update dietary preferences based on onboarding
            if (data.dietType != null) {
              _isVegetarian = data.dietType == DietType.vegetarian;
              _isVegan = data.dietType == DietType.vegan;
              _isGlutenFree = data.dietType == DietType.glutenFree;
              _isDairyFree = data.dietType == DietType.dairyFree;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading onboarding data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update system UI based on current theme
    _updateSystemUIOverlay();

    // Sync the selected theme with the current theme mode
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      switch (themeProvider.themeMode) {
        case ThemeMode.dark:
          _selectedTheme = 'Dark';
          break;
        case ThemeMode.light:
          _selectedTheme = 'Light';
          break;
        case ThemeMode.system:
          _selectedTheme = 'System';
          break;
      }
    });
  }

  void _updateSystemUIOverlay() {
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: brightness,
      ),
    );
  }

  void _showEditBottomSheet({
    required String title,
    required String currentValue,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 4.w,
          right: 4.w,
          top: 2.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit $title',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              autofocus: true,
              decoration: InputDecoration(
                labelText: title,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSave(controller.text);
                      Navigator.pop(context);
                      _showSuccessSnackBar('$title updated successfully');
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              isDangerous ? 'Delete' : 'Confirm',
              style: TextStyle(
                color: isDangerous ? theme.colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAvatarTap() {
    _showSuccessSnackBar('Avatar edit functionality coming soon');
  }

  void _handleEditAge() {
    _showEditBottomSheet(
      title: 'Age',
      currentValue: _userData["age"].toString(),
      keyboardType: TextInputType.number,
      onSave: (value) {
        setState(() {
          _userData["age"] = int.tryParse(value) ?? _userData["age"];
        });
      },
    );
  }

  void _handleEditHeight() {
    _showEditBottomSheet(
      title: 'Height',
      currentValue: _userData["height"] as String,
      onSave: (value) {
        setState(() {
          _userData["height"] = value;
        });
      },
    );
  }

  void _handleEditWeight() {
    _showEditBottomSheet(
      title: 'Weight',
      currentValue: _userData["weight"] as String,
      onSave: (value) {
        setState(() {
          _userData["weight"] = value;
        });
      },
    );
  }

  void _handleEditCalorieTarget() {
    _showEditBottomSheet(
      title: 'Calorie Target',
      currentValue: _userData["calorieTarget"].toString(),
      keyboardType: TextInputType.number,
      onSave: (value) {
        setState(() {
          _userData["calorieTarget"] =
              int.tryParse(value) ?? _userData["calorieTarget"];
        });
      },
    );
  }

  void _handleEditWaterGoal() {
    _showEditBottomSheet(
      title: 'Water Intake Goal (L)',
      currentValue: _userData["waterIntakeGoal"].toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSave: (value) {
        setState(() {
          _userData["waterIntakeGoal"] =
              double.tryParse(value) ?? _userData["waterIntakeGoal"];
        });
      },
    );
  }

  void _handleEditWeightGoal() {
    _showEditBottomSheet(
      title: 'Weight Goal',
      currentValue: _userData["weightGoal"] as String,
      onSave: (value) {
        setState(() {
          _userData["weightGoal"] = value;
        });
      },
    );
  }

  void _handleThemePressed() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ...[
              'Dark',
              'Light',
              'System'
            ].map((themeOption) => RadioListTile<String>(
                  title: Text(themeOption),
                  value: themeOption,
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    if (!mounted) return;

                    setState(() {
                      _selectedTheme = value ?? 'Dark';
                    });

                    // Update the actual theme
                    ThemeMode newMode;
                    if (value == 'Dark') {
                      newMode = ThemeMode.dark;
                    } else if (value == 'Light') {
                      newMode = ThemeMode.light;
                    } else {
                      newMode = ThemeMode.system;
                    }

                    // Close the bottom sheet first
                    Navigator.pop(context);

                    // Update theme and show snackbar after the bottom sheet animation completes
                    Future.microtask(() async {
                      await themeProvider.setThemeMode(newMode);

                      // Wait for the next frame to ensure the new context is ready
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Theme changed to $themeOption'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        });
                      }
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _handleExportData() {
    _showSuccessSnackBar('Data export initiated. Check your email.');
  }

  void _handlePrivacyPolicy() {
    _showSuccessSnackBar('Opening privacy policy...');
  }

  void _handleDeleteAccount() {
    _showConfirmationDialog(
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? This action cannot be undone.',
      isDangerous: true,
      onConfirm: () {
        _showSuccessSnackBar('Account deletion request submitted');
      },
    );
  }

  void _handleLogout() {
    _showConfirmationDialog(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      onConfirm: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home-dashboard-screen',
          (route) => false,
        );
      },
    );
  }

  Widget _buildOnboardingInfoSection() {
    final theme = Theme.of(context);
    final data = _onboardingData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Gender',
                  data.gender[0].toUpperCase() + data.gender.substring(1)),
              _buildDivider(),
              _buildInfoRow('Age', '${data.age} years'),
              _buildDivider(),
              _buildInfoRow('Height', '${data.heightCm.toInt()} cm'),
              _buildDivider(),
              _buildInfoRow('Weight', '${data.weightKg.toStringAsFixed(1)} kg'),
              _buildDivider(),
              _buildInfoRow('Birthdate',
                  DateFormat('MMM dd, yyyy').format(data.birthdate)),
              _buildDivider(),
              _buildInfoRow('Overall Goal', _getGoalString(data.overallGoal)),
              _buildDivider(),
              _buildInfoRow(
                  'Time Horizon', _getTimeHorizonString(data.timeHorizon)),
              _buildDivider(),
              _buildInfoRow('Activity Level',
                  _getActivityLevelString(data.activityLevel)),
              if (data.personType == PersonType.sportsPlayer) ...[
                _buildDivider(),
                _buildInfoRow('Person Type', 'Sports Player'),
                if (data.sport != null && data.sport!.isNotEmpty) ...[
                  _buildDivider(),
                  _buildInfoRow('Sport', data.sport!),
                ],
              ],
              if (data.exercisePreferences.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('Exercise Preferences',
                    data.exercisePreferences.join(', ')),
              ],
              if (data.equipment.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('Equipment', data.equipment.join(', ')),
              ],
              if (data.dietType != null && data.dietType != DietType.none) ...[
                _buildDivider(),
                _buildInfoRow('Diet Type', _getDietTypeString(data.dietType!)),
              ],
              if (data.allergies.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('Allergies', data.allergies.join(', '),
                    isWarning: true),
              ],
              if (data.dislikes.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow('Dislikes', data.dislikes.join(', ')),
              ],
            ],
          ),
        ),
        if (data.recommendedDailyCalories != null ||
            data.recommendedWaterIntakeGlasses != null) ...[
          SizedBox(height: 2.h),
          Text(
            'Goals & AI Recommendations',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (data.recommendedDailyCalories != null) ...[
                  _buildInfoRow(
                    'Daily Calorie Goal',
                    '${data.recommendedDailyCalories} cal',
                    icon: Icons.local_fire_department,
                  ),
                ],
                if (data.recommendedDailyCalories != null &&
                    data.recommendedWaterIntakeGlasses != null)
                  _buildDivider(),
                if (data.recommendedWaterIntakeGlasses != null) ...[
                  _buildInfoRow(
                    'Water Intake Goal',
                    '${data.recommendedWaterIntakeGlasses} glasses (${(data.recommendedWaterIntakeGlasses! * 0.25).toStringAsFixed(1)}L)',
                    icon: Icons.water_drop,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isWarning = false, IconData? icon}) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 2.w),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isWarning ? theme.colorScheme.error : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: const Divider(height: 1),
    );
  }

  String _getGoalString(OverallGoal goal) {
    switch (goal) {
      case OverallGoal.loseWeight:
        return 'Lose Weight';
      case OverallGoal.gainMuscle:
        return 'Gain Muscle';
      case OverallGoal.maintain:
        return 'Maintain Weight';
      case OverallGoal.mentalWellbeing:
        return 'Mental Wellbeing';
    }
  }

  String _getTimeHorizonString(TimeHorizon horizon) {
    switch (horizon) {
      case TimeHorizon.oneMonth:
        return '1 Month';
      case TimeHorizon.threeMonths:
        return '3 Months';
      case TimeHorizon.sixMonths:
        return '6 Months';
      case TimeHorizon.oneYear:
        return '1 Year';
      case TimeHorizon.longTerm:
        return 'Long Term (1+ years)';
    }
  }

  String _getActivityLevelString(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  String _getDietTypeString(DietType diet) {
    switch (diet) {
      case DietType.none:
        return 'None';
      case DietType.vegetarian:
        return 'Vegetarian';
      case DietType.vegan:
        return 'Vegan';
      case DietType.keto:
        return 'Ketogenic';
      case DietType.paleo:
        return 'Paleo';
      case DietType.mediterranean:
        return 'Mediterranean';
      case DietType.lowCarb:
        return 'Low Carb';
      case DietType.lowFat:
        return 'Low Fat';
      case DietType.glutenFree:
        return 'Gluten Free';
      case DietType.dairyFree:
        return 'Dairy Free';
      case DietType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              ProfileHeaderWidget(
                userName: _userData["name"] as String,
                userAvatar: _userData["avatar"] as String,
                avatarSemanticLabel: _userData["avatarSemanticLabel"] as String,
                currentStreak: _userData["currentStreak"] as int,
                onAvatarTap: _handleAvatarTap,
              ),
              SizedBox(height: 3.h),

              // Onboarding Information (if available)
              if (_onboardingData != null) ...[
                _buildOnboardingInfoSection(),
                SizedBox(height: 3.h),
              ],

              // Dietary Preferences
              PreferencesSectionWidget(
                isVegetarian: _isVegetarian,
                isVegan: _isVegan,
                isGlutenFree: _isGlutenFree,
                isDairyFree: _isDairyFree,
                isNutFree: _isNutFree,
                onVegetarianChanged: (value) =>
                    setState(() => _isVegetarian = value),
                onVeganChanged: (value) => setState(() => _isVegan = value),
                onGlutenFreeChanged: (value) =>
                    setState(() => _isGlutenFree = value),
                onDairyFreeChanged: (value) =>
                    setState(() => _isDairyFree = value),
                onNutFreeChanged: (value) => setState(() => _isNutFree = value),
              ),
              SizedBox(height: 3.h),

              // App Settings
              AppSettingsSectionWidget(
                notificationsEnabled: _notificationsEnabled,
                useMetricUnits: _useMetricUnits,
                selectedTheme: _selectedTheme,
                onNotificationsChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
                onUnitsChanged: (value) =>
                    setState(() => _useMetricUnits = value),
                onThemePressed: _handleThemePressed,
              ),
              SizedBox(height: 3.h),

              // Privacy & Security
              PrivacySectionWidget(
                onExportData: _handleExportData,
                onPrivacyPolicy: _handlePrivacyPolicy,
                onDeleteAccount: _handleDeleteAccount,
              ),
              SizedBox(height: 3.h),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                  child: Text(
                    'Logout',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // App Version
              Center(
                child: Text(
                  'FitGrit AI v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/user-profile-screen',
        onNavigate: (route) {
          if (route != '/user-profile-screen') {
            if (route == '/home-dashboard-screen') {
              // Pop back to home since profile is pushed on top of home
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, route);
            }
          }
        },
      ),
    );
  }
}
