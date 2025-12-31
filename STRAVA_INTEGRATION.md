# Strava Integration Guide

## Overview

This app now integrates with Strava to fetch and display your running activities with detailed metrics including:

- **Distance & Duration**: Total distance traveled and time spent
- **Pace & Speed**: Average pace, average/max speed
- **Elevation**: Elevation gain, high/low points
- **Heart Rate**: Average and max heart rate (if available)
- **Cadence**: Steps per minute (if available)
- **Interactive Charts**: Visual representation of pace, elevation, heart rate, and cadence over time

## Features

### Running History Screen

- View list of all your running activities from Strava
- See summary statistics (distance, duration, pace)
- View yearly running totals
- Pull-to-refresh to get latest activities
- Tap any activity to see detailed statistics

### Running Details Screen

- Comprehensive activity statistics
- Interactive charts for:
  - Pace over time
  - Elevation profile
  - Heart rate zones
  - Cadence variations
- Visual data representation using fl_chart

## Setup Instructions

### 1. Create a Strava API Application

1. Go to [https://www.strava.com/settings/api](https://www.strava.com/settings/api)
2. Click "Create an App" (or use an existing app)
3. Fill in the application details:
   - **Application Name**: Your app name
   - **Website**: Your website (can be any valid URL)
   - **Authorization Callback Domain**: Use `localhost` for development
4. After creating the app, note down:
   - **Client ID**
   - **Client Secret**

### 2. Configure the App

Open `lib/services/strava_auth_service.dart` and update the following constants:

```dart
static const String clientId = 'YOUR_CLIENT_ID';        // Replace with your Client ID
static const String clientSecret = 'YOUR_CLIENT_SECRET'; // Replace with your Client Secret
static const String redirectUrl = 'your-app://redirect'; // Update if using custom redirect
```

### 3. Get Your Access Tokens

Since full OAuth flow requires deep linking setup, you can manually get your tokens for testing:

#### Method A: Using OAuth Playground

1. Go to: `https://www.strava.com/oauth/authorize?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://localhost&approval_prompt=force&scope=read,activity:read,activity:read_all`
2. Replace `YOUR_CLIENT_ID` with your actual Client ID
3. Authorize the app - you'll be redirected to localhost with a code in the URL
4. Copy the authorization code from the URL
5. Make a POST request to exchange the code for tokens:
   ```bash
   curl -X POST https://www.strava.com/oauth/token \
     -d client_id=YOUR_CLIENT_ID \
     -d client_secret=YOUR_CLIENT_SECRET \
     -d code=AUTHORIZATION_CODE \
     -d grant_type=authorization_code
   ```
6. You'll receive a JSON response with `access_token`, `refresh_token`, and `expires_at`

#### Method B: Get Tokens from Strava Settings

1. Go to [https://www.strava.com/settings/api](https://www.strava.com/settings/api)
2. Under "Your Access Token", you can generate a temporary token for testing
3. Note: These tokens may have limited permissions

### 4. Enter Tokens in the App

1. Run the app and navigate to the Fitness screen
2. Select "RUNNING" from the exercise dropdown
3. Tap the history icon (clock icon) in the app bar
4. Tap "Connect Strava Account"
5. Tap "Enter Tokens" in the dialog
6. Enter your:
   - Access Token
   - Refresh Token
   - Expires At (Unix timestamp, defaults to 6 hours from now)
7. Tap "Save"

The app will now fetch your running activities from Strava!

## Usage

### View Running History

1. Go to Fitness screen
2. Select "RUNNING" from the exercise dropdown
3. Tap the history icon in the app bar
4. You'll see a list of your recent running activities

### View Activity Details

1. From the Running History screen, tap any activity
2. View comprehensive statistics and interactive charts
3. Scroll down to see pace, elevation, heart rate, and cadence charts

### Disconnect Strava

1. From the Running History screen, tap the logout icon in the app bar
2. Confirm disconnection
3. Your tokens will be securely removed

## Data Privacy & Security

- **Secure Storage**: All tokens are stored securely using `flutter_secure_storage`
- **Automatic Refresh**: Access tokens are automatically refreshed when expired
- **Read-Only Access**: The app only requests read permissions for your activities
- **No Data Collection**: Your Strava data is only used to display information in the app

## Troubleshooting

### "Error loading activities"

- Check that your access token is valid
- Ensure you have granted the correct permissions (`read`, `activity:read`, `activity:read_all`)
- Try refreshing the token by logging out and logging back in

### "No running activities found"

- Make sure you have running activities in your Strava account
- Check that activities are not private
- Verify the token has `activity:read_all` scope

### Charts not displaying

- Some activities may not have all data streams (heart rate, cadence)
- Charts will only show for data that exists in your activity
- Ensure your device recorded the data during the run

## Advanced: Setting Up Deep Linking (Optional)

For a full OAuth flow without manual token entry, you can set up deep linking:

### Android Setup

1. Add intent filter to `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="yourapp"
        android:host="redirect" />
</intent-filter>
```

### iOS Setup

1. Add URL scheme to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

2. Update `redirectUrl` in `strava_auth_service.dart` to match your scheme

## API Rate Limits

Strava API has the following rate limits:

- **100 requests every 15 minutes**
- **1,000 requests per day**

The app is designed to minimize API calls by:

- Caching activities locally (pull-to-refresh to update)
- Fetching details only when viewing specific activities
- Reusing tokens with automatic refresh

## Additional Resources

- [Strava API Documentation](https://developers.strava.com/docs/reference/)
- [Strava API Getting Started](https://developers.strava.com/docs/getting-started/)
- [Strava Authentication Guide](https://developers.strava.com/docs/authentication/)

## Future Enhancements

Potential features to add:

- Local caching of activities for offline viewing
- Comparison between runs
- Personal records tracking
- Goal setting and progress tracking
- Integration with the running form analysis feature
- Export data to other formats
- Activity filtering and search
