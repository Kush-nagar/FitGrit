# Fitness Analysis Data Storage

This document describes how fitness video analysis data is automatically saved to Firebase, including Presidential Fitness Test benchmark comparisons.

## Overview

When a video is analyzed in the Fitness tab, the results are automatically saved to Firebase Firestore under the user's fitness analyses collection. The system also compares results against Presidential Fitness Test benchmarks (if user age and gender are configured) and saves the pass/fail status.

## Firestore Structure

```
users/{userId}/fitness_analyses/{analysisId}/
```

## Presidential Fitness Test Benchmarks

The app includes age and gender-specific benchmarks for the Presidential Fitness Test:

- **Ages**: 6-17 years
- **Gender**: Male and Female categories
- **Exercises**: Sit-ups, Pull-ups, Shuttle Run, V-Sit & Reach

### Benchmark Comparison Fields

When user age and gender are configured, the following fields are automatically added to each analysis:

- `benchmarkPassed`: boolean - Whether the user met the benchmark
- `benchmarkValue`: double - The required benchmark value
- `userValue`: double - The user's actual performance value
- `difference`: double - Absolute difference between user and benchmark
- `differenceText`: string - Human-readable difference (e.g., "2 reps", "0.5s")

## Exercise Types and Saved Data

### 1. Rep-Based Exercises (Push-ups, Pull-ups, Sit-ups)

**Saved Fields:**

- `exerciseType`: string - "pushUp", "pullUp", or "sitUp"
- `reps`: int - Total number of reps completed
- `date`: timestamp - When the analysis was performed
- `videoPath`: string - Path to the analyzed video (optional)
- `createdAt`: timestamp - Document creation time

**Example:**

```dart
{
  "exerciseType": "pushUp",
  "reps": 25,
  "date": Timestamp,
  "videoPath": "/path/to/video.mp4",
  "createdAt": Timestamp
}
```

### 2. Shuttle Run

**Saved Fields:**

- `exerciseType`: string - "shuttleRun"
- `totalDistance`: double - Total distance covered (meters)
- `totalTime`: double - Total time elapsed (seconds)
- `completedRuns`: int - Number of one-way runs completed
- `averageRunTime`: double - Average time per run (seconds)
- `averageSpeed`: double - Average speed (m/s)
- `maxSpeed`: double - Peak speed achieved (m/s)
- `peakSpeedTime`: double - When max speed occurred (seconds)
- `runTimes`: List<double> - Time for each individual run
- `speedProfile`: List<double> - Speed measurements over time
- `shuttleDistance`: double - Distance of one shuttle (meters)
- `directionChanges`: int - Number of turns made
- `averageTurnTime`: double - Average time per turn (seconds)
- `date`: timestamp - When the analysis was performed
- `videoPath`: string - Path to the analyzed video (optional)
- `createdAt`: timestamp - Document creation time

**Example:**

```dart
{
  "exerciseType": "shuttleRun",
  "totalDistance": 120.5,
  "totalTime": 45.2,
  "completedRuns": 6,
  "averageRunTime": 7.53,
  "averageSpeed": 2.67,
  "maxSpeed": 4.2,
  "peakSpeedTime": 12.5,
  "runTimes": [8.1, 7.5, 7.3, 7.8, 7.2, 7.3],
  "speedProfile": [0, 1.2, 2.5, 3.1, ...],
  "shuttleDistance": 20.0,
  "directionChanges": 5,
  "averageTurnTime": 1.8,
  "date": Timestamp,
  "videoPath": "/path/to/video.mp4",
  "createdAt": Timestamp
}
```

### 3. Flexibility Tests (Sit-and-Reach, V-Sit-and-Reach)

**Saved Fields:**

- `exerciseType`: string - "sitAndReach" or "vSitAndReach"
- `reachDistance`: double - Current reach distance from starting position (cm)
- `maxReachDistance`: double - Maximum reach achieved (cm)
- `flexibilityScore`: double - Overall flexibility rating (0-100)
- `hamstringFlexibility`: double - Hamstring flexibility measurement (degrees)
- `lowerBackFlexibility`: double - Lower back flexibility measurement (degrees)
- `hipFlexibility`: double - Hip flexibility measurement (degrees)
- `rating`: string - Qualitative rating ("Excellent", "Good", "Fair", "Needs Improvement")
- `reachProfile`: List<double> - Reach distance measurements over time
- `reps`: int - Number of attempts/repetitions
- `date`: timestamp - When the analysis was performed
- `videoPath`: string - Path to the analyzed video (optional)
- `createdAt`: timestamp - Document creation time

**Example:**

```dart
{
  "exerciseType": "sitAndReach",
  "reachDistance": 28.5,
  "maxReachDistance": 32.1,
  "flexibilityScore": 82.5,
  "hamstringFlexibility": 165.3,
  "lowerBackFlexibility": 45.2,
  "hipFlexibility": 78.9,
  "rating": "Excellent",
  "reachProfile": [10.2, 15.5, 22.3, 28.5, 32.1, 30.5],
  "reps": 3,
  "date": Timestamp,
  "videoPath": "/path/to/video.mp4",
  "createdAt": Timestamp
}
```

## Service Methods

The `FirebaseFitnessService` provides the following methods:

### Saving Data

- `saveRepExercise()` - Save push-up, pull-up, or sit-up analysis
- `saveShuttleRun()` - Save shuttle run analysis
- `saveFlexibilityTest()` - Save sit-and-reach or v-sit-and-reach analysis

### Retrieving Data

- `getAllAnalyses()` - Get all fitness analyses (with optional filtering and limits)
- `getAnalysesByDate()` - Get analyses for a specific date
- `getAnalysisById()` - Get a specific analysis by ID
- `getExerciseStats()` - Get statistics for a specific exercise type

### Managing Data

- `deleteAnalysis()` - Delete a specific analysis

## Automatic Saving

Data is automatically saved when:

1. A video analysis completes successfully
2. Results are displayed to the user
3. The user navigates to the detail screen (for shuttle run)

The saving happens in the background and doesn't block the UI. Success/failure is logged to the console.

## User Identification

Currently using a default user ID (`default_user`). In production, this should be replaced with Firebase Authentication user ID.

```dart
// TODO: Replace with Firebase Auth user ID
String get userId => 'default_user';
```

## Usage in Fitness Screen

The fitness screen automatically saves data after video processing completes in the `_processFullVideo()` method. The service is initialized as a class member:

```dart
final FirebaseFitnessService _firebaseFitnessService = FirebaseFitnessService();
```

And called after analysis completes:

```dart
// For push-ups, pull-ups, sit-ups
await _firebaseFitnessService.saveRepExercise(
  exerciseType: _selectedExercise,
  reps: repCount,
  videoPath: _currentVideoPath,
);

// For shuttle run
await _firebaseFitnessService.saveShuttleRun(
  metrics: _currentShuttleRunMetrics!,
  videoPath: _currentVideoPath,
);

// For flexibility tests
await _firebaseFitnessService.saveFlexibilityTest(
  metrics: _currentFlexibilityMetrics!,
  reps: _flexibilityRepCount,
  videoPath: _currentVideoPath,
);
```
