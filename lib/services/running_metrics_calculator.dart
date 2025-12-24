/// Service for calculating running pace and speed from video analysis.
/// Uses pose estimation and frame timestamps to calculate accurate metrics.
import 'dart:math';
import '../models/keypoint.dart';

/// Running metrics calculated from video
class RunningMetrics {
  final double totalDistance; // meters
  final double totalTime; // seconds
  final double averagePace; // minutes per km
  final double averageSpeed; // km/h
  final double instantaneousSpeed; // current speed in km/h
  final double maxSpeed; // peak speed in km/h
  final List<double> speedProfile; // speed over time

  RunningMetrics({
    required this.totalDistance,
    required this.totalTime,
    required this.averagePace,
    required this.averageSpeed,
    required this.instantaneousSpeed,
    required this.maxSpeed,
    required this.speedProfile,
  });

  @override
  String toString() {
    return '''
Running Metrics:
├─ Distance: ${totalDistance.toStringAsFixed(2)}m
├─ Time: ${(totalTime / 60).toStringAsFixed(2)} min
├─ Avg Pace: ${_formatPace(averagePace)} /km
├─ Avg Speed: ${averageSpeed.toStringAsFixed(2)} km/h
└─ Max Speed: ${maxSpeed.toStringAsFixed(2)} km/h
''';
  }

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm == 0 || paceMinPerKm.isInfinite) return '--:--';
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

class RunningMetricsCalculator {
  // Configuration
  final double runnerHeight; // meters (used to calibrate stride length)
  final double videoFps; // frames per second of video

  // Historical data
  final List<List<Keypoint>> _poseHistory = [];
  final List<int> _timestampHistory = [];
  final List<double> _speeds = [];

  // Calibration factors
  double _strideCalibrationFactor = 1.0;

  RunningMetricsCalculator({
    this.runnerHeight = 1.75, // default height in meters
    this.videoFps = 30.0,
  }) {
    // Calibrate stride length based on runner height
    // Average stride length is approximately 1.14 * height for running
    _strideCalibrationFactor = runnerHeight * 1.14;
  }

  /// Add a frame to the analysis
  void addFrame(List<Keypoint> keypoints, int timestamp) {
    _poseHistory.add(keypoints);
    _timestampHistory.add(timestamp);
  }

  /// Calculate running metrics from accumulated frames
  RunningMetrics calculateMetrics() {
    if (_poseHistory.length < 10) {
      return _createDefaultMetrics();
    }

    // Calculate distance traveled
    final distance = _calculateTotalDistance();

    // Calculate time
    final timeSeconds =
        (_timestampHistory.last - _timestampHistory.first) / 1000.0;

    // Calculate speeds
    _calculateSpeedProfile();

    final avgSpeed = distance > 0 && timeSeconds > 0
        ? (distance / 1000.0) / (timeSeconds / 3600.0) // km/h
        : 0.0;

    final avgPace = avgSpeed > 0 ? 60.0 / avgSpeed : 0.0; // min/km

    final instantSpeed = _speeds.isNotEmpty ? _speeds.last : 0.0;
    final maxSpeed =
        _speeds.isNotEmpty ? _speeds.reduce((a, b) => a > b ? a : b) : 0.0;

    return RunningMetrics(
      totalDistance: distance,
      totalTime: timeSeconds,
      averagePace: avgPace,
      averageSpeed: avgSpeed,
      instantaneousSpeed: instantSpeed,
      maxSpeed: maxSpeed,
      speedProfile: List.from(_speeds),
    );
  }

  /// Calculate total distance by tracking body movement
  double _calculateTotalDistance() {
    if (_poseHistory.length < 2) return 0.0;

    double totalDistance = 0.0;

    // Track hip midpoint movement as proxy for body movement
    for (int i = 1; i < _poseHistory.length; i++) {
      final prevHip = _getHipMidpoint(_poseHistory[i - 1]);
      final currHip = _getHipMidpoint(_poseHistory[i]);

      if (prevHip != null && currHip != null) {
        // Calculate horizontal movement (assuming camera is stationary side view)
        final dx = (currHip.x - prevHip.x).abs();

        // Convert normalized coordinates to actual distance
        // This is a simplified model - in practice, you'd need camera calibration
        // Assume the person occupies about 0.5 of frame width at their height
        final frameWidth = runnerHeight / 0.5;
        final distanceMeters = dx * frameWidth * _strideCalibrationFactor;

        // Only add if movement is significant (filter out noise)
        if (distanceMeters > 0.001 && distanceMeters < 0.5) {
          totalDistance += distanceMeters;
        }
      }
    }

    return totalDistance;
  }

  /// Calculate speed profile over time
  void _calculateSpeedProfile() {
    _speeds.clear();

    // Use sliding window to calculate instantaneous speed
    const windowSize = 5; // frames

    for (int i = windowSize; i < _poseHistory.length; i++) {
      final startIdx = i - windowSize;
      final endIdx = i;

      final startHip = _getHipMidpoint(_poseHistory[startIdx]);
      final endHip = _getHipMidpoint(_poseHistory[endIdx]);

      if (startHip != null && endHip != null) {
        // Distance traveled in this window
        final dx = (endHip.x - startHip.x).abs();
        final frameWidth = runnerHeight / 0.5;
        final distanceMeters = dx * frameWidth * _strideCalibrationFactor;

        // Time for this window
        final timeSeconds =
            (_timestampHistory[endIdx] - _timestampHistory[startIdx]) / 1000.0;

        // Speed in km/h
        final speed = timeSeconds > 0
            ? (distanceMeters / 1000.0) / (timeSeconds / 3600.0)
            : 0.0;

        // Clamp to reasonable running speeds (0-40 km/h)
        _speeds.add(speed.clamp(0.0, 40.0));
      } else {
        // No valid data, use previous speed or 0
        _speeds.add(_speeds.isNotEmpty ? _speeds.last : 0.0);
      }
    }
  }

  /// Calculate stride frequency from ankle movement
  double calculateCadence() {
    if (_poseHistory.length < 20) return 0.0;

    // Track left ankle vertical position
    final leftAnkleY = <double>[];

    for (var pose in _poseHistory) {
      final ankle = _findKeypoint(pose, KeypointNames.leftAnkle);
      if (ankle != null) {
        leftAnkleY.add(ankle.y);
      }
    }

    if (leftAnkleY.isEmpty) return 0.0;

    // Count peaks (foot strikes)
    int strikes = 0;
    for (int i = 1; i < leftAnkleY.length - 1; i++) {
      if (leftAnkleY[i] > leftAnkleY[i - 1] &&
          leftAnkleY[i] > leftAnkleY[i + 1]) {
        if (leftAnkleY[i] - leftAnkleY[i - 1] > 0.02) {
          strikes++;
        }
      }
    }

    // Calculate cadence (steps per minute)
    final timeSeconds =
        (_timestampHistory.last - _timestampHistory.first) / 1000.0;
    final cadence = timeSeconds > 0 ? (strikes * 2 * 60.0) / timeSeconds : 0.0;

    return cadence;
  }

  /// Estimate stride length from current pose
  double estimateStrideLength(List<Keypoint> keypoints) {
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final leftAnkle = _findKeypoint(keypoints, KeypointNames.leftAnkle);

    if (leftHip == null || leftAnkle == null) return 0.0;

    // Calculate leg length
    final legLength = _calculateDistance(leftHip, leftAnkle);

    // Stride length is approximately 2x leg length when running
    // Multiply by calibration factor
    return legLength * 2.0 * _strideCalibrationFactor;
  }

  /// Calculate pace from speed
  String formatPace(double speedKmh) {
    if (speedKmh <= 0) return '--:--';

    final paceMinPerKm = 60.0 / speedKmh;
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();

    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get hip midpoint from keypoints
  Keypoint? _getHipMidpoint(List<Keypoint> keypoints) {
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);

    if (leftHip == null || rightHip == null) return null;

    return Keypoint(
      name: 'hip_midpoint',
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      confidence: (leftHip.confidence + rightHip.confidence) / 2,
    );
  }

  /// Find specific keypoint by name
  Keypoint? _findKeypoint(List<Keypoint> keypoints, String name) {
    try {
      return keypoints.firstWhere((kp) => kp.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two keypoints
  double _calculateDistance(Keypoint p1, Keypoint p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Create default metrics when not enough data
  RunningMetrics _createDefaultMetrics() {
    return RunningMetrics(
      totalDistance: 0.0,
      totalTime: 0.0,
      averagePace: 0.0,
      averageSpeed: 0.0,
      instantaneousSpeed: 0.0,
      maxSpeed: 0.0,
      speedProfile: [],
    );
  }

  /// Reset calculator
  void reset() {
    _poseHistory.clear();
    _timestampHistory.clear();
    _speeds.clear();
  }

  /// Set runner height for calibration
  void setRunnerHeight(double heightMeters) {
    _strideCalibrationFactor = heightMeters * 1.14;
  }

  /// Get current progress
  Map<String, dynamic> getProgress() {
    final metrics = calculateMetrics();
    final cadence = calculateCadence();

    return {
      'framesProcessed': _poseHistory.length,
      'distance': metrics.totalDistance,
      'time': metrics.totalTime,
      'avgSpeed': metrics.averageSpeed,
      'currentSpeed': metrics.instantaneousSpeed,
      'cadence': cadence,
    };
  }
}
