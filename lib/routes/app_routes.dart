import 'package:flutter/material.dart';
import '../presentation/food_log_history_screen/food_log_history_screen.dart';
import '../presentation/recipe_suggestions_screen/recipe_suggestions_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/camera_scan_screen/camera_scan_screen.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';
import '../presentation/recognition_results_screen/recognition_results_screen.dart';
import '../presentation/food_logging_screen/food_logging_screen.dart';
import '../presentation/fitness_screen/fitness_screen.dart';
import '../presentation/recipes_screen/recipes_screen.dart';
import '../presentation/recipe_details_screen/recipe_details_screen.dart';
import '../presentation/running_history_screen/running_history_screen.dart';
import '../presentation/running_details_screen/running_details_screen.dart';
import '../presentation/wellness_screen/wellness_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/onboarding_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String foodLogHistory = '/food-log-history-screen';
  static const String recipeSuggestions = '/recipe-suggestions-screen';
  static const String userProfile = '/user-profile-screen';
  static const String cameraScan = '/camera-scan-screen';
  static const String homeDashboard = '/home-dashboard-screen';
  static const String recognitionResults = '/recognition-results-screen';
  static const String foodLogging = '/food-logging-screen';
  static const String fitness = '/fitness-screen';
  static const String recipes = '/recipes-screen';
  static const String recipeDetails = '/recipe-details-screen';
  static const String runningHistory = '/running-history-screen';
  static const String runningDetails = '/running-details-screen';
  static const String wellness = '/wellness-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    foodLogHistory: (context) => const FoodLogHistoryScreen(),
    recipeSuggestions: (context) => const RecipeSuggestionsScreen(),
    userProfile: (context) => const UserProfileScreen(),
    cameraScan: (context) => const CameraScanScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    recognitionResults: (context) => const RecognitionResultsScreen(),
    foodLogging: (context) => const FoodLoggingScreen(),
    fitness: (context) => const FitnessScreen(),
    recipes: (context) => const RecipesScreen(),
    recipeDetails: (context) => const RecipeDetailsScreen(),
    runningHistory: (context) => const RunningHistoryScreen(),
    runningDetails: (context) => const RunningDetailsScreen(),
    wellness: (context) => const WellnessScreen(),
    // TODO: Add your other routes here
  };
}
