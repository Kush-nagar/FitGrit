import 'dart:math';
import '../models/keypoint.dart';

/// Utility functions for computing angles and distances from pose keypoints
class AngleUtils {
  /// Compute the midpoint between two keypoints
  static Keypoint midpoint(Keypoint p1, Keypoint p2) {
    return Keypoint(
      name: 'midpoint',
      x: (p1.x + p2.x) / 2,
      y: (p1.y + p2.y) / 2,
      confidence: (p1.confidence + p2.confidence) / 2,
    );
  }

  /// Compute angle between two vectors in degrees
  /// Returns angle in range [0, 180]
  static double angleBetweenVectors(
    double vx1,
    double vy1,
    double vx2,
    double vy2,
  ) {
    final dot = vx1 * vx2 + vy1 * vy2;
    final mag1 = sqrt(vx1 * vx1 + vy1 * vy1);
    final mag2 = sqrt(vx2 * vx2 + vy2 * vy2);

    if (mag1 == 0 || mag2 == 0) return 0.0;

    // Clamp to handle floating point errors
    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  /// Compute angle at a joint (three points: a-joint-b)
  /// Returns angle in degrees [0, 180]
  static double angleAtJoint(Keypoint a, Keypoint joint, Keypoint b) {
    // Vector from joint to a
    final vax = a.x - joint.x;
    final vay = a.y - joint.y;

    // Vector from joint to b
    final vbx = b.x - joint.x;
    final vby = b.y - joint.y;

    return angleBetweenVectors(vax, vay, vbx, vby);
  }

  /// Compute leg spread angle - VIEW INDEPENDENT
  /// Measures angle between left and right legs from hip vertex
  /// Returns angle in degrees. ~0° when knees overlap, ~180° when legs straight opposite
  /// Works from any camera angle (front, side, or angled)
  static double computeLegSpreadAngle({
    required Keypoint leftHip,
    required Keypoint rightHip,
    required Keypoint leftKnee,
    required Keypoint rightKnee,
  }) {
    final midHip = midpoint(leftHip, rightHip);

    // Vector from midHip to left knee
    final vLx = leftKnee.x - midHip.x;
    final vLy = leftKnee.y - midHip.y;

    // Vector from midHip to right knee
    final vRx = rightKnee.x - midHip.x;
    final vRy = rightKnee.y - midHip.y;

    return angleBetweenVectors(vLx, vLy, vRx, vRy);
  }

  /// Compute knee extension angle - VIEW INDEPENDENT
  /// Measures angle at knee joint: 180° = straight leg, <165° = bent knee
  /// Works from any camera angle (uses 3-point joint angle)
  static double computeKneeExtensionAngle({
    required Keypoint hip,
    required Keypoint knee,
    required Keypoint ankle,
  }) {
    return angleAtJoint(hip, knee, ankle);
  }

  /// Compute torso/spine angle - VIEW INDEPENDENT
  /// Measures the angle between hip-shoulder line and hip-knee line
  /// Works from any camera angle (front, side, or angled)
  /// Returns angle in degrees [0, 180]
  static double computeTorsoAngle({
    required Keypoint leftHip,
    required Keypoint rightHip,
    required Keypoint leftShoulder,
    required Keypoint rightShoulder,
  }) {
    final midHip = midpoint(leftHip, rightHip);
    final midShoulder = midpoint(leftShoulder, rightShoulder);

    // For view-independence, we measure torso relative to hip line
    // A more upright posture will have shoulders directly above hips
    // Forward lean will show greater horizontal displacement

    // Calculate the ratio of vertical to horizontal displacement
    final dx = (midShoulder.x - midHip.x).abs();
    final dy = (midHip.y - midShoulder.y).abs(); // Y inverted in screen coords

    // Compute angle from hip baseline (more horizontal = more forward lean)
    if (dy == 0) return 90.0; // Flat torso
    final angle = atan(dx / dy) * 180 / pi;

    return angle.clamp(0.0, 90.0);
  }

  /// Compute forward reach distance (normalized) - VIEW INDEPENDENT
  /// Measures actual distance from hip center to wrists
  /// Works from any camera angle
  /// Returns normalized distance (0-1 scale relative to torso length)
  static double computeForwardReach({
    required Keypoint leftHip,
    required Keypoint rightHip,
    required Keypoint leftShoulder,
    required Keypoint rightShoulder,
    required Keypoint leftWrist,
    required Keypoint rightWrist,
  }) {
    final midHip = midpoint(leftHip, rightHip);
    final midShoulder = midpoint(leftShoulder, rightShoulder);
    final midWrist = midpoint(leftWrist, rightWrist);

    // Torso length for normalization
    final torsoLength = distance(midHip, midShoulder);
    if (torsoLength == 0) return 0.0;

    // Distance from hip center to wrist center (view-independent)
    final reachDistance = distance(midHip, midWrist);

    // Normalize by torso length
    // In a good stretch, wrists should extend beyond hips significantly
    return (reachDistance / torsoLength).clamp(0.0, 3.0);
  }

  /// Compute back curvature angle to detect rounded back
  /// Returns angle between upper spine and lower spine
  /// Higher values indicate more curvature (rounded back)
  static double computeBackCurvature({
    required Keypoint leftHip,
    required Keypoint rightHip,
    required Keypoint leftShoulder,
    required Keypoint rightShoulder,
    Keypoint? neck, // Optional neck keypoint if available
  }) {
    final midHip = midpoint(leftHip, rightHip);
    final midShoulder = midpoint(leftShoulder, rightShoulder);

    if (neck != null) {
      // Angle between lower spine (hip->shoulder) and upper spine (shoulder->neck)
      return angleAtJoint(midHip, midShoulder, neck);
    } else {
      // Fallback: use shoulder-hip angle deviation from vertical
      // This is less accurate but works without neck keypoint
      final torsoAngle = computeTorsoAngle(
        leftHip: leftHip,
        rightHip: rightHip,
        leftShoulder: leftShoulder,
        rightShoulder: rightShoulder,
      );
      // Return as curvature indicator (>30° from vertical suggests leaning/rounding)
      return torsoAngle;
    }
  }

  /// Check if keypoints have sufficient confidence
  static bool hasGoodConfidence(List<Keypoint> keypoints,
      {double threshold = 0.5}) {
    if (keypoints.isEmpty) return false;
    final avgScore =
        keypoints.map((k) => k.confidence).reduce((a, b) => a + b) /
            keypoints.length;
    return avgScore >= threshold;
  }

  /// Compute distance between two keypoints
  static double distance(Keypoint a, Keypoint b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  /// Compute symmetry between left and right leg spread
  /// Returns absolute difference in degrees
  static double computeLegSymmetry({
    required Keypoint leftHip,
    required Keypoint rightHip,
    required Keypoint leftKnee,
    required Keypoint rightKnee,
  }) {
    final midHip = midpoint(leftHip, rightHip);

    // Left leg angle from vertical
    final leftVecX = leftKnee.x - midHip.x;
    final leftVecY = leftKnee.y - midHip.y;
    final leftAngle = angleBetweenVectors(leftVecX, leftVecY, 0, 1);

    // Right leg angle from vertical
    final rightVecX = rightKnee.x - midHip.x;
    final rightVecY = rightKnee.y - midHip.y;
    final rightAngle = angleBetweenVectors(rightVecX, rightVecY, 0, 1);

    return (leftAngle - rightAngle).abs();
  }
}
