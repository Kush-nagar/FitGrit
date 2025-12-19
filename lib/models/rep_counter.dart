/// Exercise-specific rep counter using pose keypoints.
/// Supports push-ups, pull-ups, and sit-ups with configurable thresholds.
/// Tracks rep timeline for video annotation.
import 'dart:math';
import '../models/keypoint.dart';

enum ExerciseType { pushUp, pullUp, sitUp }

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
    this.upThreshold = 0.65,
    this.downThreshold = 0.35,
    this.transitionDebounce = 200,
  }) {
    print('RepCounter initialized for $exerciseType');
    print('Thresholds - Up: $upThreshold, Down: $downThreshold');
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

    // Debug logging every 10 frames
    if (_repTimeline.length % 10 == 0) {
      print(
          'Signal: ${signal.toStringAsFixed(3)}, Smoothed: ${smoothedSignal.toStringAsFixed(3)}, State: $_currentState, Reps: $_repCount');
    }

    // Debounce transitions
    final timeSinceLastTransition = timestampMillis - _lastTransitionTime;
    if (timeSinceLastTransition < transitionDebounce) {
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

  /// Pull-up signal: body height (shoulders relative to wrists)
  double? _computePullUpSignal(List<Keypoint> keypoints) {
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftWrist == null ||
        rightWrist == null) {
      return null;
    }

    // Calculate vertical distance between shoulders and wrists
    final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final wristY = (leftWrist.y + rightWrist.y) / 2;
    final distance = (wristY - shoulderY).abs();

    // Normalize: close to wrists (up) = 1.0, far from wrists (down) = 0.0
    // Typical range: 0.1 (up) to 0.4 (down) in normalized coordinates
    final normalized = (1.0 - (distance / 0.4)).clamp(0.0, 1.0);
    return normalized;
  }

  /// Sit-up signal: hip-shoulder angle (sitting up = high, lying down = low)
  double? _computeSitUpSignal(List<Keypoint> keypoints) {
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final leftKnee = _findKeypoint(keypoints, KeypointNames.leftKnee);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);
    final rightKnee = _findKeypoint(keypoints, KeypointNames.rightKnee);

    // Check if we have at least one side visible
    final hasLeft = leftShoulder != null && leftHip != null && leftKnee != null;
    final hasRight =
        rightShoulder != null && rightHip != null && rightKnee != null;

    if (!hasLeft && !hasRight) {
      return null;
    }

    // Calculate hip angles (use available side or average both)
    double avgAngle;
    if (hasLeft && hasRight) {
      final leftAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);
      final rightAngle = _calculateAngle(rightShoulder, rightHip, rightKnee);
      avgAngle = (leftAngle + rightAngle) / 2;
    } else if (hasLeft) {
      avgAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);
    } else {
      avgAngle = _calculateAngle(rightShoulder!, rightHip!, rightKnee!);
    }

    // Normalize: 70°-90° (sitting up) = 1.0, 160°+ (lying down) = 0.0
    // Adjusted range for more realistic sit-up angles
    final normalized = (1.0 - (avgAngle - 70) / 90).clamp(0.0, 1.0);
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
