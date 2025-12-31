/// Flexibility form analyzer that evaluates sit-and-reach and v-sit-and-reach technique.
/// Analyzes posture, leg position, reach form, and provides feedback.
import 'dart:math';
import 'keypoint.dart';
import '../services/flexibility_metrics_calculator.dart';

/// Form quality rating
enum FlexibilityFormQuality {
  excellent,
  good,
  fair,
  poor,
}

/// Metrics for flexibility form analysis
class FlexibilityFormMetrics {
  final FlexibilityTestType testType;

  // Posture metrics
  final double backAlignment; // 0-1, 1 is straight/proper curve
  final double neckPosition; // 0-1, 1 is neutral
  final double shoulderRelaxation; // 0-1, 1 is relaxed

  // Leg metrics
  final double kneeExtension; // 0-1, 1 is fully extended
  final double legSymmetry; // 0-1, 1 is perfectly symmetric (for V sit)
  final double legSpreadAngle; // degrees (for V sit-and-reach)

  // Reach metrics
  final double reachSmoothness; // 0-1, 1 is smooth controlled movement
  final double holdStability; // 0-1, 1 is stable hold
  final double properTechnique; // 0-1, 1 is using correct form

  // Overall assessment
  final FlexibilityFormQuality overallQuality;
  final double qualityScore; // 0-100
  final List<String> issues; // List of detected issues
  final List<String> recommendations; // Suggestions for improvement

  FlexibilityFormMetrics({
    required this.testType,
    required this.backAlignment,
    required this.neckPosition,
    required this.shoulderRelaxation,
    required this.kneeExtension,
    required this.legSymmetry,
    required this.legSpreadAngle,
    required this.reachSmoothness,
    required this.holdStability,
    required this.properTechnique,
    required this.overallQuality,
    required this.qualityScore,
    required this.issues,
    required this.recommendations,
  });

  @override
  String toString() {
    final testName = testType == FlexibilityTestType.sitAndReach
        ? 'Sit and Reach'
        : 'V Sit and Reach';
    return '''
Flexibility Form Analysis ($testName):
├─ Overall Quality: $overallQuality (${qualityScore.toStringAsFixed(1)}/100)
├─ Back Alignment: ${(backAlignment * 100).toStringAsFixed(0)}%
├─ Knee Extension: ${(kneeExtension * 100).toStringAsFixed(0)}%
├─ Reach Smoothness: ${(reachSmoothness * 100).toStringAsFixed(0)}%
└─ Issues Found: ${issues.length}
''';
  }
}

class FlexibilityFormAnalyzer {
  final FlexibilityTestType testType;

  // Historical data for analysis
  final List<List<Keypoint>> _poseHistory = [];
  final List<int> _timestampHistory = [];
  static const int historyLimit =
      90; // Keep last 90 frames (3 seconds at 30fps)

  // Metrics tracking
  final List<double> _reachPositions = [];
  final List<double> _kneeAngles = [];

  FlexibilityFormAnalyzer({this.testType = FlexibilityTestType.sitAndReach});

  /// Analyze a single frame of flexibility form
  FlexibilityFormMetrics analyzeFrame(List<Keypoint> keypoints, int timestamp) {
    // Update history
    _poseHistory.add(keypoints);
    _timestampHistory.add(timestamp);

    // Keep only recent history
    while (_poseHistory.length > historyLimit) {
      _poseHistory.removeAt(0);
      _timestampHistory.removeAt(0);
    }

    // Need at least 10 frames for meaningful analysis
    if (_poseHistory.length < 10) {
      return _createDefaultMetrics();
    }

    // Analyze different aspects of form
    final postureMetrics = _analyzePosture(keypoints);
    final legMetrics = _analyzeLegPosition(keypoints);
    final reachMetrics = _analyzeReachMovement();

    // Compile issues and recommendations
    final issues = <String>[];
    final recommendations = <String>[];

    _evaluateForm(
        postureMetrics, legMetrics, reachMetrics, issues, recommendations);

    // Calculate overall quality score
    final qualityScore =
        _calculateQualityScore(postureMetrics, legMetrics, reachMetrics);
    final quality = _determineFormQuality(qualityScore);

    return FlexibilityFormMetrics(
      testType: testType,
      backAlignment: postureMetrics['backAlignment'] ?? 0.0,
      neckPosition: postureMetrics['neckPosition'] ?? 0.0,
      shoulderRelaxation: postureMetrics['shoulderRelaxation'] ?? 0.0,
      kneeExtension: legMetrics['kneeExtension'] ?? 0.0,
      legSymmetry: legMetrics['legSymmetry'] ?? 0.0,
      legSpreadAngle: legMetrics['legSpreadAngle'] ?? 0.0,
      reachSmoothness: reachMetrics['smoothness'] ?? 0.0,
      holdStability: reachMetrics['stability'] ?? 0.0,
      properTechnique: reachMetrics['technique'] ?? 0.0,
      overallQuality: quality,
      qualityScore: qualityScore,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// Analyze posture metrics
  Map<String, double> _analyzePosture(List<Keypoint> keypoints) {
    final nose = _findKeypoint(keypoints, KeypointNames.nose);
    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);

    double backAlignment = 0.0;
    double neckPosition = 0.0;
    double shoulderRelaxation = 0.0;

    // Check back alignment (should be relatively straight or smooth curve)
    if (leftShoulder != null &&
        rightShoulder != null &&
        leftHip != null &&
        rightHip != null) {
      final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
      final hipMidY = (leftHip.y + rightHip.y) / 2;

      // Back should be angled forward during reach
      final backAngle = atan2(
            shoulderMidY - hipMidY,
            (leftShoulder.x + rightShoulder.x) / 2 -
                (leftHip.x + rightHip.x) / 2,
          ).abs() *
          180 /
          pi;

      // Good form: 30-60 degree forward lean
      if (backAngle >= 30 && backAngle <= 60) {
        backAlignment = 1.0;
      } else if (backAngle >= 20 && backAngle <= 70) {
        backAlignment = 0.7;
      } else {
        backAlignment = 0.4;
      }
    }

    // Check neck position (should be neutral, not hyperextended)
    if (nose != null && leftShoulder != null && rightShoulder != null) {
      final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
      final neckAngle = (nose.y - shoulderMidY).abs();

      // Neck should be relatively neutral
      if (neckAngle < 0.1) {
        neckPosition = 1.0;
      } else if (neckAngle < 0.15) {
        neckPosition = 0.7;
      } else {
        neckPosition = 0.4;
      }
    }

    // Check shoulder relaxation (shoulders shouldn't be hunched)
    if (leftShoulder != null && rightShoulder != null) {
      final shoulderLevelness = (leftShoulder.y - rightShoulder.y).abs();

      // Shoulders should be level and relaxed
      if (shoulderLevelness < 0.05) {
        shoulderRelaxation = 1.0;
      } else if (shoulderLevelness < 0.1) {
        shoulderRelaxation = 0.7;
      } else {
        shoulderRelaxation = 0.4;
      }
    }

    return {
      'backAlignment': backAlignment,
      'neckPosition': neckPosition,
      'shoulderRelaxation': shoulderRelaxation,
    };
  }

  /// Analyze leg position metrics
  Map<String, double> _analyzeLegPosition(List<Keypoint> keypoints) {
    double kneeExtension = 0.0;
    double legSymmetry = 0.0;
    double legSpreadAngle = 0.0;

    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final leftKnee = _findKeypoint(keypoints, KeypointNames.leftKnee);
    final leftAnkle = _findKeypoint(keypoints, KeypointNames.leftAnkle);
    final rightKnee = _findKeypoint(keypoints, KeypointNames.rightKnee);

    // Check knee extension (legs should be straight)
    if (leftHip != null && leftKnee != null && leftAnkle != null) {
      final leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
      _kneeAngles.add(leftKneeAngle);

      // Closer to 180° is better
      if (leftKneeAngle >= 170) {
        kneeExtension = 1.0;
      } else if (leftKneeAngle >= 160) {
        kneeExtension = 0.8;
      } else if (leftKneeAngle >= 150) {
        kneeExtension = 0.6;
      } else {
        kneeExtension = 0.3;
      }
    }

    // For V sit-and-reach, check leg symmetry and spread
    if (testType == FlexibilityTestType.vSitAndReach) {
      if (leftHip != null && leftKnee != null && rightKnee != null) {
        // Check leg spread angle
        legSpreadAngle = _calculateAngle(leftKnee, leftHip, rightKnee);

        // Check symmetry (both legs should extend equally)
        final leftDist = sqrt(
            pow(leftKnee.x - leftHip.x, 2) + pow(leftKnee.y - leftHip.y, 2));
        final rightDist = sqrt(
            pow(rightKnee.x - leftHip.x, 2) + pow(rightKnee.y - leftHip.y, 2));

        final symmetryRatio =
            min(leftDist, rightDist) / max(leftDist, rightDist);
        legSymmetry = symmetryRatio;
      }
    } else {
      // For regular sit-and-reach, legs should be together
      if (leftKnee != null && rightKnee != null) {
        final legDistance = (leftKnee.x - rightKnee.x).abs();

        if (legDistance < 0.05) {
          legSymmetry = 1.0;
        } else if (legDistance < 0.1) {
          legSymmetry = 0.7;
        } else {
          legSymmetry = 0.4;
        }
      }
    }

    return {
      'kneeExtension': kneeExtension,
      'legSymmetry': legSymmetry,
      'legSpreadAngle': legSpreadAngle,
    };
  }

  /// Analyze reach movement quality
  Map<String, double> _analyzeReachMovement() {
    double smoothness = 0.0;
    double stability = 0.0;
    double technique = 0.0;

    if (_poseHistory.length < 20) {
      return {
        'smoothness': 0.5,
        'stability': 0.5,
        'technique': 0.5,
      };
    }

    // Track hand position over time to assess smoothness
    final handPositions = <double>[];
    for (var pose in _poseHistory.take(_poseHistory.length)) {
      final leftWrist = _findKeypoint(pose, KeypointNames.leftWrist);
      final rightWrist = _findKeypoint(pose, KeypointNames.rightWrist);

      if (leftWrist != null && rightWrist != null) {
        final avgX = (leftWrist.x + rightWrist.x) / 2;
        handPositions.add(avgX);
        _reachPositions.add(avgX);
      }
    }

    // Calculate smoothness (low variance = smooth movement)
    if (handPositions.length >= 10) {
      final velocities = <double>[];
      for (int i = 1; i < handPositions.length; i++) {
        velocities.add((handPositions[i] - handPositions[i - 1]).abs());
      }

      final avgVelocity =
          velocities.reduce((a, b) => a + b) / velocities.length;
      final variance = velocities
              .map((v) => pow(v - avgVelocity, 2))
              .reduce((a, b) => a + b) /
          velocities.length;

      // Lower variance indicates smoother movement
      if (variance < 0.001) {
        smoothness = 1.0;
      } else if (variance < 0.005) {
        smoothness = 0.8;
      } else if (variance < 0.01) {
        smoothness = 0.6;
      } else {
        smoothness = 0.4;
      }
    }

    // Calculate stability (recent frames should be relatively stable)
    if (_reachPositions.length >= 10) {
      final recentPositions =
          _reachPositions.skip(_reachPositions.length - 10).toList();
      final avgPosition =
          recentPositions.reduce((a, b) => a + b) / recentPositions.length;
      final deviations =
          recentPositions.map((p) => (p - avgPosition).abs()).toList();
      final avgDeviation =
          deviations.reduce((a, b) => a + b) / deviations.length;

      // Lower deviation indicates better stability
      if (avgDeviation < 0.01) {
        stability = 1.0;
      } else if (avgDeviation < 0.02) {
        stability = 0.8;
      } else if (avgDeviation < 0.03) {
        stability = 0.6;
      } else {
        stability = 0.4;
      }
    }

    // Overall technique score based on progressive reach
    if (_reachPositions.length >= 20) {
      final firstHalf =
          _reachPositions.take(_reachPositions.length ~/ 2).toList();
      final secondHalf =
          _reachPositions.skip(_reachPositions.length ~/ 2).toList();

      final avgFirst = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final avgSecond = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      // Should show progression (reach further in second half)
      final progression = (avgSecond - avgFirst).abs();

      if (progression > 0.05) {
        technique = 1.0; // Good progression
      } else if (progression > 0.02) {
        technique = 0.7;
      } else {
        technique = 0.5; // Minimal progression
      }
    }

    return {
      'smoothness': smoothness,
      'stability': stability,
      'technique': technique,
    };
  }

  /// Evaluate form and generate issues/recommendations
  void _evaluateForm(
    Map<String, double> postureMetrics,
    Map<String, double> legMetrics,
    Map<String, double> reachMetrics,
    List<String> issues,
    List<String> recommendations,
  ) {
    // Check posture issues
    if ((postureMetrics['backAlignment'] ?? 0.0) < 0.6) {
      issues.add('Back alignment needs improvement');
      recommendations
          .add('Keep your back straight with a natural curve, avoid rounding');
    }

    if ((postureMetrics['neckPosition'] ?? 0.0) < 0.6) {
      issues.add('Neck position not neutral');
      recommendations
          .add('Keep your neck in a neutral position, chin slightly tucked');
    }

    if ((postureMetrics['shoulderRelaxation'] ?? 0.0) < 0.6) {
      issues.add('Shoulders appear tense or uneven');
      recommendations.add('Relax your shoulders, keep them level and down');
    }

    // Check leg issues
    if ((legMetrics['kneeExtension'] ?? 0.0) < 0.7) {
      issues.add('Knees are bending');
      recommendations.add('Keep your legs fully extended with knees locked');
    }

    if (testType == FlexibilityTestType.vSitAndReach) {
      if ((legMetrics['legSymmetry'] ?? 0.0) < 0.7) {
        issues.add('Legs are not spread evenly');
        recommendations.add('Spread both legs equally to form a V shape');
      }
    } else {
      if ((legMetrics['legSymmetry'] ?? 0.0) < 0.7) {
        issues.add('Legs are not together');
        recommendations.add('Keep your legs close together with feet touching');
      }
    }

    // Check reach issues
    if ((reachMetrics['smoothness'] ?? 0.0) < 0.6) {
      issues.add('Reach movement is jerky');
      recommendations.add('Reach forward slowly and smoothly, avoid bouncing');
    }

    if ((reachMetrics['stability'] ?? 0.0) < 0.6) {
      issues.add('Position is unstable');
      recommendations
          .add('Hold the maximum reach position steadily for 2-3 seconds');
    }

    if ((reachMetrics['technique'] ?? 0.0) < 0.6) {
      issues.add('Technique needs improvement');
      recommendations
          .add('Exhale as you reach forward, maintain progressive stretch');
    }
  }

  /// Calculate overall quality score
  double _calculateQualityScore(
    Map<String, double> postureMetrics,
    Map<String, double> legMetrics,
    Map<String, double> reachMetrics,
  ) {
    double score = 0.0;

    // Posture contributes 35% to overall score
    score += (postureMetrics['backAlignment'] ?? 0.0) * 15;
    score += (postureMetrics['neckPosition'] ?? 0.0) * 10;
    score += (postureMetrics['shoulderRelaxation'] ?? 0.0) * 10;

    // Legs contribute 35% to overall score
    score += (legMetrics['kneeExtension'] ?? 0.0) * 25;
    score += (legMetrics['legSymmetry'] ?? 0.0) * 10;

    // Reach technique contributes 30% to overall score
    score += (reachMetrics['smoothness'] ?? 0.0) * 10;
    score += (reachMetrics['stability'] ?? 0.0) * 10;
    score += (reachMetrics['technique'] ?? 0.0) * 10;

    return score.clamp(0, 100);
  }

  /// Determine form quality from score
  FlexibilityFormQuality _determineFormQuality(double score) {
    if (score >= 85) return FlexibilityFormQuality.excellent;
    if (score >= 70) return FlexibilityFormQuality.good;
    if (score >= 55) return FlexibilityFormQuality.fair;
    return FlexibilityFormQuality.poor;
  }

  /// Create default metrics when insufficient data
  FlexibilityFormMetrics _createDefaultMetrics() {
    return FlexibilityFormMetrics(
      testType: testType,
      backAlignment: 0.0,
      neckPosition: 0.0,
      shoulderRelaxation: 0.0,
      kneeExtension: 0.0,
      legSymmetry: 0.0,
      legSpreadAngle: 0.0,
      reachSmoothness: 0.0,
      holdStability: 0.0,
      properTechnique: 0.0,
      overallQuality: FlexibilityFormQuality.poor,
      qualityScore: 0.0,
      issues: ['Insufficient data for analysis'],
      recommendations: ['Continue performing the exercise to gather data'],
    );
  }

  /// Find a specific keypoint
  Keypoint? _findKeypoint(List<Keypoint> keypoints, String name) {
    try {
      return keypoints.firstWhere(
        (kp) => kp.name == name,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate angle between three points (in degrees)
  double _calculateAngle(Keypoint a, Keypoint b, Keypoint c) {
    final ba = Point(a.x - b.x, a.y - b.y);
    final bc = Point(c.x - b.x, c.y - b.y);

    final dotProduct = ba.x * bc.x + ba.y * bc.y;
    final magnitudeBA = sqrt(ba.x * ba.x + ba.y * ba.y);
    final magnitudeBC = sqrt(bc.x * bc.x + bc.y * bc.y);

    if (magnitudeBA == 0 || magnitudeBC == 0) return 0;

    final cosAngle = dotProduct / (magnitudeBA * magnitudeBC);
    final angle = acos(cosAngle.clamp(-1.0, 1.0)) * 180 / pi;

    return angle;
  }

  /// Reset the analyzer
  void reset() {
    _poseHistory.clear();
    _timestampHistory.clear();
    _reachPositions.clear();
    _kneeAngles.clear();
  }
}
