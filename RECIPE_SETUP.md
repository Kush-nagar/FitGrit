# Recipe Generation Setup

## Gemini API Configuration

This app uses the Gemini API to generate recipes from detected ingredients. To use this feature, you need to set up a Gemini API key.

### Getting Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Get API Key" or "Create API Key"
4. Copy your API key

### Setting Up the API Key

You have several options to provide the API key:

#### Option 1: Using --dart-define (Recommended for Development)

Run the app with the API key as a command-line argument:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

Or for release builds:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_api_key_here
```

#### Option 2: Create a Configuration File

Create a file `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String geminiApiKey = 'your_api_key_here';
}
```

Then update `lib/presentation/recipes_screen/recipes_screen.dart`:

Change:

```dart
const apiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);
```

To:

```dart
import '../../config/api_config.dart';
// ...
final apiKey = ApiConfig.geminiApiKey;
```

**Important**: Add `lib/config/api_config.dart` to your `.gitignore` to keep your API key secret!

#### Option 3: Environment Variables (For CI/CD)

Set the environment variable before building:

**Linux/Mac:**

```bash
export GEMINI_API_KEY=your_api_key_here
flutter run --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

**Windows:**

```powershell
$env:GEMINI_API_KEY="your_api_key_here"
flutter run --dart-define=GEMINI_API_KEY=$env:GEMINI_API_KEY
```

## Recipe Feature Overview

The recipe generation feature:

- Takes detected ingredients from the recognition screen
- Uses Gemini AI to generate exactly 8 diverse recipes
- Each recipe includes:
  - Name and description
  - Complete ingredient list with quantities
  - Step-by-step cooking instructions
  - Nutrition facts (calories, protein, carbs, fat, fiber, sugar, sodium)
  - Prep time, cook time, and servings
- Beautiful UI with recipe cards and detailed recipe view

## Usage

1. Scan ingredients using the camera
2. Review and edit detected ingredients
3. Tap "Find Recipes"
4. View 8 AI-generated recipes
5. Tap on any recipe to see full details
6. Use the refresh button to generate new recipes

## Notes

- The Gemini API has rate limits and quotas
- Make sure you've enabled the Generative Language API in Google Cloud Console
- Keep your API key secret and never commit it to version control
