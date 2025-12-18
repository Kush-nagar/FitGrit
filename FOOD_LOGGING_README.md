# Food Logging Feature

This feature allows users to log their food intake by capturing an image, recognizing ingredients, and getting detailed nutrition information.

## How It Works

1. **Capture Food Image**: User takes a photo of their food using the camera scan screen
2. **Ingredient Recognition**: The app uses Gemini AI to detect ingredients in the image
3. **Review & Edit**: User can review, edit, add, or remove detected ingredients
4. **Get Nutrition Info**: When user clicks "Log Food", the app:
   - Sends the image and ingredients to Gemini API
   - Receives detailed nutrition facts (calories, protein, carbs, fat, fiber, sugar, sodium)
   - Displays the information in a beautiful UI
5. **Log to Dashboard**: User can log the food, which:
   - Saves to local storage (SharedPreferences)
   - Updates their daily nutrition goals
   - Can be viewed on the dashboard

## Files Created

### Models

- `lib/core/models/nutrition_info.dart` - Data model for nutrition information

### Services

- `lib/services/gemini_service.dart` (updated) - Added `getNutritionInfo()` method
- `lib/services/nutrition_storage_service.dart` - Handles storing/retrieving logged foods

### Screens

- `lib/presentation/food_logging_screen/food_logging_screen.dart` - Main screen for viewing nutrition and logging food

### Configuration

- `lib/core/config/app_config.dart` - Contains Gemini API key (already configured)
- `lib/routes/app_routes.dart` (updated) - Added food logging screen route

## Usage Flow

```
Camera Scan Screen
        ↓
Recognition Results Screen
        ↓ (Click "Log Food" button)
Food Logging Screen (NEW!)
        ↓ (Click "Log" button)
Dashboard (with updated nutrition data)
```

## API Integration

The app uses Google's Gemini API for:

1. **Ingredient Detection** - Analyzing food images to identify ingredients
2. **Nutrition Analysis** - Getting detailed nutritional information for the food

### Gemini API Key

The API key is already configured in `lib/core/config/app_config.dart`. If you need to change it:

1. Get a key from https://makersuite.google.com/app/apikey
2. Update `AppConfig.geminiApiKey` in the config file

## Data Storage

### Local Storage (SharedPreferences)

- Logged foods are stored locally
- Data automatically resets at midnight (new day)
- Users can set daily nutrition goals
- Progress is calculated against daily goals

### Storage Methods Available

```dart
// Log a food item
await nutritionStorageService.logFood(nutritionInfo);

// Get today's logged foods
List<Map<String, dynamic>> foods = await nutritionStorageService.getLoggedFoods();

// Get today's totals
Map<String, double> totals = await nutritionStorageService.getTodaysTotals();

// Get/set daily goals
await nutritionStorageService.setDailyGoal(
  calories: 2000,
  protein: 150,
  carbs: 200,
  fat: 70,
);

// Get progress towards goals (0.0 - 1.0+)
Map<String, double> progress = await nutritionStorageService.getProgress();
```

## Dashboard Integration

To display nutrition data on the dashboard, you can use:

```dart
import 'package:your_app/services/nutrition_storage_service.dart';

final storageService = NutritionStorageService();

// Get today's totals
final totals = await storageService.getTodaysTotals();
final goals = await storageService.getDailyGoal();
final progress = await storageService.getProgress();

// Display
Text('Calories: ${totals['calories'].toInt()} / ${goals['calories'].toInt()}');
Text('Progress: ${(progress['calories'] * 100).toStringAsFixed(1)}%');
```

## Testing

1. **Test Ingredient Recognition**:

   - Go to Camera Scan Screen
   - Take a photo of food
   - Verify ingredients are detected

2. **Test Food Logging**:

   - From Recognition Results, click "Log Food"
   - Wait for nutrition analysis (takes a few seconds)
   - Verify nutrition facts are displayed
   - Click "Log" button
   - Should navigate to dashboard

3. **Test Data Persistence**:
   - Log multiple foods
   - Use `getTodaysTotals()` to verify data is saved
   - Restart app - data should persist until midnight

## Next Steps

1. **Dashboard Updates**: Update the home dashboard to display:

   - Today's calorie progress
   - Macro breakdown (protein/carbs/fat)
   - List of logged foods
   - Progress bars

2. **Food Log History**: Update the food log history screen to show:

   - Past logged foods
   - Nutrition history over time
   - Charts/graphs

3. **Goal Setting**: Add UI for users to set their daily nutrition goals

4. **Edit Logged Foods**: Allow users to edit or delete logged foods

5. **Offline Mode**: Add caching for frequently logged foods

## Troubleshooting

### "API access denied" error

- Check that the Gemini API key is valid
- Enable the Generative Language API in Google Cloud Console

### "No text returned by Gemini" error

- Check your internet connection
- The image might be too large (automatically resized to 1024px)
- Try with a different image

### Data not persisting

- Check SharedPreferences permissions
- Verify data is being saved with `getLoggedFoods()`
- Check if it's past midnight (data auto-resets)

## Dependencies

The following packages are used:

- `shared_preferences` - Local data storage
- `http` - API requests to Gemini
- `image` - Image processing
- `sizer` - Responsive sizing
