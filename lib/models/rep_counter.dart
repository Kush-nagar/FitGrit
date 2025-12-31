/// Exercise-specific rep counter using pose keypoints.
/// Supports push-ups, pull-ups, sit-ups, running, and flexibility tests with configurable thresholds.
/// Tracks rep timeline for video annotation.
import 'dart:math';
import '../models/keypoint.dart';

enum ExerciseType { pushUp, pullUp, sitUp, running, sitAndReach, vSitAndReach }

enum RepState { up, down, transitioning }

class RepCounter {
  final ExerciseType exerciseType;
  int _repCount = 0;
  RepState _currentState = RepState.up;

  // Smoothing window for reducing jitter
  final List<double> _signalHistory = [];
  static const int smoothingWindow = 5;

  // Timeline tracking for video annotation
  final Map<int, int> _repTimeline = {}; // timestamp -> rep count
  final Map<int, RepState> _stateTimeline = {}; // timestamp -> state

  // Configurable thresholds
  double upThreshold;
  double downThreshold;
  double transitionDebounce; // milliseconds

  int _lastTransitionTime = 0;

  RepCounter({
    required this.exerciseType,
    double? upThreshold,
    double? downThreshold,
    this.transitionDebounce = 200,
  })  : upThreshold = upThreshold ?? _getDefaultUpThreshold(exerciseType),
        downThreshold =
            downThreshold ?? _getDefaultDownThreshold(exerciseType) {
    print('RepCounter initialized for $exerciseType');
    print('Thresholds - Up: ${this.upThreshold}, Down: ${this.downThreshold}');
  }

  // Exercise-specific default thresholds
  static double _getDefaultUpThreshold(ExerciseType type) {
    switch (type) {
      case ExerciseType.pushUp:
        return 0.65;
      case ExerciseType.pullUp:
        return 0.70; // Higher threshold for pull-ups (more strict)
      case ExerciseType.sitUp:
        return 0.60; // Moderate threshold for sit-ups (clear sitting position)
      case ExerciseType.running:
        return 0.0; // Running doesn't use rep counting
      case ExerciseType.sitAndReach:
      case ExerciseType.vSitAndReach:
        return 0.70; // Significant forward reach required
    }
  }

  static double _getDefaultDownThreshold(ExerciseType type) {
    switch (type) {
      case ExerciseType.pushUp:
        return 0.35;
      case ExerciseType.pullUp:
        return 0.30; // Lower threshold for pull-ups (ensure full extension)
      case ExerciseType.sitUp:
        return 0.25; // Lower threshold for sit-ups (ensure lying flat)
      case ExerciseType.running:
        return 0.0; // Running doesn't use rep counting
      case ExerciseType.sitAndReach:
      case ExerciseType.vSitAndReach:
        return 0.25; // Return to resting position
    }
  }

  /// Update rep counter with latest keypoints and timestamp.
  /// Returns true if a new rep was completed.
  bool update(List<Keypoint> keypoints, int timestampMillis) {
    final signal = _computeExerciseSignal(keypoints);

    if (signal == null) {
      // Unable to compute signal (missing keypoints)
      if (_repTimeline.isEmpty) {
        print('⚠ Signal null - missing keypoints at ${timestampMillis}ms');
      }
      return false;
    }

    // Apply smoothing
    _signalHistory.add(signal);
    if (_signalHistory.length > smoothingWindow) {
      _signalHistory.removeAt(0);
    }
    final smoothedSignal =
        _signalHistory.reduce((a, b) => a + b) / _signalHistory.length;

    // Enhanced debug logging for pull-ups and sit-ups
    if (_repTimeline.length % 10 == 0) {
      if (exerciseType == ExerciseType.pullUp) {
        print(
            '🏋️ Pull-up Signal: ${signal.toStringAsFixed(3)}, Smoothed: ${smoothedSignal.toStringAsFixed(3)}, '
            'State: $_currentState, Reps: $_repCount, '
            'Up threshold: ${upThreshold.toStringAsFixed(2)}, Down threshold: ${downThreshold.toStringAsFixed(2)}');
      } else if (exerciseType == ExerciseType.sitUp) {
        print(
            '🧘 Sit-up Signal: ${signal.toStringAsFixed(3)}, Smoothed: ${smoothedSignal.toStringAsFixed(3)}, '
            'State: $_currentState, Reps: $_repCount, '
            'Up threshold: ${upThreshold.toStringAsFixed(2)}, Down threshold: ${downThreshold.toStringAsFixed(2)}');
      } else {
        print(
            'Signal: ${signal.toStringAsFixed(3)}, Smoothed: ${smoothedSignal.toStringAsFixed(3)}, '
            'State: $_currentState, Reps: $_repCount');
      }
    }

    // Debounce transitions (skip debounce for the very first update)
    final timeSinceLastTransition = timestampMillis - _lastTransitionTime;
    final isFirstUpdate = _repTimeline.isEmpty;
    if (!isFirstUpdate && timeSinceLastTransition < transitionDebounce) {
      _repTimeline[timestampMillis] = _repCount;
      _stateTimeline[timestampMillis] = _currentState;
      return false;
    }

    // State machine logic
    bool repCompleted = false;

    if (_currentState == RepState.up && smoothedSignal < downThreshold) {
      _currentState = RepState.down;
      _lastTransitionTime = timestampMillis;
      print(
          '✓ Transition to DOWN at ${timestampMillis}ms, signal: ${smoothedSignal.toStringAsFixed(3)}');
    } else if (_currentState == RepState.down && smoothedSignal > upThreshold) {
      _currentState = RepState.up;
      _repCount++;
      _lastTransitionTime = timestampMillis;
      repCompleted = true;
      print(
          '✓ REP COMPLETED! Count: $_repCount at ${timestampMillis}ms, signal: ${smoothedSignal.toStringAsFixed(3)}');
    }

    // Record timeline
    _repTimeline[timestampMillis] = _repCount;
    _stateTimeline[timestampMillis] = _currentState;

    return repCompleted;
  }

  /// Compute exercise-specific signal from keypoints.
  /// Returns normalized value 0.0 (down) to 1.0 (up), or null if insufficient data.
  double? _computeExerciseSignal(List<Keypoint> keypoints) {
    switch (exerciseType) {
      case ExerciseType.pushUp:
        return _computePushUpSignal(keypoints);
      case ExerciseType.pullUp:
        return _computePullUpSignal(keypoints);
      case ExerciseType.sitUp:
        return _computeSitUpSignal(keypoints);
      case ExerciseType.running:
        return null; // Running doesn't use rep counting
      case ExerciseType.sitAndReach:
        return _computeSitAndReachSignal(keypoints);
      case ExerciseType.vSitAndReach:
        return _computeVSitAndReachSignal(keypoints);
    }
  }

  /// Push-up signal: elbow angle (straight = up, bent = down)
  double? _computePushUpSignal(List<Keypoint> keypoints) {
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final leftElbow = _findKeypoint(keypoints, KeypointNames.leftElbow);
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final rightElbow = _findKeypoint(keypoints, KeypointNames.rightElbow);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);

    // Check if we have at least one side visible
    final hasLeft =
        leftShoulder != null && leftElbow != null && leftWrist != null;
    final hasRight =
        rightShoulder != null && rightElbow != null && rightWrist != null;

    if (!hasLeft && !hasRight) {
      return null;
    }

    // Calculate elbow angles (use available side or average both)
    double avgAngle;
    if (hasLeft && hasRight) {
      final leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      final rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      avgAngle = (leftAngle + rightAngle) / 2;
    } else if (hasLeft) {
      avgAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    } else {
      avgAngle = _calculateAngle(rightShoulder!, rightElbow!, rightWrist!);
    }

    // Normalize: 160°+ (straight/up) = 1.0, 80° (bent/down) = 0.0
    // Adjusted range for more realistic push-up angles
    final normalized = ((avgAngle - 80) / 80).clamp(0.0, 1.0);
    return normalized;
  }

  /// Pull-up signal: combined metric using shoulder-wrist distance and elbow extension
  double? _computePullUpSignal(List<Keypoint> keypoints) {
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);
    final leftElbow = _findKeypoint(keypoints, KeypointNames.leftElbow);
    final rightElbow = _findKeypoint(keypoints, KeypointNames.rightElbow);

    // Require at least shoulders and wrists
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null) {
      return null;
    }

    // Primary signal: vertical distance between shoulders and wrists
    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final wristY = (leftWrist.y + rightWrist.y) / 2;

    // In pull-ups, shoulders are always below wrists (higher Y value)
    // Down (hanging): large distance, Up (pulled up): small distance
    final distance = shoulderY - wristY;

    // Normalized coordinates: typical pull-up ranges
    // Up position: 0.05-0.10 distance (close to bar)
    // Down position: 0.20-0.40 distance (fully extended)
    // We use 0.35 as max to handle both test and real-world scenarios
    const maxDistance = 0.35;
    const minDistance = 0.05;
    final distanceSignal =
        (1.0 - ((distance - minDistance) / (maxDistance - minDistance)))
            .clamp(0.0, 1.0);

    // Secondary signal: elbow angle (if available)
    // Up position: elbows more bent (~90-110°), Down: elbows straighter (~160-180°)
    double? elbowSignal;
    final hasLeftElbow = leftElbow != null;
    final hasRightElbow = rightElbow != null;

    if (hasLeftElbow && hasRightElbow) {
      final leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      final rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      final avgAngle = (leftAngle + rightAngle) / 2;
      // 90° (bent/up) = 1.0, 180° (straight/down) = 0.0
      elbowSignal = (1.0 - (avgAngle - 90) / 90).clamp(0.0, 1.0);
    } else if (hasLeftElbow) {
      final angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      elbowSignal = (1.0 - (angle - 90) / 90).clamp(0.0, 1.0);
    } else if (hasRightElbow) {
      final angle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      elbowSignal = (1.0 - (angle - 90) / 90).clamp(0.0, 1.0);
    }

    // Combine signals: prioritize distance, use elbow as confirmation
    final normalized = elbowSignal != null
        ? (distanceSignal * 0.7 + elbowSignal * 0.3) // Weighted average
        : distanceSignal; // Distance only if elbows not visible

    return normalized;
  }

  /// Sit-up signal: combined metrics using torso angle and vertical position
  double? _computeSitUpSignal(List<Keypoint> keypoints) {
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final leftKnee = _findKeypoint(keypoints, KeypointNames.leftKnee);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);
    final rightKnee = _findKeypoint(keypoints, KeypointNames.rightKnee);

    // Require at least hips and shoulders
    if ((leftShoulder == null && rightShoulder == null) ||
        (leftHip == null && rightHip == null)) {
      return null;
    }

    // Calculate average positions
    final shoulderY = leftShoulder != null && rightShoulder != null
        ? (leftShoulder.y + rightShoulder.y) / 2
        : (leftShoulder?.y ?? rightShoulder!.y);

    final hipY = leftHip != null && rightHip != null
        ? (leftHip.y + rightHip.y) / 2
        : (leftHip?.y ?? rightHip!.y);

    // Primary signal: vertical distance between shoulders and hips
    // Sitting up: shoulders higher (lower Y value), Lying down: shoulders lower (higher Y value)
    final verticalDistance = (shoulderY - hipY).abs();

    // When sitting up, shoulders are significantly above hips (distance 0.15-0.25)
    // When lying down, shoulders are nearly level with hips (distance 0.02-0.08)
    const maxDistance = 0.25; // Sitting up
    const minDistance = 0.02; // Lying down
    final verticalSignal =
        ((verticalDistance - minDistance) / (maxDistance - minDistance))
            .clamp(0.0, 1.0);

    // Secondary signal: hip angle (if knees are visible)
    double? hipAngleSignal;
    final hasLeft = leftShoulder != null && leftHip != null && leftKnee != null;
    final hasRight =
        rightShoulder != null && rightHip != null && rightKnee != null;

    if (hasLeft && hasRight) {
      final leftAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);
      final rightAngle = _calculateAngle(rightShoulder, rightHip, rightKnee);
      final avgAngle = (leftAngle + rightAngle) / 2;
      // 60°-80° (sitting up, torso bent forward) = 1.0, 150°-180° (lying flat) = 0.0
      hipAngleSignal = (1.0 - (avgAngle - 60) / 100).clamp(0.0, 1.0);
    } else if (hasLeft) {
      final angle = _calculateAngle(leftShoulder, leftHip, leftKnee);
      hipAngleSignal = (1.0 - (angle - 60) / 100).clamp(0.0, 1.0);
    } else if (hasRight) {
      final angle = _calculateAngle(rightShoulder, rightHip, rightKnee);
      hipAngleSignal = (1.0 - (angle - 60) / 100).clamp(0.0, 1.0);
    }

    // Combine signals: prioritize vertical distance (more reliable), use hip angle as confirmation
    final normalized = hipAngleSignal != null
        ? (verticalSignal * 0.75 + hipAngleSignal * 0.25) // Weighted average
        : verticalSignal; // Distance only if knees not visible

    return normalized;
  }

  /// Sit-and-reach signal: forward reach based on wrist horizontal position
  double? _computeSitAndReachSignal(List<Keypoint> keypoints) {
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);

    // Need at least wrists and hips
    if ((leftWrist == null && rightWrist == null) ||
        (leftHip == null && rightHip == null)) {
      return null;
    }

    // Calculate average wrist and hip positions
    final wristX = leftWrist != null && rightWrist != null
        ? (leftWrist.x + rightWrist.x) / 2
        : (leftWrist?.x ?? rightWrist!.x);

    final hipX = leftHip != null && rightHip != null
        ? (leftHip.x + rightHip.x) / 2
        : (leftHip?.x ?? rightHip!.x);

    // Calculate forward reach distance (wrist ahead of hip)
    final reachDistance = (wristX - hipX).abs();

    // Normalize: 0.0-0.15 is resting, 0.3+ is full reach
    const minReach = 0.0;
    const maxReach = 0.35;
    final normalized =
        ((reachDistance - minReach) / (maxReach - minReach)).clamp(0.0, 1.0);

    return normalized;
  }

  /// V-sit-and-reach signal: similar to sit-and-reach with leg spread consideration
  double? _computeVSitAndReachSignal(List<Keypoint> keypoints) {
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);
    final leftKnee = _findKeypoint(keypoints, KeypointNames.leftKnee);
    final rightKnee = _findKeypoint(keypoints, KeypointNames.rightKnee);

    // Need at least wrists and hips
    if ((leftWrist == null && rightWrist == null) ||
        (leftHip == null && rightHip == null)) {
      return null;
    }

    // Calculate average wrist and hip positions
    final wristX = leftWrist != null && rightWrist != null
        ? (leftWrist.x + rightWrist.x) / 2
        : (leftWrist?.x ?? rightWrist!.x);

    final hipX = leftHip != null && rightHip != null
        ? (leftHip.x + rightHip.x) / 2
        : (leftHip?.x ?? rightHip!.x);

    // Calculate forward reach distance
    final reachDistance = (wristX - hipX).abs();

    // Optional: factor in leg spread for V-sit-and-reach
    double legSpreadBonus = 0.0;
    if (leftKnee != null && rightKnee != null && leftHip != null) {
      final legSpreadAngle = _calculateAngle(leftKnee, leftHip, rightKnee);
      // Wider spread (80-120°) adds bonus to reach signal
      if (legSpreadAngle >= 80 && legSpreadAngle <= 120) {
        legSpreadBonus = 0.1;
      }
    }

    // Normalize: 0.0-0.15 is resting, 0.3+ is full reach
    const minReach = 0.0;
    const maxReach = 0.35;
    final normalized =
        ((reachDistance - minReach) / (maxReach - minReach) + legSpreadBonus)
            .clamp(0.0, 1.0);

    return normalized;
  }

  /// Calculate angle between three points (in degrees)
  double _calculateAngle(Keypoint a, Keypoint b, Keypoint c) {
    final ba = Point(a.x - b.x, a.y - b.y);
    final bc = Point(c.x - b.x, c.y - b.y);

    final dot = ba.x * bc.x + ba.y * bc.y;
    final magBA = sqrt(ba.x * ba.x + ba.y * ba.y);
    final magBC = sqrt(bc.x * bc.x + bc.y * bc.y);

    if (magBA == 0 || magBC == 0) return 0;

    final cos = (dot / (magBA * magBC)).clamp(-1.0, 1.0);
    final angle = acos(cos) * 180 / pi;
    return angle;
  }

  Keypoint? _findKeypoint(List<Keypoint> keypoints, String name) {
    try {
      final kp = keypoints.firstWhere((kp) => kp.name == name);
      // Only return if confidence is reasonable
      return kp.confidence > 0.2 ? kp : null;
    } catch (_) {
      return null;
    }
  }

  /// Get rep count at specific timestamp (for video annotation)
  int getRepCountAt(int timestampMillis) {
    // Find closest timestamp in timeline
    if (_repTimeline.isEmpty) return 0;

    final timestamps = _repTimeline.keys.toList()..sort();
    final closest = timestamps.reduce((a, b) =>
        (a - timestampMillis).abs() < (b - timestampMillis).abs() ? a : b);

    return _repTimeline[closest] ?? 0;
  }

  /// Get state at specific timestamp
  RepState getStateAt(int timestampMillis) {
    if (_stateTimeline.isEmpty) return RepState.up;

    final timestamps = _stateTimeline.keys.toList()..sort();
    final closest = timestamps.reduce((a, b) =>
        (a - timestampMillis).abs() < (b - timestampMillis).abs() ? a : b);

    return _stateTimeline[closest] ?? RepState.up;
  }

  /// Reset counter
  void reset() {
    _repCount = 0;
    _currentState = RepState.up;
    _signalHistory.clear();
    _repTimeline.clear();
    _stateTimeline.clear();
    _lastTransitionTime = 0;
  }

  /// Create snapshot of current state for frame annotation
  Map<String, dynamic> snapshot({int? timestampMillis}) {
    return {
      'repCount':
          timestampMillis != null ? getRepCountAt(timestampMillis) : _repCount,
      'state': (timestampMillis != null
              ? getStateAt(timestampMillis)
              : _currentState)
          .toString()
          .split('.')
          .last,
      'exerciseType': exerciseType.toString().split('.').last,
    };
  }

  int get repCount => _repCount;
  RepState get currentState => _currentState;
  Map<int, int> get repTimeline => Map.unmodifiable(_repTimeline);
}
