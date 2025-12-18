# Firebase Integration - Daily Nutrition Tracking

This integration connects your app to Firebase Firestore for storing and retrieving daily nutrition data, including calories, macros, water intake, and logged foods.

## 🎯 What's New

### Firebase Firestore Structure

Your data is now organized in Firebase with the following structure:

```
Firestore Database:
└── users/
    └── {userId}/
        ├── daily_logs/
        │   ├── 2025-12-16/
        │   │   ├── calories: 1850.0
        │   │   ├── protein: 120.5
        │   │   ├── carbs: 180.2
        │   │   ├── fat: 65.3
        │   │   ├── fiber: 25.0
        │   │   ├── sugar: 45.0
        │   │   ├── sodium: 1200.0
        │   │   ├── waterGlasses: 6
        │   │   ├── foods: [array of logged foods]
        │   │   ├── lastUpdated: timestamp
        │   │   └── createdAt: timestamp
        │   │
        │   ├── 2025-12-17/
        │   │   └── ... (same structure)
        │   │
        │   └── 2025-12-18/
        │       └── ... (same structure)
        │
        └── settings/
            └── daily_goals/
                ├── targetCalories: 2000.0
                ├── targetProtein: 150.0
                ├── targetCarbs: 200.0
                ├── targetFat: 70.0
                ├── targetWaterGlasses: 8
                └── lastUpdated: timestamp
```

### Key Features

#### 1. **Date-Based Organization**

- Each day's data is stored in a separate document
- Date format: `YYYY-MM-DD` (e.g., `2025-12-17`)
- If you didn't log anything yesterday, that date will show all zeros
- Historical data is preserved indefinitely

#### 2. **Real-Time Data Sync**

- When you log food, it immediately updates Firebase
- Dashboard automatically loads data for the selected date
- Changes are reflected instantly across all devices (future feature)

#### 3. **Date Navigation**

- Navigate between dates using arrow buttons
- Click calendar icon to pick any date
- Cannot navigate to future dates
- View your entire nutrition history

#### 4. **Water Intake Tracking**

- Each glass of water is tracked per date
- Separate from food logs
- Stored in the same daily document

## 📱 Updated Screens

### Home Dashboard Screen

**New Features:**

- Date picker button in app bar
- Previous/Next day navigation arrows
- Shows data for selected date
- Real-time loading indicator
- Displays logged foods from Firebase

**Usage:**

```dart
// The dashboard now automatically:
1. Loads data for today on launch
2. Updates when you change dates
3. Shows logged foods from Firebase
4. Reflects water intake changes
```

### Food Logging Screen

**Changes:**

- Now saves directly to Firebase
- Stores complete nutrition info
- Includes timestamp
- Organized by date automatically

## 🔧 Installation & Setup

### 1. Install Dependencies

Run this command to install the new Firebase dependency:

```bash
flutter pub get
```

### 2. Firebase Setup

**Important:** Make sure Firebase is properly configured in your project.

**Check these files exist:**

- `android/app/google-services.json` (Android)
- `ios/Runner/GoogleService-Info.plist` (iOS)
- `web/index.html` has Firebase config (Web)

### 3. Firestore Rules

Add these security rules in Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /daily_logs/{date} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /settings/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

**Note:** Currently using `default_user` as user ID. Update `firebase_nutrition_service.dart` line 18 to use Firebase Auth when ready.

## 💾 Data Storage Details

### What Gets Stored

**When you log food:**

```json
{
  "foodName": "Grilled Chicken Salad",
  "ingredients": ["Chicken", "Lettuce", "Tomatoes"],
  "calories": 320,
  "protein": 35,
  "carbs": 15,
  "fat": 12,
  "fiber": 5,
  "sugar": 6,
  "sodium": 450,
  "servingSize": "1 serving (250g)",
  "timestamp": "2025-12-17T14:30:00.000Z"
}
```

**Daily totals are automatically calculated:**

- Sum of all calories from logged foods
- Sum of all macros (protein, carbs, fat)
- Sum of fiber, sugar, sodium
- Count of water glasses

### Data Persistence

✅ **What persists:**

- All logged foods (forever)
- Daily totals (forever)
- Water intake per day (forever)
- Daily goals

❌ **What doesn't persist:**

- Nothing! All data is permanent until manually deleted

## 🎮 Usage Examples

### View Different Dates

**Method 1: Arrow Navigation**

```
[←] Current date [→]
```

- Click left arrow: Go to previous day
- Click right arrow: Go to next day (disabled for future dates)

**Method 2: Date Picker**

- Click calendar icon in app bar
- Select any date from the calendar
- Dashboard updates automatically

### Check Yesterday's Data

1. Open dashboard
2. Click left arrow button
3. See yesterday's totals
4. If nothing logged yesterday, everything shows 0

### Log Food

1. Tap "Scan Food" button
2. Take photo of food
3. Review detected ingredients
4. Tap "Log Food"
5. View nutrition info
6. Tap "Log" button
7. Data saves to Firebase for today

### Add Water

- Tap water glass icon
- Water count increases for current date
- Saved immediately to Firebase

## 🔄 Migration from SharedPreferences

**Old behavior:**

- Data stored locally on device
- Reset at midnight automatically
- Lost if app uninstalled

**New behavior:**

- Data stored in Firebase cloud
- Never resets automatically
- Preserved across devices
- Accessible from anywhere

## 📊 API Reference

### FirebaseNutritionService

```dart
final service = FirebaseNutritionService();

// Log food for a specific date
await service.logFood(
  nutritionInfo: nutritionInfo,
  date: DateTime(2025, 12, 17), // Optional, defaults to today
);

// Add water glass
await service.addWaterGlass(
  date: DateTime.now(), // Optional
);

// Get daily totals
final totals = await service.getDailyTotals(
  date: DateTime(2025, 12, 16), // Optional, defaults to today
);
// Returns:
// {
//   'calories': 1850.0,
//   'protein': 120.5,
//   'carbs': 180.2,
//   'fat': 65.3,
//   'fiber': 25.0,
//   'sugar': 45.0,
//   'sodium': 1200.0,
//   'waterGlasses': 6,
//   'foods': [...]
// }

// Get logged foods for a date
final foods = await service.getLoggedFoods(
  date: DateTime(2025, 12, 17),
);

// Delete a food item
await service.deleteFood(
  index: 0, // Index in foods array
  date: DateTime.now(),
);

// Get/Set daily goals
await service.setDailyGoals(
  targetCalories: 2000,
  targetProtein: 150,
  targetCarbs: 200,
  targetFat: 70,
  targetWaterGlasses: 8,
);

final goals = await service.getDailyGoals();

// Get progress towards goals
final progress = await service.getProgress(
  date: DateTime.now(),
);
// Returns values 0.0 to 1.0+ for each nutrient

// Stream real-time updates (for advanced usage)
service.streamDailyTotals(date: DateTime.now()).listen((data) {
  print('Calories: ${data['calories']}');
});

// Get date range (for history/charts)
final history = await service.getDateRange(
  startDate: DateTime(2025, 12, 1),
  endDate: DateTime(2025, 12, 17),
);
```

## 🐛 Troubleshooting

### "FirebaseException: [permission-denied]"

**Solution:** Update Firestore security rules (see Installation section)

### "No data loading"

**Check:**

1. Firebase initialized in `main.dart`
2. Internet connection active
3. Firestore rules allow read/write
4. Check Firebase Console for data

### "Data showing for wrong date"

**Solution:**

- Check device date/time settings
- Timezone might affect date calculations
- Firebase uses UTC, app converts to local time

### Yesterday shows 0 even though I logged food

**Expected behavior:** If you didn't log anything yesterday, it correctly shows 0. The data is stored per date, so only dates with logged foods will show values.

### Water intake not saving

**Check:**

1. Date is not in the future
2. Firebase connection is active
3. No errors in console logs

## 🚀 Future Enhancements

### Planned Features:

1. **Firebase Authentication**

   - Multiple user support
   - Secure user-specific data
   - Cross-device sync

2. **Offline Mode**

   - Cache data locally
   - Sync when online
   - Conflict resolution

3. **History Analytics**

   - Weekly/monthly summaries
   - Trend charts
   - Goal achievement tracking

4. **Social Features**
   - Share progress
   - Friend comparisons
   - Challenges

## 📝 Notes

- **User ID:** Currently using `default_user`. Replace with Firebase Auth UID in production.
- **Timezone:** All dates are stored and compared in local device timezone.
- **Data Limits:** Firestore free tier allows 1GB storage and 50K reads/day.
- **Performance:** Each date access = 1 read. Optimize by caching frequently accessed dates.

## 🔐 Security Recommendations

Before deploying to production:

1. **Enable Firebase Authentication**
2. **Update Firestore rules** to use auth.uid
3. **Implement rate limiting** to prevent abuse
4. **Add data validation** in security rules
5. **Enable Firebase App Check** for additional security

## 📄 Files Modified

- ✅ `pubspec.yaml` - Added cloud_firestore dependency
- ✅ `lib/services/firebase_nutrition_service.dart` - New service file
- ✅ `lib/presentation/home_dashboard_screen/home_dashboard_screen.dart` - Updated to use Firebase
- ✅ `lib/presentation/food_logging_screen/food_logging_screen.dart` - Updated to save to Firebase

## 🎉 Summary

Your app now has:

- ✅ Firebase Firestore integration
- ✅ Date-based data organization
- ✅ Historical data preservation
- ✅ Date navigation on dashboard
- ✅ Real-time data loading
- ✅ Proper data structure
- ✅ Zero values for empty dates

Everything is ready to use! Just make sure Firebase is properly set up in your project.
