# ⚠️ IMPORTANT: Gemini API Key Required

## 🔑 Before Running the App

The Akira chatbot **will not work** until you add your Gemini API key!

## Quick Setup (2 minutes)

### Step 1: Get Your Free API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Get API Key" or "Create API Key"
4. Copy your API key (starts with `AIza...`)

### Step 2: Add to Your App

1. Open: `lib/services/akira_chatbot_service.dart`
2. Find line 8:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```
3. Replace with your key:
   ```dart
   static const String _apiKey = 'AIzaSy...your-actual-key-here';
   ```
4. Save the file

### Step 3: Run the App

```bash
flutter run
```

## ✅ Testing Akira

1. Launch the app
2. On the home dashboard, tap the chat bubble icon 🗨️ (top-right)
3. You should see Akira's welcome message
4. Type a question like "What are healthy breakfast ideas?"
5. Watch the response stream in!

If you see an error instead, check that:

- ✅ Your API key is correct (no extra spaces or quotes)
- ✅ You've saved the file after editing
- ✅ You have internet connection
- ✅ Your API key is active in Google AI Studio

## 🆓 Free Tier Limits

Gemini 1.5 Flash (used by Akira):

- **Free quota**: 15 requests per minute
- **Rate limit**: 1 million tokens per minute
- **Cost**: Free for personal use

This is more than enough for testing and personal use!

## 🔒 Security Reminder

**NEVER commit your API key to Git!**

If using version control:

1. Add `.env` to `.gitignore`
2. Use environment variables for the key
3. Share instructions, not the actual key

See [AKIRA_SETUP.md](AKIRA_SETUP.md) for production-ready security setup.

## 📚 Need Help?

- **Setup Guide**: See [AKIRA_SETUP.md](AKIRA_SETUP.md)
- **Feature Overview**: See [AKIRA_CHATBOT_SUMMARY.md](AKIRA_CHATBOT_SUMMARY.md)
- **Example Conversations**: See [AKIRA_EXAMPLE_CONVERSATIONS.md](AKIRA_EXAMPLE_CONVERSATIONS.md)
- **UI Details**: See [AKIRA_UI_GUIDE.md](AKIRA_UI_GUIDE.md)

## 🎉 You're All Set!

Once you've added your API key, Akira is ready to help your users with:

- 🥗 Nutrition advice
- 💪 Fitness guidance
- 🧘 Wellness tips
- 🏃 Presidential Fitness Test info
- 📱 App feature explanations

Happy chatting! 🤖✨
