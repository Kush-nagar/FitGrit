/// Service for calculating shuttle run metrics from video analysis.
/// Tracks distance, speed, direction changes, and timing.
import 'dart:math';
import '../models/keypoint.dart';

/// Shuttle run performance metrics
class ShuttleRunPerformanceMetrics {
  final double totalDistance; // meters
  final double totalTime; // seconds
  final int completedRuns; // number of one-way runs
  final double averageRunTime; // seconds per run
  final double averageSpeed; // m/s
  final double maxSpeed; // m/s
  final double peakSpeedTime; // when max speed occurred (seconds)
  final List<double> runTimes; // time for each individual run
  final List<double> speedProfile; // speed over time
  final double shuttleDistance; // distance of one shuttle (meters)
  final int directionChanges; // number of turns
  final double averageTurnTime; // average time per turn (seconds)

  ShuttleRunPerformanceMetrics({
    required this.totalDistance,
    required this.totalTime,
    required this.completedRuns,
    required this.averageRunTime,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.peakSpeedTime,
    required this.runTimes,
    required this.speedProfile,
    required this.shuttleDistance,
    required this.directionChanges,
    required this.averageTurnTime,
  });

  @override
  String toString() {
    return '''
Shuttle Run Performance:
├─ Total Distance: ${totalDistance.toStringAsFixed(2)}m
├─ Total Time: ${totalTime.toStringAsFixed(2)}s
├─ Completed Runs: $completedRuns
├─ Avg Run Time: ${averageRunTime.toStringAsFixed(2)}s
├─ Avg Speed: ${averageSpeed.toStringAsFixed(2)} m/s
├─ Max Speed: ${maxSpeed.toStringAsFixed(2)} m/s
├─ Direction Changes: $directionChanges
├─ Avg Turn Time: ${averageTurnTime.toStringAsFixed(2)}s
└─ Shuttle Distance: ${shuttleDistance.toStringAsFixed(1)}m
''';
  }

  String formatRunTime(double seconds) {
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).toStringAsFixed(1);
    return '${mins}:${secs.padLeft(4, '0')}';
  }
}

class ShuttleRunMetricsCalculator {
  // Configuration
  final double shuttleDistance; // meters (typical: 20m, 10m, or 5m)
  final double videoFps; // frames per second

  // Historical data
  final List<List<Keypoint>> _poseHistory = [];
  final List<int> _timestampHistory = [];
  final List<double> _hipXPositions = [];
  final List<double> _speeds = [];

  // Direction tracking
  final List<int> _directionChangeTimestamps = [];
  String _lastDirection = 'stationary'; // 'left', 'right', 'stationary'

  // Calibration
  double? _minX;
  double? _maxX;
  double _normalizedToMeters = 1.0;

  ShuttleRunMetricsCalculator({
    this.shuttleDistance = 20.0, // default 20m shuttle
    this.videoFps = 30.0,
  });

  /// Add a frame to the calculator
  void addFrame(List<Keypoint> keypoints) {
    _poseHistory.add(keypoints);
    _timestampHistory.add(DateTime.now().millisecondsSinceEpoch);

    // Track hip position
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);

    if (leftHip != null && rightHip != null) {
      final hipX = (leftHip.x + rightHip.x) / 2;
      _hipXPositions.add(hipX);

      // Update min/max for calibration
      if (_minX == null || hipX < _minX!) _minX = hipX;
      if (_maxX == null || hipX > _maxX!) _maxX = hipX;

      // Calibrate normalized coordinates to real distance
      if (_minX != null && _maxX != null) {
        final normalizedWidth = _maxX! - _minX!;
        if (normalizedWidth > 0.1) {
          // Only calibrate if we have significant movement
          _normalizedToMeters = shuttleDistance / normalizedWidth;
        }
      }

      // Detect direction changes
      _detectDirectionChange(hipX);
    }

    // Calculate instantaneous speed
    if (_hipXPositions.length >= 5) {
      final i = _hipXPositions.length - 1;
      final deltaPos = (_hipXPositions[i] - _hipXPositions[i - 4]).abs();
      final deltaTime =
          (_timestampHistory[i] - _timestampHistory[i - 4]) / 1000.0;

      if (deltaTime > 0) {
        final speed = (deltaPos * _normalizedToMeters) / deltaTime;
        _speeds.add(speed);
      }
    }
  }

  /// Detect direction changes
  void _detectDirectionChange(double currentX) {
    if (_hipXPositions.length < 10) return;

    // Look at recent movement
    final recentPositions = _hipXPositions.sublist(_hipXPositions.length - 10);
    final movementDelta = recentPositions.last - recentPositions.first;

    String currentDirection;
    if (movementDelta > 0.02) {
      currentDirection = 'right';
    } else if (movementDelta < -0.02) {
      currentDirection = 'left';
    } else {
      currentDirection = 'stationary';
    }

    // Detect actual direction change (not including stationary)
    if (currentDirection != _lastDirection &&
        currentDirection != 'stationary' &&
        _lastDirection != 'stationary') {
      _directionChangeTimestamps.add(_timestampHistory.last);
    }

    _lastDirection = currentDirection;
  }

  /// Calculate all metrics
  ShuttleRunPerformanceMetrics calculateMetrics() {
    if (_timestampHistory.isEmpty) {
      return _createDefaultMetrics();
    }

    // Calculate total time
    final totalTimeMs = _timestampHistory.last - _timestampHistory.first;
    final totalTime = totalTimeMs / 1000.0;

    // Calculate total distance
    double totalDistance = 0.0;
    for (int i = 1; i < _hipXPositions.length; i++) {
      final deltaPos = (_hipXPositions[i] - _hipXPositions[i - 1]).abs();
      totalDistance += deltaPos * _normalizedToMeters;
    }

    // Calculate completed runs (direction changes + 1)
    final completedRuns = _directionChangeTimestamps.length + 1;

    // Calculate run times
    final runTimes = <double>[];
    if (_directionChangeTimestamps.isNotEmpty) {
      // First run
      final firstRunTime =
          (_directionChangeTimestamps.first - _timestampHistory.first) / 1000.0;
      runTimes.add(firstRunTime);

      // Intermediate runs
      for (int i = 1; i < _directionChangeTimestamps.length; i++) {
        final runTime = (_directionChangeTimestamps[i] -
                _directionChangeTimestamps[i - 1]) /
            1000.0;
        runTimes.add(runTime);
      }

      // Last run (if not finished)
      if (_timestampHistory.isNotEmpty) {
        final lastRunTime =
            (_timestampHistory.last - _directionChangeTimestamps.last) / 1000.0;
        if (lastRunTime > 0.5) {
          // Only add if significant
          runTimes.add(lastRunTime);
        }
      }
    }

    // Average run time
    final averageRunTime = runTimes.isNotEmpty
        ? runTimes.reduce((a, b) => a + b) / runTimes.length
        : 0.0;

    // Speed metrics
    final avgSpeed = totalTime > 0 ? totalDistance / totalTime : 0.0;
    final maxSpeed =
        _speeds.isNotEmpty ? _speeds.reduce((a, b) => a > b ? a : b) : 0.0;

    // Find when peak speed occurred
    double peakSpeedTime = 0.0;
    if (_speeds.isNotEmpty && maxSpeed > 0) {
      final peakIndex = _speeds.indexOf(maxSpeed);
      if (peakIndex >= 0 && peakIndex < _timestampHistory.length) {
        peakSpeedTime =
            (_timestampHistory[peakIndex + 4] - _timestampHistory.first) /
                1000.0;
      }
    }

    // Calculate average turn time
    final avgTurnTime = _directionChangeTimestamps.length > 1
        ? totalTime / _directionChangeTimestamps.length
        : 0.0;

    return ShuttleRunPerformanceMetrics(
      totalDistance: totalDistance,
      totalTime: totalTime,
      completedRuns: completedRuns,
      averageRunTime: averageRunTime,
      averageSpeed: avgSpeed,
      maxSpeed: maxSpeed,
      peakSpeedTime: peakSpeedTime,
      runTimes: runTimes,
      speedProfile: List.from(_speeds),
      shuttleDistance: shuttleDistance,
      directionChanges: _directionChangeTimestamps.length,
      averageTurnTime: avgTurnTime,
    );
  }

  /// Create default metrics when no data
  ShuttleRunPerformanceMetrics _createDefaultMetrics() {
    return ShuttleRunPerformanceMetrics(
      totalDistance: 0.0,
      totalTime: 0.0,
      completedRuns: 0,
      averageRunTime: 0.0,
      averageSpeed: 0.0,
      maxSpeed: 0.0,
      peakSpeedTime: 0.0,
      runTimes: [],
      speedProfile: [],
      shuttleDistance: shuttleDistance,
      directionChanges: 0,
      averageTurnTime: 0.0,
    );
  }

  /// Helper: Find keypoint by name
  Keypoint? _findKeypoint(List<Keypoint> keypoints, String name) {
    try {
      return keypoints.firstWhere(
        (kp) => kp.name == name,
        orElse: () => throw StateError('Not found'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Reset calculator
  void reset() {
    _poseHistory.clear();
    _timestampHistory.clear();
    _hipXPositions.clear();
    _speeds.clear();
    _directionChangeTimestamps.clear();
    _minX = null;
    _maxX = null;
    _normalizedToMeters = 1.0;
    _lastDirection = 'stationary';
  }

  /// Set shuttle distance for calibration
  void setShuttleDistance(double distance) {
    // Update calibration if we already have data
    if (_minX != null && _maxX != null) {
      final normalizedWidth = _maxX! - _minX!;
      if (normalizedWidth > 0.1) {
        _normalizedToMeters = distance / normalizedWidth;
      }
    }
  }
}
