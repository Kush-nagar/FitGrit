/// Shuttle run analyzer that evaluates shuttle run technique and performance.
/// Analyzes direction changes, speed consistency, and overall form quality.
import 'dart:math';
import 'keypoint.dart';

/// Direction of movement
enum Direction {
  left,
  right,
  stationary,
}

/// Shuttle run form quality rating
enum ShuttleFormQuality {
  excellent,
  good,
  fair,
  poor,
}

/// Metrics for shuttle run analysis
class ShuttleRunMetrics {
  // Direction change metrics
  final int directionChanges; // number of turns
  final List<double> turnTimes; // time between direction changes (seconds)
  final double averageTurnTime; // average time per turn
  final double turnEfficiency; // 0-1, how well turns are executed

  // Speed metrics
  final double averageSpeed; // m/s
  final double maxSpeed; // m/s
  final double speedConsistency; // 0-1, how consistent speed is
  final List<double> speedProfile; // speed over time

  // Form metrics
  final double bodyLean; // degrees, proper lean during turns
  final double armSwing; // 0-1, arm movement quality
  final double deceleration; // how well they decelerate before turns

  // Overall assessment
  final ShuttleFormQuality overallQuality;
  final double qualityScore; // 0-100
  final List<String> issues;
  final List<String> recommendations;

  ShuttleRunMetrics({
    required this.directionChanges,
    required this.turnTimes,
    required this.averageTurnTime,
    required this.turnEfficiency,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.speedConsistency,
    required this.speedProfile,
    required this.bodyLean,
    required this.armSwing,
    required this.deceleration,
    required this.overallQuality,
    required this.qualityScore,
    required this.issues,
    required this.recommendations,
  });

  @override
  String toString() {
    return '''
Shuttle Run Metrics:
├─ Overall Quality: $overallQuality (${qualityScore.toStringAsFixed(1)}/100)
├─ Direction Changes: $directionChanges
├─ Avg Turn Time: ${averageTurnTime.toStringAsFixed(2)}s
├─ Avg Speed: ${averageSpeed.toStringAsFixed(2)} m/s
├─ Max Speed: ${maxSpeed.toStringAsFixed(2)} m/s
├─ Turn Efficiency: ${(turnEfficiency * 100).toStringAsFixed(0)}%
├─ Speed Consistency: ${(speedConsistency * 100).toStringAsFixed(0)}%
└─ Issues Found: ${issues.length}
''';
  }
}

class ShuttleRunAnalyzer {
  // Historical data for analysis
  final List<List<Keypoint>> _poseHistory = [];
  final List<int> _timestampHistory = [];
  static const int historyLimit =
      90; // Keep last 90 frames (3 seconds at 30fps)

  // Direction tracking
  Direction _currentDirection = Direction.stationary;
  final List<Direction> _directionHistory = [];
  final List<int> _directionChangeTimestamps = [];

  // Position tracking
  final List<double> _hipXPositions = [];
  final List<double> _speeds = [];

  // Metrics tracking
  final List<double> _bodyLeans = [];
  final List<double> _armSwings = [];

  ShuttleRunAnalyzer();

  /// Analyze a single frame of shuttle run
  ShuttleRunMetrics analyzeFrame(List<Keypoint> keypoints, int timestamp) {
    // Update history
    _poseHistory.add(keypoints);
    _timestampHistory.add(timestamp);

    // Keep only recent history
    while (_poseHistory.length > historyLimit) {
      _poseHistory.removeAt(0);
      _timestampHistory.removeAt(0);
    }

    // Need at least 15 frames for analysis
    if (_poseHistory.length < 15) {
      return _createDefaultMetrics();
    }

    // Track position and detect direction changes
    _trackPositionAndDirection(keypoints, timestamp);

    // Analyze different aspects
    final turnMetrics = _analyzeTurns();
    final speedMetrics = _analyzeSpeed();
    final formMetrics = _analyzeForm(keypoints);

    // Compile issues and recommendations
    final issues = <String>[];
    final recommendations = <String>[];

    _evaluateForm(
        turnMetrics, speedMetrics, formMetrics, issues, recommendations);

    // Calculate overall quality score
    final qualityScore =
        _calculateQualityScore(turnMetrics, speedMetrics, formMetrics);
    final quality = _determineFormQuality(qualityScore);

    return ShuttleRunMetrics(
      directionChanges: _directionChangeTimestamps.length,
      turnTimes: _calculateTurnTimes(),
      averageTurnTime: _calculateAverageTurnTime(),
      turnEfficiency: turnMetrics['efficiency'] ?? 0.0,
      averageSpeed: speedMetrics['average'] ?? 0.0,
      maxSpeed: speedMetrics['max'] ?? 0.0,
      speedConsistency: speedMetrics['consistency'] ?? 0.0,
      speedProfile: List.from(_speeds),
      bodyLean: formMetrics['lean'] ?? 0.0,
      armSwing: formMetrics['armSwing'] ?? 0.0,
      deceleration: formMetrics['deceleration'] ?? 0.0,
      overallQuality: quality,
      qualityScore: qualityScore,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// Track hip position and detect direction changes
  void _trackPositionAndDirection(List<Keypoint> keypoints, int timestamp) {
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);

    if (leftHip == null || rightHip == null) return;

    // Calculate hip midpoint X position
    final hipX = (leftHip.x + rightHip.x) / 2;
    _hipXPositions.add(hipX);

    // Keep reasonable history
    if (_hipXPositions.length > historyLimit) {
      _hipXPositions.removeAt(0);
    }

    // Detect direction changes (need at least 10 positions)
    if (_hipXPositions.length >= 10) {
      // Calculate movement over last few frames
      final recentPositions =
          _hipXPositions.sublist(_hipXPositions.length - 10);
      final movementDelta = recentPositions.last - recentPositions.first;

      Direction newDirection;
      if (movementDelta > 0.02) {
        newDirection = Direction.right;
      } else if (movementDelta < -0.02) {
        newDirection = Direction.left;
      } else {
        newDirection = Direction.stationary;
      }

      // Detect direction change
      if (newDirection != _currentDirection &&
          newDirection != Direction.stationary &&
          _currentDirection != Direction.stationary) {
        _directionChangeTimestamps.add(timestamp);
      }

      _currentDirection = newDirection;
      _directionHistory.add(newDirection);
    }
  }

  /// Analyze turn metrics
  Map<String, double> _analyzeTurns() {
    if (_directionChangeTimestamps.length < 2) {
      return {'efficiency': 0.0, 'quality': 0.0};
    }

    // Calculate turn efficiency based on speed maintenance
    double totalEfficiency = 0.0;
    int validTurns = 0;

    for (int i = 0; i < _directionChangeTimestamps.length; i++) {
      // Look at speed before and after turn
      if (i > 0 && i < _speeds.length - 5) {
        final speedBeforeTurn = _speeds.length > i + 5 ? _speeds[i - 5] : 0.0;
        final speedAfterTurn = _speeds.length > i + 5 ? _speeds[i + 5] : 0.0;

        if (speedBeforeTurn > 0) {
          final speedRetention = speedAfterTurn / speedBeforeTurn;
          totalEfficiency += speedRetention.clamp(0.0, 1.0);
          validTurns++;
        }
      }
    }

    final avgEfficiency = validTurns > 0 ? totalEfficiency / validTurns : 0.0;

    return {
      'efficiency': avgEfficiency,
      'quality': avgEfficiency, // For now, quality equals efficiency
    };
  }

  /// Analyze speed metrics
  Map<String, double> _analyzeSpeed() {
    if (_hipXPositions.length < 5) {
      return {'average': 0.0, 'max': 0.0, 'consistency': 0.0};
    }

    // Calculate speeds from position changes
    _speeds.clear();
    for (int i = 4; i < _hipXPositions.length; i++) {
      final deltaPos = (_hipXPositions[i] - _hipXPositions[i - 4]).abs();
      final deltaTime =
          (_timestampHistory[i] - _timestampHistory[i - 4]) / 1000.0;

      if (deltaTime > 0) {
        // Convert normalized position change to approximate m/s
        // Assuming normalized coordinates represent ~2m width
        final speed = (deltaPos * 2.0) / deltaTime;
        _speeds.add(speed);
      }
    }

    if (_speeds.isEmpty) {
      return {'average': 0.0, 'max': 0.0, 'consistency': 0.0};
    }

    final avgSpeed = _speeds.reduce((a, b) => a + b) / _speeds.length;
    final maxSpeed = _speeds.reduce((a, b) => a > b ? a : b);

    // Calculate consistency (inverse of coefficient of variation)
    double variance = 0.0;
    for (final speed in _speeds) {
      variance += pow(speed - avgSpeed, 2);
    }
    variance /= _speeds.length;
    final stdDev = sqrt(variance);
    final cv = avgSpeed > 0 ? stdDev / avgSpeed : 1.0;
    final consistency = (1.0 - cv.clamp(0.0, 1.0)).clamp(0.0, 1.0);

    return {
      'average': avgSpeed,
      'max': maxSpeed,
      'consistency': consistency,
    };
  }

  /// Analyze form metrics
  Map<String, double> _analyzeForm(List<Keypoint> keypoints) {
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);
    final leftElbow = _findKeypoint(keypoints, KeypointNames.leftElbow);
    final rightElbow = _findKeypoint(keypoints, KeypointNames.rightElbow);

    // Body lean (good for acceleration and turning)
    double bodyLean = 0.0;
    if (leftShoulder != null &&
        rightShoulder != null &&
        leftHip != null &&
        rightHip != null) {
      final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final hipY = (leftHip.y + rightHip.y) / 2;
      final shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
      final hipX = (leftHip.x + rightHip.x) / 2;

      // Calculate lean angle
      final deltaX = (shoulderX - hipX).abs();
      final deltaY = (hipY - shoulderY).abs();
      if (deltaY > 0) {
        bodyLean = atan(deltaX / deltaY) * 180 / pi;
      }
    }
    _bodyLeans.add(bodyLean);

    // Arm swing quality
    double armSwing = 0.0;
    if (leftElbow != null &&
        rightElbow != null &&
        leftShoulder != null &&
        rightShoulder != null &&
        leftWrist != null &&
        rightWrist != null) {
      // Check arm movement range
      final leftArmAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      final rightArmAngle =
          _calculateAngle(rightShoulder, rightElbow, rightWrist);

      // Good arm swing is between 70-120 degrees
      final leftArmQuality =
          (leftArmAngle >= 70 && leftArmAngle <= 120) ? 1.0 : 0.5;
      final rightArmQuality =
          (rightArmAngle >= 70 && rightArmAngle <= 120) ? 1.0 : 0.5;
      armSwing = (leftArmQuality + rightArmQuality) / 2;
    }
    _armSwings.add(armSwing);

    // Deceleration quality (based on body lean and speed changes)
    double deceleration = 0.7; // Default moderate score
    if (_speeds.length > 5 && _directionChangeTimestamps.isNotEmpty) {
      // Check if speed decreases appropriately before direction changes
      // This is a simplified metric
      deceleration = 0.75;
    }

    return {
      'lean': bodyLean,
      'armSwing': armSwing,
      'deceleration': deceleration,
    };
  }

  /// Calculate turn times
  List<double> _calculateTurnTimes() {
    if (_directionChangeTimestamps.length < 2) return [];

    final turnTimes = <double>[];
    for (int i = 1; i < _directionChangeTimestamps.length; i++) {
      final timeDiff =
          (_directionChangeTimestamps[i] - _directionChangeTimestamps[i - 1]) /
              1000.0;
      turnTimes.add(timeDiff);
    }
    return turnTimes;
  }

  /// Calculate average turn time
  double _calculateAverageTurnTime() {
    final turnTimes = _calculateTurnTimes();
    if (turnTimes.isEmpty) return 0.0;
    return turnTimes.reduce((a, b) => a + b) / turnTimes.length;
  }

  /// Evaluate form and generate issues/recommendations
  void _evaluateForm(
    Map<String, double> turnMetrics,
    Map<String, double> speedMetrics,
    Map<String, double> formMetrics,
    List<String> issues,
    List<String> recommendations,
  ) {
    // Check turn efficiency
    final turnEfficiency = turnMetrics['efficiency'] ?? 0.0;
    if (turnEfficiency < 0.6) {
      issues.add('Slow turn execution - losing too much speed');
      recommendations
          .add('Practice quick direction changes while maintaining momentum');
    }

    // Check speed consistency
    final consistency = speedMetrics['consistency'] ?? 0.0;
    if (consistency < 0.7) {
      issues.add('Inconsistent speed between runs');
      recommendations.add('Focus on maintaining steady pace throughout');
    }

    // Check body lean
    final bodyLean = formMetrics['lean'] ?? 0.0;
    if (bodyLean < 5.0) {
      issues.add('Insufficient forward lean');
      recommendations.add('Lean forward 10-15° for better acceleration');
    } else if (bodyLean > 25.0) {
      issues.add('Excessive forward lean');
      recommendations.add('Reduce lean to maintain balance');
    }

    // Check arm swing
    final armSwing = formMetrics['armSwing'] ?? 0.0;
    if (armSwing < 0.6) {
      issues.add('Poor arm swing technique');
      recommendations.add('Drive arms forward and back with bent elbows');
    }

    // General recommendations
    if (issues.isEmpty) {
      recommendations.add('Excellent form! Keep up the good work');
    }
  }

  /// Calculate overall quality score
  double _calculateQualityScore(
    Map<String, double> turnMetrics,
    Map<String, double> speedMetrics,
    Map<String, double> formMetrics,
  ) {
    double score = 0.0;

    // Turn efficiency (30 points)
    score += (turnMetrics['efficiency'] ?? 0.0) * 30;

    // Speed consistency (25 points)
    score += (speedMetrics['consistency'] ?? 0.0) * 25;

    // Speed performance (20 points)
    final avgSpeed = speedMetrics['average'] ?? 0.0;
    final speedScore = (avgSpeed / 4.0).clamp(0.0, 1.0); // 4 m/s as reference
    score += speedScore * 20;

    // Form quality (25 points)
    final armSwing = formMetrics['armSwing'] ?? 0.0;
    final bodyLean = formMetrics['lean'] ?? 0.0;
    final leanScore = (bodyLean >= 10 && bodyLean <= 20) ? 1.0 : 0.6;
    score += (armSwing * 0.5 + leanScore * 0.5) * 25;

    return score.clamp(0.0, 100.0);
  }

  /// Determine form quality from score
  ShuttleFormQuality _determineFormQuality(double score) {
    if (score >= 85) return ShuttleFormQuality.excellent;
    if (score >= 70) return ShuttleFormQuality.good;
    if (score >= 55) return ShuttleFormQuality.fair;
    return ShuttleFormQuality.poor;
  }

  /// Create default metrics for initial frames
  ShuttleRunMetrics _createDefaultMetrics() {
    return ShuttleRunMetrics(
      directionChanges: 0,
      turnTimes: [],
      averageTurnTime: 0.0,
      turnEfficiency: 0.0,
      averageSpeed: 0.0,
      maxSpeed: 0.0,
      speedConsistency: 0.0,
      speedProfile: [],
      bodyLean: 0.0,
      armSwing: 0.0,
      deceleration: 0.0,
      overallQuality: ShuttleFormQuality.fair,
      qualityScore: 50.0,
      issues: [],
      recommendations: ['Analyzing movement...'],
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

  /// Helper: Calculate angle between three points
  double _calculateAngle(Keypoint a, Keypoint b, Keypoint c) {
    final ba = Point(a.x - b.x, a.y - b.y);
    final bc = Point(c.x - b.x, c.y - b.y);

    final dotProduct = ba.x * bc.x + ba.y * bc.y;
    final magnitudeBA = sqrt(ba.x * ba.x + ba.y * ba.y);
    final magnitudeBC = sqrt(bc.x * bc.x + bc.y * bc.y);

    if (magnitudeBA == 0 || magnitudeBC == 0) return 0;

    final cosAngle = dotProduct / (magnitudeBA * magnitudeBC);
    final angleRad = acos(cosAngle.clamp(-1.0, 1.0));
    return angleRad * 180 / pi;
  }

  /// Reset the analyzer state
  void reset() {
    _poseHistory.clear();
    _timestampHistory.clear();
    _directionHistory.clear();
    _directionChangeTimestamps.clear();
    _hipXPositions.clear();
    _speeds.clear();
    _bodyLeans.clear();
    _armSwings.clear();
    _currentDirection = Direction.stationary;
  }
}
