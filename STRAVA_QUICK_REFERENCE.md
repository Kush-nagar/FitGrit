# Strava Integration - Quick Reference

## What Was Added

### New Dependencies

- `url_launcher: ^6.3.1` - Open Strava OAuth in browser
- `flutter_secure_storage: ^9.2.2` - Securely store authentication tokens

### New Services

- **`lib/services/strava_auth_service.dart`**

  - OAuth 2.0 authentication flow
  - Secure token storage and refresh
  - Manual token entry for testing

- **`lib/services/strava_service.dart`**
  - Fetch activities from Strava API
  - Get detailed activity data
  - Retrieve activity streams (pace, elevation, heart rate, cadence)
  - Get athlete statistics

### New Models

- **`lib/models/strava_activity.dart`**
  - `StravaActivity` - Basic activity summary
  - `StravaActivityDetail` - Detailed activity data
  - `StravaActivityStreams` - Time series data (streams)
  - `StravaAthleteStats` - Athlete statistics
  - Helper methods for formatting (pace, distance, duration)

### New Screens

- **`lib/presentation/running_history_screen/running_history_screen.dart`**

  - List of running activities
  - Athlete statistics summary
  - Connect/disconnect Strava account
  - Manual token entry dialog
  - Pull-to-refresh

- **`lib/presentation/running_details_screen/running_details_screen.dart`**
  - Comprehensive activity statistics
  - Interactive charts using fl_chart:
    - Pace chart
    - Elevation profile
    - Heart rate zones
    - Cadence variations

### Updated Files

- **`lib/routes/app_routes.dart`**

  - Added routes for running history and details screens

- **`lib/presentation/fitness_screen/fitness_screen.dart`**
  - Added history button when "Running" is selected
  - Button navigates to running history screen

## Quick Start

1. **Get Strava API Credentials**

   - Create an app at https://www.strava.com/settings/api
   - Note your Client ID and Client Secret

2. **Update Credentials**

   - Edit `lib/services/strava_auth_service.dart`
   - Replace `YOUR_CLIENT_ID` and `YOUR_CLIENT_SECRET`

3. **Get Access Tokens**

   - Use OAuth playground or Strava API settings
   - See STRAVA_INTEGRATION.md for detailed instructions

4. **Connect in App**
   - Go to Fitness > Select "RUNNING"
   - Tap history icon
   - Tap "Connect Strava Account"
   - Enter your tokens
   - Start viewing your runs!

## Key Features

✅ View all running activities from Strava
✅ See detailed statistics (distance, pace, elevation, etc.)
✅ Interactive charts for performance metrics
✅ Secure token storage
✅ Automatic token refresh
✅ Athlete statistics (yearly totals)
✅ Pull-to-refresh for latest activities

## Files Modified Summary

```
pubspec.yaml                              # Added dependencies
lib/services/
  ├── strava_auth_service.dart           # NEW - Authentication
  └── strava_service.dart                # NEW - API calls
lib/models/
  └── strava_activity.dart               # NEW - Data models
lib/presentation/
  ├── running_history_screen/
  │   └── running_history_screen.dart    # NEW - Activity list
  ├── running_details_screen/
  │   └── running_details_screen.dart    # NEW - Activity details
  └── fitness_screen/
      └── fitness_screen.dart            # MODIFIED - Added history button
lib/routes/
  └── app_routes.dart                    # MODIFIED - Added new routes
STRAVA_INTEGRATION.md                    # NEW - Detailed guide
```

## Next Steps

1. Follow setup instructions in STRAVA_INTEGRATION.md
2. Test the connection with your Strava account
3. Verify activities are displaying correctly
4. Optional: Set up deep linking for full OAuth flow

## Support & Documentation

- Full setup guide: `STRAVA_INTEGRATION.md`
- Strava API docs: https://developers.strava.com/docs/
- For issues: Check troubleshooting section in STRAVA_INTEGRATION.md
