import 'package:flutter/material.dart';
import '../presentation/food_log_history_screen/food_log_history_screen.dart';
import '../presentation/recipe_suggestions_screen/recipe_suggestions_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/camera_scan_screen/camera_scan_screen.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String foodLogHistory = '/food-log-history-screen';
  static const String recipeSuggestions = '/recipe-suggestions-screen';
  static const String userProfile = '/user-profile-screen';
  static const String cameraScan = '/camera-scan-screen';
  static const String homeDashboard = '/home-dashboard-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeDashboardScreen(),
    foodLogHistory: (context) => const FoodLogHistoryScreen(),
    recipeSuggestions: (context) => const RecipeSuggestionsScreen(),
    userProfile: (context) => const UserProfileScreen(),
    cameraScan: (context) => const CameraScanScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    // TODO: Add your other routes here
  };
}
