# Quick Strava Connection Guide

## ⚠️ IMPORTANT: Token Scope Issue

**The tokens from your API settings page have `scope: read` which is NOT enough!**

You're getting 401 errors because your tokens only have `read` permission, but the app needs `activity:read_all` to fetch your running activities.

## ✅ Correct Way to Get Tokens (3 Steps)

### Step 1: Authorize with Correct Scope

1. **Copy this OAuth URL** (already has correct permissions):

   ```
   https://www.strava.com/oauth/authorize?client_id=192689&response_type=code&redirect_uri=http://localhost&approval_prompt=force&scope=read,activity:read,activity:read_all
   ```

2. **Paste it in your browser** and press Enter

3. **Click "Authorize"** - You'll be redirected to `http://localhost/?code=XXXXX`

4. **Copy the code from the URL** (everything after `code=`)

### Step 2: Exchange Code for Tokens

Open PowerShell and run this command (replace `YOUR_CODE_HERE` with the code from step 1):

```powershell
curl -X POST https://www.strava.com/oauth/token `
  -d "client_id=192689" `
  -d "client_secret=df76a4b8de7ced04bd3ad7094069cfd485f6bfcc" `
  -d "code=YOUR_CODE_HERE" `
  -d "grant_type=authorization_code"
```

You'll get a response like:

```json
{
  "access_token": "abc123...",
  "refresh_token": "def456...",
  "expires_at": 1735627412,
  "scope": "read,activity:read_all"
}
```

### Step 3: Use Tokens in App

1. Open the app → Fitness → Running → History icon
2. Tap **"Connect Strava Account"**
3. Choose **"Manual Entry"**
4. Tap **"Copy OAuth Link"** button (to make it easy next time)
5. Paste your `access_token` and `refresh_token`
6. Tap **"Connect"** - It should work now! ✅

## 🔍 Why This Is Needed

- **API Settings Page Tokens**: Only have `read` scope (can't see activities)
- **OAuth Flow Tokens**: Have `read,activity:read,activity:read_all` scope (can see activities)

Your current tokens:

```
Scope: read ❌ (WRONG - can't read activities)
```

New tokens will have:

```
Scope: read,activity:read,activity:read_all ✅ (CORRECT)
```

## 🔧 What Changed

- **New Quick Connect Method**: Automatically validates and refreshes tokens
- **Simplified UI**: Manual token entry is now the default (more reliable than OAuth on emulators)
- **Better Error Messages**: Clear feedback if something goes wrong
- **Auto-Refresh**: Tokens are automatically refreshed during connection

## 📊 Your Current Tokens (from API Settings)

From your Strava API settings page:

```
Client ID:       192689
Client Secret:   df76a4b8de7ced04bd3ad7094069cfd485f6bfcc
Access Token:    984e44795b3a16f21e88cc3f911bc59f28be584c
Refresh Token:   2a5c809e55720c5711df3e524d384a37cf810566
Expires:         2025-12-31T04:03:32Z (will be refreshed automatically)
Scope:           read
```

## 🚀 Features After Connection

Once connected, you can:

- View all your running activities
- See detailed statistics (pace, elevation, heart rate)
- Interactive charts for each activity
- Yearly running totals
- Pull-to-refresh for latest activities

## ⚠️ Troubleshooting

### "Failed to connect" Error

- Make sure you copied the entire token (no spaces at start/end)
- Get fresh tokens from https://www.strava.com/settings/api
- Make sure your Strava account has running activities

### "Rate limit exceeded" Error

- Strava allows 100 requests per 15 minutes
- Wait a few minutes and try again
- The app has built-in rate limiting to help prevent this

### Still Not Working?

1. Try the **"Disconnect Strava"** button first
2. Then reconnect with fresh tokens from the API settings page
3. Make sure you're using the tokens from the "Your Access Token" section, not creating a new app

## 📱 OAuth Method (Alternative)

If you're on a real device (not emulator), you can use the OAuth flow:

1. Choose **"OAuth"** instead of "Manual Entry"
2. You'll be redirected to Strava in your browser
3. Authorize the app
4. You'll be redirected back automatically

**Note**: OAuth doesn't work well on emulators, which is why manual entry is recommended.
