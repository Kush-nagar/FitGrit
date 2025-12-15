import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../theme/theme_provider.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/account_section_widget.dart';
import './widgets/app_settings_section_widget.dart';
import './widgets/goals_section_widget.dart';
import './widgets/preferences_section_widget.dart';
import './widgets/privacy_section_widget.dart';
import './widgets/profile_header_widget.dart';

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
  // User profile data
  final Map<String, dynamic> _userData = {
    "name": "Sarah Johnson",
    "avatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_122f6d06e-1764690565988.png",
    "avatarSemanticLabel":
        "Profile photo of a woman with long brown hair and a warm smile, wearing a light blue top against a neutral background.",
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
        automaticallyImplyLeading: false,
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

              // Account Information
              AccountSectionWidget(
                age: _userData["age"] as int,
                height: _userData["height"] as String,
                weight: _userData["weight"] as String,
                onEditAge: _handleEditAge,
                onEditHeight: _handleEditHeight,
                onEditWeight: _handleEditWeight,
              ),
              SizedBox(height: 3.h),

              // Goals
              GoalsSectionWidget(
                calorieTarget: _userData["calorieTarget"] as int,
                waterIntakeGoal: _userData["waterIntakeGoal"] as double,
                weightGoal: _userData["weightGoal"] as String,
                onEditCalorieTarget: _handleEditCalorieTarget,
                onEditWaterGoal: _handleEditWaterGoal,
                onEditWeightGoal: _handleEditWeightGoal,
              ),
              SizedBox(height: 3.h),

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
                  'NutriScan v1.0.0',
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
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
