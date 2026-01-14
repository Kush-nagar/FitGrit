# Onboarding & Splash Screen Feature

## Overview

This feature adds a modern splash screen and comprehensive onboarding flow to the FitGrit AI app. The onboarding collects user information and generates personalized health recommendations using Gemini AI.

## Features

### 1. Splash Screen (`lib/presentation/screens/splash_screen.dart`)

- **Modern & Minimalist Design**: Clean, professional look with smooth animations
- **Animated Elements**:
  - Elastic logo scale animation
  - Pulsing effect on the logo
  - Fade-in transitions
  - Animated background circles with different speeds
- **Smart Navigation**: Automatically checks if user has completed onboarding and navigates accordingly

### 2. Onboarding Flow (`lib/presentation/screens/onboarding_screen.dart`)

A 5-step onboarding process that collects comprehensive user information:

#### Step 1: Account Basics

- **Name** (required): Used for personalization throughout the app

#### Step 2: Basic Profile

- **Birthdate** (required): Used for age calculation and fitness benchmarks
- **Gender** (required): Male, Female, or Other
- **Height** (cm) (required): Used for BMR calculations
- **Weight** (kg) (required): Used for BMR and water intake calculations

#### Step 3: Goals & Priorities

- **Overall Goal** (required):
  - Lose Weight (creates caloric deficit)
  - Gain Muscle (creates caloric surplus)
  - Maintain (maintains TDEE)
  - Mental Wellbeing (focus on overall wellness)
- **Time Horizon** (required): 1 month to long-term (1+ years)
- **Person Type** (required):
  - Regular Person
  - Sports Player (with sport specification)

#### Step 4: Activity & Fitness Baseline

- **Weekly Activity Level** (required):
  - Sedentary
  - Lightly Active (1-3 days/week)
  - Moderately Active (3-5 days/week)
  - Very Active (6-7 days/week)
  - Extremely Active (very hard exercise or physical job)
- **Exercise Preferences** (optional): Running, Cycling, Swimming, Weightlifting, etc.
- **Equipment Available** (optional): Dumbbells, Resistance Bands, Yoga Mat, etc.

#### Step 5: Nutrition Preferences

- **Diet Type** (optional): Vegetarian, Vegan, Keto, Paleo, Mediterranean, etc.
- **Caloric Target Preference**:
  - Automatic (recommended) - calculated by AI
  - Manual - user enters their own target
- **Food Allergies** (optional): Comma-separated list
- **Food Dislikes** (optional): Comma-separated list

### 3. User Onboarding Model (`lib/models/user_onboarding_model.dart`)

Comprehensive data model with:

- All onboarding fields
- JSON serialization/deserialization
- Age calculation from birthdate
- Copy-with method for updates
- Enums for type-safe selections

### 4. Onboarding Service (`lib/services/onboarding_service.dart`)

Handles:

- Saving/loading onboarding data to SharedPreferences
- Checking onboarding completion status
- **Gemini AI Integration**: Sends user profile to Gemini for personalized recommendations
- **Default Calculations**: Falls back to BMR/TDEE calculations if Gemini fails
- Water intake recommendation (based on weight, activity, and sports player status)
- Daily calorie recommendation (based on BMR, activity level, goals, and sports player status)
- Automatic saving to user preferences for Presidential Fitness Test benchmarks

## AI-Powered Recommendations

The service uses Gemini AI to analyze the user's complete profile and provide:

1. **Daily Water Intake Goal** (in glasses)

   - Based on: weight, activity level, sports player status
   - Adjusted for climate and exercise intensity

2. **Daily Calorie Goal**

   - Based on: BMR (age, gender, height, weight), activity level, overall goal
   - Adjusted for sports players (15% increase)
   - Goal-specific adjustments:
     - Weight Loss: 500 calorie deficit
     - Muscle Gain: 300 calorie surplus
     - Maintain/Wellbeing: TDEE maintenance

3. **Macro Targets** (Protein, Carbs, Fat)
   - Automatically calculated based on calorie goal and overall goal
   - Weight Loss: 30% protein, 40% carbs, 30% fat
   - Muscle Gain: 30% protein, 45% carbs, 25% fat
   - Maintain: 25% protein, 45% carbs, 30% fat

## Automatic Updates

### Presidential Fitness Test Benchmarks

The onboarding automatically populates:

- User's age → `UserPreferencesService.saveAge()`
- User's gender → `UserPreferencesService.saveGender()`
- User's name → `UserPreferencesService.saveName()`

This eliminates the need for users to manually enter this information in settings.

### Water Intake Service

- Daily water goal is automatically set based on Gemini recommendations
- Updates `WaterIntakeService.setTargetGlasses()`

### Calorie Tracking

- Daily calorie goal is saved and used throughout the app
- `FirebaseNutritionService.getDailyGoals()` now reads from onboarding data
- Macros are automatically calculated based on the user's goal

## Navigation Flow

```
App Launch
    ↓
Splash Screen (2.5s animations)
    ↓
Has completed onboarding?
    ├── Yes → Home Dashboard
    └── No → Onboarding Flow (5 steps)
            ↓
        Complete Onboarding
            ↓
        Get Gemini Recommendations
            ↓
        Save to Services
            ↓
        Home Dashboard
```

## Routes Updated

- `/` → Splash Screen (initial route)
- `/splash` → Splash Screen
- `/onboarding` → Onboarding Flow
- `/home-dashboard-screen` → Home Dashboard (after onboarding)

## Data Storage

All data is stored locally using SharedPreferences:

- Key: `user_onboarding_data` → JSON string of complete profile
- Key: `onboarding_complete` → Boolean flag
- Key: `target_water_glasses` → Integer (water goal)
- Key: `daily_calorie_goal` → Integer (calorie goal)

## Fallback Behavior

If Gemini API fails or is unavailable:

1. Uses default BMR/TDEE calculations (Mifflin-St Jeor Equation)
2. Applies activity multipliers
3. Adjusts for goals and sports player status
4. Provides sensible defaults for water intake (33ml per kg body weight)

## Usage Instructions

### First Time Users

1. App launches with animated splash screen
2. User is automatically directed to onboarding
3. Complete all 5 steps
4. Recommendations are generated
5. User is taken to home dashboard with personalized goals

### Returning Users

1. App launches with splash screen
2. Automatically navigates to home dashboard
3. Personalized goals are loaded from saved data

### Re-onboarding (Testing)

To test onboarding again, clear app data or use:

```dart
final onboardingService = OnboardingService();
await onboardingService.clearOnboardingData();
```

## Technical Details

### Dependencies Used

- `shared_preferences`: Data persistence
- `intl`: Date formatting
- `flutter/material`: UI components
- Existing Gemini service integration

### Animation Details

- Logo scale: 1200ms elastic animation
- Pulse effect: 1500ms repeating ease-in-out
- Fade transitions: 800ms ease-in
- Background circles: 3-4 second staggered animations

### Form Validation

- Step 1: Name must not be empty
- Step 2: Birthdate, height, and weight required
- Steps 3-5: Pre-selected defaults, all optional fields clearly marked
- Continue button disabled until required fields are complete

## Future Enhancements

Potential improvements:

- Add profile editing screen
- Allow re-calculation of goals on demand
- Add progress tracking against onboarding goals
- Export onboarding data for backup
- Add more diet types and restrictions
- Integrate with wearable devices for activity tracking
- Add photos to profile
- Social features (optional sharing of goals)

## Notes

- The Gemini API key is stored in `lib/core/config/app_config.dart`
- For production, move to environment variables or secure storage
- All calculations are done locally as fallback if Gemini is unavailable
- User can update goals manually in settings (future feature)
- Onboarding data persists across app restarts
