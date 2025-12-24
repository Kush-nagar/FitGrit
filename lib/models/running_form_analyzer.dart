/// Running form analyzer that evaluates running technique based on pose keypoints.
/// Analyzes stride, posture, arm swing, and overall form quality.
import 'dart:math';
import 'keypoint.dart';

/// Types of running activities
enum RunType {
  sprint, // High-intensity short distance
  middleDistance, // 400m - 1500m
  longDistance, // 5k, 10k, marathon
  recovery, // Easy pace recovery runs
}

/// Running form quality rating
enum FormQuality {
  excellent,
  good,
  fair,
  poor,
}

/// Metrics for running form analysis
class RunningFormMetrics {
  // Stride metrics
  final double strideLength; // meters
  final double strideFrequency; // steps per minute (cadence)
  final double footStrikeAngle; // degrees (heel vs forefoot)

  // Posture metrics
  final double forwardLean; // degrees from vertical
  final double hipAlignment; // 0-1, 1 is perfect
  final double shoulderRelaxation; // 0-1, 1 is relaxed

  // Arm metrics
  final double armSwingAmplitude; // 0-1, optimal range
  final double elbowAngle; // degrees, should be ~90

  // Overall assessment
  final FormQuality overallQuality;
  final double qualityScore; // 0-100
  final List<String> issues; // List of detected issues
  final List<String> recommendations; // Suggestions for improvement

  RunningFormMetrics({
    required this.strideLength,
    required this.strideFrequency,
    required this.footStrikeAngle,
    required this.forwardLean,
    required this.hipAlignment,
    required this.shoulderRelaxation,
    required this.armSwingAmplitude,
    required this.elbowAngle,
    required this.overallQuality,
    required this.qualityScore,
    required this.issues,
    required this.recommendations,
  });

  @override
  String toString() {
    return '''
Running Form Analysis:
├─ Overall Quality: $overallQuality (${qualityScore.toStringAsFixed(1)}/100)
├─ Cadence: ${strideFrequency.toStringAsFixed(0)} spm
├─ Stride Length: ${strideLength.toStringAsFixed(2)}m
├─ Forward Lean: ${forwardLean.toStringAsFixed(1)}°
├─ Foot Strike: ${footStrikeAngle.toStringAsFixed(1)}°
└─ Issues Found: ${issues.length}
''';
  }
}

class RunningFormAnalyzer {
  final RunType runType;

  // Historical data for analysis
  final List<List<Keypoint>> _poseHistory = [];
  final List<int> _timestampHistory = [];
  static const int historyLimit = 60; // Keep last 60 frames

  // Metrics tracking
  final List<double> _strideLengths = [];
  final List<double> _cadences = [];
  final List<double> _leanAngles = [];

  RunningFormAnalyzer({this.runType = RunType.longDistance});

  /// Analyze a single frame of running form
  RunningFormMetrics analyzeFrame(List<Keypoint> keypoints, int timestamp) {
    // Update history
    _poseHistory.add(keypoints);
    _timestampHistory.add(timestamp);

    // Keep only recent history
    while (_poseHistory.length > historyLimit) {
      _poseHistory.removeAt(0);
      _timestampHistory.removeAt(0);
    }

    // Need at least 10 frames for analysis
    if (_poseHistory.length < 10) {
      return _createDefaultMetrics();
    }

    // Analyze different aspects of running form
    final strideMetrics = _analyzeStridePattern();
    final postureMetrics = _analyzePosture(keypoints);
    final armMetrics = _analyzeArmSwing(keypoints);

    // Compile issues and recommendations
    final issues = <String>[];
    final recommendations = <String>[];

    _evaluateForm(
        strideMetrics, postureMetrics, armMetrics, issues, recommendations);

    // Calculate overall quality score
    final qualityScore =
        _calculateQualityScore(strideMetrics, postureMetrics, armMetrics);
    final quality = _determineFormQuality(qualityScore);

    return RunningFormMetrics(
      strideLength: strideMetrics['length'] ?? 0.0,
      strideFrequency: strideMetrics['cadence'] ?? 0.0,
      footStrikeAngle: strideMetrics['footStrike'] ?? 0.0,
      forwardLean: postureMetrics['lean'] ?? 0.0,
      hipAlignment: postureMetrics['hipAlignment'] ?? 0.0,
      shoulderRelaxation: postureMetrics['shoulderRelaxation'] ?? 0.0,
      armSwingAmplitude: armMetrics['amplitude'] ?? 0.0,
      elbowAngle: armMetrics['elbowAngle'] ?? 90.0,
      overallQuality: quality,
      qualityScore: qualityScore,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// Analyze stride pattern over multiple frames
  Map<String, double> _analyzeStridePattern() {
    if (_poseHistory.length < 20) {
      return {'length': 0.0, 'cadence': 0.0, 'footStrike': 0.0};
    }

    // Detect stride events (foot strikes) by analyzing ankle vertical position
    final leftAnkleY = <double>[];
    final rightAnkleY = <double>[];

    for (var pose in _poseHistory) {
      final leftAnkle = _findKeypoint(pose, KeypointNames.leftAnkle);
      final rightAnkle = _findKeypoint(pose, KeypointNames.rightAnkle);

      if (leftAnkle != null && rightAnkle != null) {
        leftAnkleY.add(leftAnkle.y);
        rightAnkleY.add(rightAnkle.y);
      }
    }

    if (leftAnkleY.isEmpty) {
      return {'length': 0.0, 'cadence': 0.0, 'footStrike': 0.0};
    }

    // Detect stride frequency (cadence) by counting peaks
    final strides = _detectStrides(leftAnkleY, rightAnkleY);
    final timeSpan =
        (_timestampHistory.last - _timestampHistory.first) / 1000.0; // seconds
    final cadence =
        strides > 0 && timeSpan > 0 ? (strides / timeSpan) * 60 : 0.0;

    // Estimate stride length based on hip-to-ankle distance and movement
    final strideLength = _estimateStrideLength();

    // Analyze foot strike angle
    final footStrike = _analyzefootStrikeAngle();

    _cadences.add(cadence);
    _strideLengths.add(strideLength);

    return {
      'length': strideLength,
      'cadence': cadence,
      'footStrike': footStrike,
    };
  }

  /// Detect number of strides from ankle position data
  int _detectStrides(List<double> leftY, List<double> rightY) {
    int strides = 0;

    // Simple peak detection - when foot is at lowest point (highest y value)
    for (int i = 1; i < leftY.length - 1; i++) {
      if (leftY[i] > leftY[i - 1] && leftY[i] > leftY[i + 1]) {
        if (leftY[i] - leftY[i - 1] > 0.02) {
          // Threshold for noise
          strides++;
        }
      }
      if (rightY[i] > rightY[i - 1] && rightY[i] > rightY[i + 1]) {
        if (rightY[i] - rightY[i - 1] > 0.02) {
          strides++;
        }
      }
    }

    return strides;
  }

  /// Estimate stride length from hip-to-ankle distance
  double _estimateStrideLength() {
    if (_poseHistory.isEmpty) return 0.0;

    final latestPose = _poseHistory.last;
    final hip = _findKeypoint(latestPose, KeypointNames.leftHip) ??
        _findKeypoint(latestPose, KeypointNames.rightHip);
    final ankle = _findKeypoint(latestPose, KeypointNames.leftAnkle) ??
        _findKeypoint(latestPose, KeypointNames.rightAnkle);

    if (hip == null || ankle == null) return 0.0;

    // Approximate stride length as 2x the hip-to-ankle distance
    // This is a simplified model; real stride length varies by height
    final legLength = _calculateDistance(hip, ankle);
    return legLength * 2.0 * 1.5; // Rough estimate in meters
  }

  /// Analyze foot strike angle (forefoot vs heel strike)
  double _analyzefootStrikeAngle() {
    if (_poseHistory.isEmpty) return 0.0;

    final latestPose = _poseHistory.last;
    final ankle = _findKeypoint(latestPose, KeypointNames.leftAnkle);
    final knee = _findKeypoint(latestPose, KeypointNames.leftKnee);

    if (ankle == null || knee == null) return 0.0;

    // Calculate angle of leg at foot strike
    final angle = _calculateAngle(
        knee,
        ankle,
        Keypoint(
          name: 'ground',
          x: ankle.x,
          y: ankle.y + 0.1,
          confidence: 1.0,
        ));

    return angle;
  }

  /// Analyze posture (forward lean, hip alignment)
  Map<String, double> _analyzePosture(List<Keypoint> keypoints) {
    final nose = _findKeypoint(keypoints, KeypointNames.nose);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);

    if (nose == null || leftHip == null || rightHip == null) {
      return {'lean': 0.0, 'hipAlignment': 0.0, 'shoulderRelaxation': 0.0};
    }

    // Calculate forward lean (angle from vertical)
    final hipMidpoint = Keypoint(
      name: 'hip_center',
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2,
      confidence: 1.0,
    );

    final lean = _calculateForwardLean(nose, hipMidpoint);
    _leanAngles.add(lean);

    // Hip alignment (should be level)
    final hipAlignment = 1.0 - (leftHip.y - rightHip.y).abs();

    // Shoulder relaxation (shoulders shouldn't be too high)
    double shoulderRelaxation = 1.0;
    if (leftShoulder != null && rightShoulder != null) {
      final shoulderHeight = ((leftShoulder.y + rightShoulder.y) / 2);
      final noseHeight = nose.y;
      shoulderRelaxation =
          1.0 - ((noseHeight - shoulderHeight).abs().clamp(0.0, 1.0));
    }

    return {
      'lean': lean,
      'hipAlignment': hipAlignment.clamp(0.0, 1.0),
      'shoulderRelaxation': shoulderRelaxation.clamp(0.0, 1.0),
    };
  }

  /// Calculate forward lean angle
  double _calculateForwardLean(Keypoint head, Keypoint hip) {
    final dx = head.x - hip.x;
    final dy = head.y - hip.y;
    final angle = atan2(dx.abs(), dy.abs()) * 180 / pi;
    return angle;
  }

  /// Analyze arm swing
  Map<String, double> _analyzeArmSwing(List<Keypoint> keypoints) {
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final leftElbow = _findKeypoint(keypoints, KeypointNames.leftElbow);
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);

    if (leftShoulder == null || leftElbow == null || leftWrist == null) {
      return {'amplitude': 0.5, 'elbowAngle': 90.0};
    }

    // Calculate elbow angle
    final elbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);

    // Arm swing amplitude (normalized distance from shoulder to wrist)
    final amplitude = _calculateDistance(leftShoulder, leftWrist);

    return {
      'amplitude': amplitude.clamp(0.0, 1.0),
      'elbowAngle': elbowAngle,
    };
  }

  /// Evaluate form and generate issues/recommendations
  void _evaluateForm(
    Map<String, double> stride,
    Map<String, double> posture,
    Map<String, double> arms,
    List<String> issues,
    List<String> recommendations,
  ) {
    final cadence = stride['cadence'] ?? 0.0;
    final lean = posture['lean'] ?? 0.0;
    final elbowAngle = arms['elbowAngle'] ?? 90.0;

    // Optimal cadence based on run type
    final optimalCadence = _getOptimalCadence(runType);

    if (cadence > 0 &&
        (cadence < optimalCadence - 20 || cadence > optimalCadence + 20)) {
      issues.add('Cadence out of optimal range');
      recommendations
          .add('Aim for ${optimalCadence.toStringAsFixed(0)} steps per minute');
    }

    if (lean > 15) {
      issues.add('Excessive forward lean');
      recommendations
          .add('Keep torso more upright, lean from ankles not waist');
    } else if (lean < 2) {
      issues.add('Insufficient forward lean');
      recommendations.add('Lean slightly forward (3-5°) from ankles');
    }

    if (elbowAngle < 75 || elbowAngle > 110) {
      issues.add('Elbow angle not optimal');
      recommendations.add('Keep elbows bent at approximately 90 degrees');
    }

    final hipAlignment = posture['hipAlignment'] ?? 0.0;
    if (hipAlignment < 0.85) {
      issues.add('Hip misalignment detected');
      recommendations.add('Focus on keeping hips level and stable');
    }

    final footStrike = stride['footStrike'] ?? 0.0;
    if (footStrike > 20) {
      issues.add('Heavy heel striking detected');
      recommendations.add('Try landing mid-foot for better efficiency');
    }
  }

  /// Calculate overall quality score (0-100)
  double _calculateQualityScore(
    Map<String, double> stride,
    Map<String, double> posture,
    Map<String, double> arms,
  ) {
    double score = 100.0;

    // Cadence scoring (30 points)
    final cadence = stride['cadence'] ?? 0.0;
    final optimalCadence = _getOptimalCadence(runType);
    if (cadence > 0) {
      final cadenceDiff = (cadence - optimalCadence).abs();
      score -= (cadenceDiff / optimalCadence) * 30;
    }

    // Posture scoring (40 points)
    final lean = posture['lean'] ?? 0.0;
    final optimalLean = _getOptimalLean(runType);
    final leanDiff = (lean - optimalLean).abs();
    score -= (leanDiff / 10) * 20;

    final hipAlignment = posture['hipAlignment'] ?? 0.0;
    score -= (1.0 - hipAlignment) * 20;

    // Arm swing scoring (30 points)
    final elbowAngle = arms['elbowAngle'] ?? 90.0;
    final elbowDiff = (elbowAngle - 90).abs();
    score -= (elbowDiff / 30) * 15;

    final amplitude = arms['amplitude'] ?? 0.5;
    score -= (0.5 - amplitude).abs() * 15;

    return score.clamp(0.0, 100.0);
  }

  /// Determine form quality from score
  FormQuality _determineFormQuality(double score) {
    if (score >= 85) return FormQuality.excellent;
    if (score >= 70) return FormQuality.good;
    if (score >= 55) return FormQuality.fair;
    return FormQuality.poor;
  }

  /// Get optimal cadence for run type
  double _getOptimalCadence(RunType type) {
    switch (type) {
      case RunType.sprint:
        return 200.0; // Higher cadence for sprints
      case RunType.middleDistance:
        return 180.0;
      case RunType.longDistance:
        return 170.0; // Slightly lower for distance
      case RunType.recovery:
        return 160.0;
    }
  }

  /// Get optimal forward lean for run type
  double _getOptimalLean(RunType type) {
    switch (type) {
      case RunType.sprint:
        return 8.0; // More aggressive lean
      case RunType.middleDistance:
        return 5.0;
      case RunType.longDistance:
        return 3.0; // Minimal lean
      case RunType.recovery:
        return 2.0;
    }
  }

  /// Create default metrics when not enough data
  RunningFormMetrics _createDefaultMetrics() {
    return RunningFormMetrics(
      strideLength: 0.0,
      strideFrequency: 0.0,
      footStrikeAngle: 0.0,
      forwardLean: 0.0,
      hipAlignment: 1.0,
      shoulderRelaxation: 1.0,
      armSwingAmplitude: 0.5,
      elbowAngle: 90.0,
      overallQuality: FormQuality.fair,
      qualityScore: 50.0,
      issues: ['Analyzing...'],
      recommendations: ['Keep running to collect data'],
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

  /// Calculate angle between three points
  double _calculateAngle(Keypoint p1, Keypoint p2, Keypoint p3) {
    final v1x = p1.x - p2.x;
    final v1y = p1.y - p2.y;
    final v2x = p3.x - p2.x;
    final v2y = p3.y - p2.y;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = sqrt(v1x * v1x + v1y * v1y);
    final mag2 = sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 0;

    final cosAngle = dot / (mag1 * mag2);
    return acos(cosAngle.clamp(-1.0, 1.0)) * 180 / pi;
  }

  /// Calculate distance between two keypoints
  double _calculateDistance(Keypoint p1, Keypoint p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Reset analyzer
  void reset() {
    _poseHistory.clear();
    _timestampHistory.clear();
    _strideLengths.clear();
    _cadences.clear();
    _leanAngles.clear();
  }

  /// Get average metrics over time
  Map<String, double> getAverageMetrics() {
    return {
      'avgCadence': _cadences.isEmpty
          ? 0.0
          : _cadences.reduce((a, b) => a + b) / _cadences.length,
      'avgStrideLength': _strideLengths.isEmpty
          ? 0.0
          : _strideLengths.reduce((a, b) => a + b) / _strideLengths.length,
      'avgLean': _leanAngles.isEmpty
          ? 0.0
          : _leanAngles.reduce((a, b) => a + b) / _leanAngles.length,
    };
  }
}
