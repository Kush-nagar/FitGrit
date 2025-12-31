/// Service for calculating flexibility metrics from sit-and-reach and v-sit-and-reach poses.
/// Uses pose estimation to measure reach distance and flexibility scores.
import 'dart:math';
import '../models/keypoint.dart';

/// Types of flexibility tests
enum FlexibilityTestType {
  sitAndReach,
  vSitAndReach,
}

/// Flexibility metrics calculated from pose analysis
class FlexibilityMetrics {
  final FlexibilityTestType testType;
  final double reachDistance; // cm from starting position
  final double maxReachDistance; // peak reach achieved
  final double flexibilityScore; // 0-100 rating
  final double hamstringFlexibility; // degrees
  final double lowerBackFlexibility; // degrees
  final double hipFlexibility; // degrees
  final String rating; // Excellent, Good, Fair, Poor
  final List<double> reachProfile; // reach distance over time

  FlexibilityMetrics({
    required this.testType,
    required this.reachDistance,
    required this.maxReachDistance,
    required this.flexibilityScore,
    required this.hamstringFlexibility,
    required this.lowerBackFlexibility,
    required this.hipFlexibility,
    required this.rating,
    required this.reachProfile,
  });

  @override
  String toString() {
    return '''
Flexibility Metrics (${_testTypeName(testType)}):
├─ Reach Distance: ${reachDistance.toStringAsFixed(1)}cm
├─ Max Reach: ${maxReachDistance.toStringAsFixed(1)}cm
├─ Flexibility Score: ${flexibilityScore.toStringAsFixed(1)}/100
├─ Rating: $rating
├─ Hamstring: ${hamstringFlexibility.toStringAsFixed(1)}°
└─ Lower Back: ${lowerBackFlexibility.toStringAsFixed(1)}°
''';
  }

  String _testTypeName(FlexibilityTestType type) {
    switch (type) {
      case FlexibilityTestType.sitAndReach:
        return 'Sit and Reach';
      case FlexibilityTestType.vSitAndReach:
        return 'V Sit and Reach';
    }
  }
}

class FlexibilityMetricsCalculator {
  final FlexibilityTestType testType;
  final double participantHeight; // meters (used for calibration)

  // Historical data
  final List<List<Keypoint>> _poseHistory = [];
  final List<double> _reachDistances = [];

  // Baseline measurements (starting position)
  List<Keypoint>? _baselinePose;
  double? _baselineFingerX;

  FlexibilityMetricsCalculator({
    required this.testType,
    this.participantHeight = 1.75,
  });

  /// Set the baseline pose (starting position before reaching)
  void setBaseline(List<Keypoint> keypoints) {
    _baselinePose = List.from(keypoints);

    // Get baseline finger position (we'll track hands/wrists as proxy)
    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);

    if (leftWrist != null && rightWrist != null) {
      _baselineFingerX = (leftWrist.x + rightWrist.x) / 2;
    }
  }

  /// Add a frame to the analysis
  void addFrame(List<Keypoint> keypoints) {
    _poseHistory.add(List.from(keypoints));

    // Calculate reach distance for this frame
    if (_baselineFingerX != null) {
      final reachDist = _calculateReachDistance(keypoints);
      _reachDistances.add(reachDist);
    }
  }

  /// Calculate flexibility metrics from accumulated frames
  FlexibilityMetrics calculateMetrics() {
    if (_poseHistory.isEmpty || _baselinePose == null) {
      return _createDefaultMetrics();
    }

    // Get the frame with maximum reach
    final maxReachFrame = _findMaxReachFrame();

    // Calculate various flexibility measurements
    final currentReach =
        _reachDistances.isNotEmpty ? _reachDistances.last : 0.0;
    final maxReach = _reachDistances.isNotEmpty
        ? _reachDistances.reduce((a, b) => a > b ? a : b)
        : 0.0;

    final hamstringFlex = _calculateHamstringFlexibility(maxReachFrame);
    final lowerBackFlex = _calculateLowerBackFlexibility(maxReachFrame);
    final hipFlex = _calculateHipFlexibility(maxReachFrame);

    // Calculate overall flexibility score
    final flexScore = _calculateFlexibilityScore(
      maxReach,
      hamstringFlex,
      lowerBackFlex,
      hipFlex,
    );

    final rating = _determineRating(flexScore);

    return FlexibilityMetrics(
      testType: testType,
      reachDistance: currentReach,
      maxReachDistance: maxReach,
      flexibilityScore: flexScore,
      hamstringFlexibility: hamstringFlex,
      lowerBackFlexibility: lowerBackFlex,
      hipFlexibility: hipFlex,
      rating: rating,
      reachProfile: List.from(_reachDistances),
    );
  }

  /// Calculate reach distance from baseline
  double _calculateReachDistance(List<Keypoint> keypoints) {
    if (_baselineFingerX == null) return 0.0;

    final leftWrist = _findKeypoint(keypoints, KeypointNames.leftWrist);
    final rightWrist = _findKeypoint(keypoints, KeypointNames.rightWrist);

    if (leftWrist == null || rightWrist == null) return 0.0;

    final currentFingerX = (leftWrist.x + rightWrist.x) / 2;

    // Calculate horizontal reach
    final reachNormalized = (currentFingerX - _baselineFingerX!).abs();

    // Convert to centimeters (approximate based on participant height)
    // Assume person's arm span ≈ height, and they occupy about 0.7 of frame width
    final frameWidthMeters = participantHeight / 0.7;
    final reachMeters = reachNormalized * frameWidthMeters;
    final reachCm = reachMeters * 100;

    return reachCm;
  }

  /// Find the frame with maximum reach
  List<Keypoint> _findMaxReachFrame() {
    if (_poseHistory.isEmpty) return [];

    double maxReach = 0.0;
    int maxReachIdx = _poseHistory.length - 1;

    for (int i = 0; i < _reachDistances.length; i++) {
      if (_reachDistances[i] > maxReach) {
        maxReach = _reachDistances[i];
        maxReachIdx = i;
      }
    }

    return _poseHistory[maxReachIdx];
  }

  /// Calculate hamstring flexibility based on knee angle
  double _calculateHamstringFlexibility(List<Keypoint> keypoints) {
    if (keypoints.isEmpty) return 0.0;

    // For sit-and-reach, measure angle at knee joint
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final leftKnee = _findKeypoint(keypoints, KeypointNames.leftKnee);
    final leftAnkle = _findKeypoint(keypoints, KeypointNames.leftAnkle);

    if (leftHip != null && leftKnee != null && leftAnkle != null) {
      final angle = _calculateAngle(leftHip, leftKnee, leftAnkle);
      // More straight leg = better flexibility (closer to 180°)
      return angle;
    }

    return 0.0;
  }

  /// Calculate lower back flexibility based on spine curve
  double _calculateLowerBackFlexibility(List<Keypoint> keypoints) {
    if (keypoints.isEmpty) return 0.0;

    final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
    final rightShoulder = _findKeypoint(keypoints, KeypointNames.rightShoulder);
    final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
    final rightHip = _findKeypoint(keypoints, KeypointNames.rightHip);

    if (leftShoulder != null &&
        rightShoulder != null &&
        leftHip != null &&
        rightHip != null) {
      // Calculate shoulder midpoint and hip midpoint
      final shoulderMid = Keypoint(
        x: (leftShoulder.x + rightShoulder.x) / 2,
        y: (leftShoulder.y + rightShoulder.y) / 2,
        confidence: (leftShoulder.confidence + rightShoulder.confidence) / 2,
        name: 'shoulderMid',
      );

      final hipMid = Keypoint(
        x: (leftHip.x + rightHip.x) / 2,
        y: (leftHip.y + rightHip.y) / 2,
        confidence: (leftHip.confidence + rightHip.confidence) / 2,
        name: 'hipMid',
      );

      // Angle from hip to shoulder relative to vertical
      // More forward bend = better flexibility
      final angle = atan2(
            shoulderMid.y - hipMid.y,
            shoulderMid.x - hipMid.x,
          ) *
          180 /
          pi;

      return angle.abs();
    }

    return 0.0;
  }

  /// Calculate hip flexibility
  double _calculateHipFlexibility(List<Keypoint> keypoints) {
    if (keypoints.isEmpty) return 0.0;

    if (testType == FlexibilityTestType.vSitAndReach) {
      // For V sit-and-reach, measure leg spread angle
      final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
      final leftKnee = _findKeypoint(keypoints, KeypointNames.leftKnee);
      final rightKnee = _findKeypoint(keypoints, KeypointNames.rightKnee);

      if (leftHip != null && leftKnee != null && rightKnee != null) {
        final angle = _calculateAngle(leftKnee, leftHip, rightKnee);
        return angle;
      }
    } else {
      // For regular sit-and-reach, measure hip flexion
      final leftShoulder = _findKeypoint(keypoints, KeypointNames.leftShoulder);
      final leftHip = _findKeypoint(keypoints, KeypointNames.leftHip);
      final leftKnee = _findKeypoint(keypoints, KeypointNames.leftKnee);

      if (leftShoulder != null && leftHip != null && leftKnee != null) {
        final angle = _calculateAngle(leftShoulder, leftHip, leftKnee);
        // Smaller angle = better hip flexion
        return 180 - angle;
      }
    }

    return 0.0;
  }

  /// Calculate overall flexibility score (0-100)
  double _calculateFlexibilityScore(
    double reachDistance,
    double hamstringFlex,
    double lowerBackFlex,
    double hipFlex,
  ) {
    double score = 0.0;

    // Reach distance component (0-40 points)
    // Excellent: >30cm, Good: 20-30cm, Fair: 10-20cm, Poor: <10cm
    if (reachDistance > 30) {
      score += 40;
    } else if (reachDistance > 20) {
      score += 30 + (reachDistance - 20) * 1.0;
    } else if (reachDistance > 10) {
      score += 20 + (reachDistance - 10) * 1.0;
    } else {
      score += reachDistance * 2.0;
    }

    // Hamstring flexibility (0-25 points)
    // Closer to 180° is better
    final hamstringScore = ((hamstringFlex - 90) / 90) * 25;
    score += hamstringScore.clamp(0, 25);

    // Lower back flexibility (0-20 points)
    final lowerBackScore = (lowerBackFlex / 90) * 20;
    score += lowerBackScore.clamp(0, 20);

    // Hip flexibility (0-15 points)
    if (testType == FlexibilityTestType.vSitAndReach) {
      // Wider spread is better for V sit
      final hipScore = (hipFlex / 120) * 15;
      score += hipScore.clamp(0, 15);
    } else {
      // Greater hip flexion is better for regular sit-and-reach
      final hipScore = (hipFlex / 90) * 15;
      score += hipScore.clamp(0, 15);
    }

    return score.clamp(0, 100);
  }

  /// Determine rating based on score
  String _determineRating(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  /// Find a specific keypoint in the list
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

  /// Create default metrics when insufficient data
  FlexibilityMetrics _createDefaultMetrics() {
    return FlexibilityMetrics(
      testType: testType,
      reachDistance: 0.0,
      maxReachDistance: 0.0,
      flexibilityScore: 0.0,
      hamstringFlexibility: 0.0,
      lowerBackFlexibility: 0.0,
      hipFlexibility: 0.0,
      rating: 'Insufficient Data',
      reachProfile: [],
    );
  }

  /// Reset the calculator
  void reset() {
    _poseHistory.clear();
    _reachDistances.clear();
    _baselinePose = null;
    _baselineFingerX = null;
  }
}
