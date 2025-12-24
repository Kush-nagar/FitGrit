# Running Form Analysis Feature

## Overview

Added comprehensive running form analysis to the fitness screen, including pose analysis, form quality assessment, and accurate pace/speed calculation from uploaded videos.

## Features

### 1. Running Form Analysis

- **Stride Analysis**: Measures stride length, cadence (steps per minute), and foot strike angle
- **Posture Evaluation**: Analyzes forward lean, hip alignment, and shoulder relaxation
- **Arm Swing Analysis**: Checks arm swing amplitude and elbow angle
- **Real-time Feedback**: Provides issues and recommendations for improvement

### 2. Running Metrics Calculation

- **Distance Tracking**: Calculates total distance traveled from video
- **Speed Calculation**: Provides average speed, instantaneous speed, and max speed
- **Pace Calculation**: Displays pace in min/km format
- **Cadence Tracking**: Measures steps per minute

### 3. Form Quality Rating

The system rates running form on a scale of:

- **Excellent** (85-100 points): Green indicator
- **Good** (70-84 points): Light green indicator
- **Fair** (55-69 points): Orange indicator
- **Poor** (0-54 points): Red indicator

### 4. Customizable Settings

- **Run Type Selection**: Sprint, Middle Distance, Long Distance, or Recovery
- **Runner Height**: Adjustable from 1.4m to 2.1m for accurate stride calibration
- **Optimal Thresholds**: Different optimal cadence and lean angles based on run type

## Usage

### From Camera View

1. Select "RUNNING" from the exercise dropdown in the app bar
2. Click the settings icon to configure run type and height
3. Start the camera to begin live analysis
4. Running metrics overlay will display:
   - Distance traveled
   - Current speed and pace
   - Cadence (steps per minute)
   - Form quality rating
   - Detected issues (if any)

### From Video Upload

1. Select "RUNNING" from the exercise dropdown
2. Upload a running video
3. Click "Analyze Video" to process
4. View comprehensive metrics including:
   - Total distance
   - Average and max speed
   - Average pace
   - Form quality assessment
   - Stride analysis

## Technical Details

### New Files Created

1. **`lib/models/running_form_analyzer.dart`**

   - `RunningFormAnalyzer` class: Analyzes running form frame by frame
   - `RunningFormMetrics` class: Contains all form analysis results
   - `FormQuality` enum: Quality rating levels
   - `RunType` enum: Different running activity types

2. **`lib/services/running_metrics_calculator.dart`**
   - `RunningMetricsCalculator` class: Calculates pace, speed, and distance
   - `RunningMetrics` class: Contains all calculated running metrics
   - Uses hip midpoint tracking for movement analysis
   - Calibrates stride length based on runner height

### Modified Files

1. **`lib/models/rep_counter.dart`**

   - Added `ExerciseType.running` to the enum

2. **`lib/presentation/fitness_screen/fitness_screen.dart`**
   - Added running analyzer and metrics calculator integration
   - Added running metrics overlay UI
   - Added settings dialog for run type and height
   - Updated frame processing to handle running analysis
   - Updated video analysis to support running metrics

## Accuracy Considerations

### Speed & Distance Calculation

The accuracy of speed and distance calculations depends on:

- **Camera Angle**: Side view works best
- **Camera Stability**: Stationary camera provides most accurate results
- **Runner Height Setting**: Must be set correctly for calibration
- **Video Quality**: Higher quality videos yield better pose detection

### Form Analysis

Form analysis is based on:

- Pose keypoint detection (MoveNet model)
- Joint angle calculations
- Temporal analysis of movement patterns
- Comparison with optimal biomechanics for each run type

## Recommendations

For best results:

1. Set the correct runner height in settings
2. Choose the appropriate run type (sprint/middle/long/recovery)
3. Record from a side view with the full body visible
4. Ensure good lighting and minimal background clutter
5. Keep the camera stationary during recording

## Future Enhancements

- GPS integration for outdoor runs (more accurate distance)
- Camera calibration for precise distance measurement
- Historical tracking of running metrics
- Comparison with previous runs
- Export running data to common fitness formats
