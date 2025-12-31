# Flexibility Exercise Pose Analysis Enhancement

## Overview

Enhanced the Sit and Reach and V Sit and Reach exercises with comprehensive pose analysis featuring:

- **Rep Counter**: Tracks complete reach cycles (reach forward → return to rest)
- **Multi-Angle Analysis**: Evaluates posture from multiple viewpoints
- **Real-time Feedback**: Provides instant corrections and improvement suggestions
- **Detailed Metrics**: Comprehensive flexibility and form quality scoring

## Features Added

### 1. Rep Counter for Flexibility Exercises

- Counts complete reach cycles based on wrist-to-hip distance
- **Sit and Reach**: Detects forward reach (70% threshold) and return to rest (25% threshold)
- **V Sit and Reach**: Similar mechanics with bonus scoring for proper leg spread (80-120° angle)
- Visual display with a badge showing current rep count

### 2. Multi-Angle Pose Analysis

Analyzes form from four key perspectives:

#### **Front View**

- **Metric**: Leg Symmetry
- **Assessment**: Checks if legs are aligned properly
  - For Sit and Reach: Legs should be together (feet touching)
  - For V Sit and Reach: Legs should spread evenly forming a V shape
- **Scoring**:
  - Excellent (85-100%): Perfect alignment
  - Good (70-84%): Minor asymmetry
  - Fair (55-69%): Noticeable misalignment
  - Needs Work (<55%): Significant asymmetry

#### **Side View**

- **Metric**: Back Alignment
- **Assessment**: Evaluates back posture and forward lean angle
- **Proper Form**: 30-60° forward lean with natural curve
- **Common Issues**:
  - Too upright (>70°): Limited reach
  - Excessive rounding (<20°): Poor form, potential injury risk

#### **Legs Analysis**

- **Metric**: Knee Extension
- **Assessment**: Measures how straight the legs are
- **Proper Form**: Knees locked, legs fully extended (170-180°)
- **Scoring Breakdown**:
  - 100%: Legs fully straight (≥170°)
  - 80%: Minor bend (160-169°)
  - 60%: Noticeable bend (150-159°)
  - 30%: Significant bend (<150°)

#### **Upper Body Analysis**

- **Metric**: Shoulder & Neck Position
- **Assessment**: Checks for proper shoulder relaxation and neutral neck
- **Proper Form**:
  - Shoulders level and relaxed (not hunched)
  - Neck neutral (not hyperextended)
  - Shoulder distance from midline <5cm

### 3. Real-Time Issue Detection

The system identifies common form problems:

#### Posture Issues

- ❌ **Back alignment needs improvement**

  - Cause: Rounded back or excessive arching
  - Fix: Maintain natural spine curve, engage core

- ❌ **Neck position not neutral**

  - Cause: Looking up too much or tucking chin excessively
  - Fix: Keep neck aligned with spine, gaze forward

- ❌ **Shoulders appear tense or uneven**
  - Cause: Hunched or elevated shoulders
  - Fix: Relax shoulders, pull them down and back

#### Leg Issues

- ❌ **Knees are bending**

  - Cause: Tight hamstrings or improper technique
  - Fix: Lock knees, press back of legs to floor

- ❌ **Legs are not together** (Sit and Reach)

  - Cause: Poor positioning
  - Fix: Keep legs straight and feet together

- ❌ **Legs are not spread evenly** (V Sit and Reach)
  - Cause: Asymmetric positioning
  - Fix: Spread legs equally to form symmetric V

#### Reach Issues

- ❌ **Reach movement is jerky**

  - Cause: Bouncing or forcing the stretch
  - Fix: Move slowly and smoothly, avoid bouncing

- ❌ **Position is unstable**

  - Cause: Not holding maximum reach
  - Fix: Hold peak position steadily for 2-3 seconds

- ❌ **Technique needs improvement**
  - Cause: Insufficient progression or improper breathing
  - Fix: Exhale while reaching, progressively increase reach

### 4. Improvement Recommendations

Contextual guidance based on detected issues:

#### Posture Recommendations

- ✅ Keep your back straight with a natural curve, avoid rounding
- ✅ Keep your neck in a neutral position, chin slightly tucked
- ✅ Relax your shoulders, keep them level and down

#### Leg Recommendations

- ✅ Keep your legs fully extended with knees locked
- ✅ Keep your legs close together with feet touching (Sit and Reach)
- ✅ Spread both legs equally to form a V shape (V Sit and Reach)

#### Technique Recommendations

- ✅ Reach forward slowly and smoothly, avoid bouncing
- ✅ Hold the maximum reach position steadily for 2-3 seconds
- ✅ Exhale as you reach forward, maintain progressive stretch

### 5. Visual Progress Indicators

Each angle analysis includes:

- **Color-coded status badge**: Green (Excellent), Light Green (Good), Orange (Fair), Red (Needs Work)
- **Progress bar**: Visual representation of score (0-100%)
- **Percentage display**: Numerical score
- **Description**: Brief explanation of what's being measured

### 6. Overall Quality Score

Comprehensive scoring system (0-100):

#### Score Breakdown

- **Posture (35 points)**:

  - Back Alignment: 15 points
  - Neck Position: 10 points
  - Shoulder Relaxation: 10 points

- **Legs (35 points)**:

  - Knee Extension: 25 points
  - Leg Symmetry: 10 points

- **Reach Technique (30 points)**:
  - Smoothness: 10 points
  - Stability: 10 points
  - Proper Technique: 10 points

#### Quality Ratings

- **Excellent** (85-100): Outstanding form, minimal corrections needed
- **Good** (70-84): Solid form with minor areas for improvement
- **Fair** (55-69): Acceptable form but several issues to address
- **Poor** (<55): Multiple form issues requiring immediate attention

## Technical Implementation

### Rep Counter Logic

```dart
// Sit and Reach Signal Computation
double? _computeSitAndReachSignal(List<Keypoint> keypoints) {
  // Calculate forward reach based on wrist-to-hip distance
  final reachDistance = (wristX - hipX).abs();

  // Normalize: 0.0 = rest, 1.0 = full reach
  // Thresholds: 0.70 (up), 0.25 (down)
  return normalized;
}

// V Sit and Reach adds leg spread bonus
double? _computeVSitAndReachSignal(List<Keypoint> keypoints) {
  // Base reach distance
  final reachDistance = (wristX - hipX).abs();

  // Bonus for proper leg spread (80-120°)
  if (legSpreadAngle >= 80 && legSpreadAngle <= 120) {
    legSpreadBonus = 0.1;
  }

  return normalized + bonus;
}
```

### Pose Analysis Components

#### Multi-Angle Analysis

- **Front View**: Analyzes leg symmetry and alignment
- **Side View**: Evaluates back posture and reach angle
- **Legs**: Measures knee extension quality
- **Upper Body**: Checks shoulder relaxation and neck position

#### Form Metrics Collection

- **Historical tracking**: Maintains last 90 frames (3 seconds at 30fps)
- **Smoothness analysis**: Calculates movement variance
- **Stability assessment**: Evaluates position hold quality
- **Progressive technique**: Measures reach improvement over time

### UI Components

#### Main Display

- Exercise title with type indicator
- Rep counter badge (white translucent with border)
- Reach distance and max reach metrics
- Flexibility score (0-100)
- Overall form quality rating

#### Analysis Sections

1. **Multi-Angle Analysis Box** (white translucent background)

   - Four perspective rows with progress bars
   - Color-coded status badges
   - Descriptive labels

2. **Issues Box** (orange translucent with border)

   - Warning icon header
   - Bulleted list of detected problems
   - Concise issue descriptions

3. **Recommendations Box** (green translucent with border)
   - Lightbulb icon header
   - Arrow-pointed improvement tips
   - Actionable guidance

## Usage Guide

### Getting Started

1. **Select Exercise**: Choose "Sit and Reach" or "V Sit and Reach"
2. **Position Camera**: Place device to capture full body (side angle recommended)
3. **Start Camera**: Tap camera button to begin analysis
4. **Initial Position**: System sets baseline from your starting posture
5. **Perform Exercise**: Reach forward smoothly, hold, and return

### Best Practices

- **Camera Placement**: Side view captures best form data
- **Lighting**: Ensure good lighting for accurate pose detection
- **Clothing**: Wear fitted clothing for better keypoint detection
- **Hold Time**: Maintain maximum reach for 2-3 seconds per rep
- **Breathing**: Exhale while reaching forward, inhale when returning
- **Progression**: Focus on improving form quality before increasing reps

### Interpreting Feedback

- **Green indicators**: Excellent form, keep it up!
- **Yellow/Orange indicators**: Minor issues, check recommendations
- **Red indicators**: Significant form problems, adjust immediately
- **Rep counter**: Each complete cycle (forward + return) = 1 rep
- **Score trends**: Monitor quality score to ensure consistent form

## Benefits

### For Users

- **Immediate Feedback**: Know instantly if form is correct
- **Injury Prevention**: Detect and correct poor posture before issues arise
- **Progress Tracking**: Monitor improvement through rep count and scores
- **Guided Learning**: Step-by-step recommendations for better technique
- **Motivation**: Visual progress indicators encourage proper form

### For Trainers/Coaches

- **Objective Assessment**: Quantifiable metrics for form evaluation
- **Consistent Standards**: Same evaluation criteria for all users
- **Remote Coaching**: Analyze form without physical presence
- **Progress Documentation**: Track improvements over multiple sessions
- **Targeted Corrections**: Specific feedback for each angle/aspect

## Future Enhancements

- **Video playback**: Review past sessions with pose overlay
- **Comparison mode**: Compare current form to previous best
- **Voice feedback**: Audio cues for real-time corrections
- **Export reports**: Detailed PDF reports with analysis
- **Custom thresholds**: Adjust sensitivity for different skill levels
- **Historical trends**: Long-term flexibility progress tracking

## Technical Notes

### Performance

- Real-time analysis at 30 FPS
- Minimal latency (<100ms)
- Efficient pose estimation using MoveNet TFLite
- Optimized UI rendering with selective updates

### Accuracy

- MoveNet provides 17 keypoints with confidence scores
- Minimum confidence threshold: 0.2 (20%)
- Temporal smoothing reduces jitter
- Multiple signals combined for robust detection

### Compatibility

- Flutter cross-platform support
- Camera service for live feed
- Video service for recorded analysis
- Works on Android, iOS, and desktop platforms

---

## Quick Reference

### Rep Counting

- **Up Position**: Wrist extends 35cm+ from hip (70% threshold)
- **Down Position**: Wrist within 15cm of hip (25% threshold)
- **Debounce**: 200ms between transitions to prevent jitter

### Score Ranges

- **85-100**: Excellent ⭐⭐⭐⭐⭐
- **70-84**: Good ⭐⭐⭐⭐
- **55-69**: Fair ⭐⭐⭐
- **<55**: Needs Work ⭐⭐

### Key Angles

- **Back Lean**: 30-60° (optimal forward reach)
- **Knee Extension**: 170-180° (fully straight)
- **Leg Spread (V-Sit)**: 80-120° (proper V formation)
- **Neck Alignment**: <10cm deviation (neutral position)

---

**Version**: 1.0  
**Last Updated**: December 29, 2025  
**Author**: Fitness App Development Team
