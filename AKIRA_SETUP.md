# Akira Chatbot Setup Instructions

This guide will help you set up the Akira AI chatbot feature in your app.

## Prerequisites

1. A Google Cloud account
2. Access to Google AI Studio (for Gemini API)

## Step 1: Get Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click on "Get API Key" or "Create API Key"
4. Copy your API key

## Step 2: Add API Key to Your App

### Option 1: Direct Method (For Development/Testing)

1. Open `lib/services/akira_chatbot_service.dart`
2. Find the line:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```
3. Replace `'YOUR_GEMINI_API_KEY_HERE'` with your actual API key:
   ```dart
   static const String _apiKey = 'AIza...your-actual-key-here';
   ```

### Option 2: Secure Method (For Production - Recommended)

1. Create a `.env` file in the root of your project (if not already present)
2. Add your API key:
   ```
   GEMINI_API_KEY=AIza...your-actual-key-here
   ```
3. Add `.env` to your `.gitignore` file to prevent committing it
4. Install the `flutter_dotenv` package:
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```
5. Update the service to load from environment:

   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';

   static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
   ```

## Step 3: Install Dependencies

Run the following command to install the new dependencies:

```bash
flutter pub get
```

## Step 4: Test the Chatbot

1. Run your app:
   ```bash
   flutter run
   ```
2. Navigate to the home dashboard
3. Look for the chat bubble icon in the top-right corner of the app bar
4. Tap it to open Akira
5. Try asking questions like:
   - "What are some healthy breakfast ideas?"
   - "How many calories should I eat per day?"
   - "What exercises can help with flexibility?"
   - "Tell me about the Presidential Fitness Test"

## Features Implemented

✅ **Streaming Responses**: Akira types responses in real-time, showing chunks as they're generated
✅ **Typing Animation**: Three-dot animation shows when Akira is thinking
✅ **Content Filtering**: Built-in safety settings prevent inappropriate responses
✅ **App Knowledge**: Akira knows about all app features (nutrition tracking, fitness, recipes, etc.)
✅ **Modern UI**: Chat interface matches your app's theme with gradient accents
✅ **Chat History**: Conversation history is maintained during the session
✅ **Clear Chat**: Option to clear chat history and start fresh

## Customization

### Adjust Response Style

Edit the system prompt in `lib/services/akira_chatbot_service.dart` to change Akira's personality or focus areas.

### Change Model

You can switch to different Gemini models by changing this line:

```dart
model: 'gemini-1.5-flash',  // Fast and efficient
// or
model: 'gemini-1.5-pro',     // More capable, slightly slower
```

### Safety Settings

Adjust content filtering in the `safetySettings` array:

- `HarmBlockThreshold.high` - More permissive
- `HarmBlockThreshold.medium` - Balanced
- `HarmBlockThreshold.low` - More restrictive

## Troubleshooting

### "API key not found" Error

- Make sure you've added your API key correctly
- Rebuild the app after adding the key

### No Response from Chatbot

- Check your internet connection
- Verify your API key is valid
- Check the console for error messages

### Streaming Not Working

- Ensure you're using `gemini-1.5-flash` or `gemini-1.5-pro`
- Check that you have the latest version of `google_generative_ai` package

### Content Blocked

- If Akira's response is blocked, it may have triggered safety filters
- Try rephrasing your question
- Check the safety settings if you need to adjust them

## API Usage and Pricing

- Gemini 1.5 Flash has generous free tier limits
- Check [Google AI Pricing](https://ai.google.dev/pricing) for current rates
- The app uses efficient streaming to minimize token usage

## Security Best Practices

🔒 **Never commit API keys to version control**
🔒 Use environment variables for production
🔒 Rotate API keys periodically
🔒 Set usage quotas in Google Cloud Console
🔒 Monitor API usage regularly

## Support

If you encounter issues:

1. Check the Flutter console for error messages
2. Verify your API key is active in Google AI Studio
3. Ensure all dependencies are properly installed
4. Review the knowledge base file for context updates

## Next Steps

Consider adding:

- Persistent chat history (save to Firebase)
- Voice input/output integration
- Multi-language support
- Personalized responses based on user data
- Quick reply suggestions
- Image analysis for food recognition questions
