/// Represents a single body keypoint detected by MoveNet.
/// Contains 2D coordinates and confidence score.
class Keypoint {
  final String name;
  final double x; // Normalized 0.0-1.0
  final double y; // Normalized 0.0-1.0
  final double confidence; // 0.0-1.0

  const Keypoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  factory Keypoint.fromList(String name, List<dynamic> coords) {
    return Keypoint(
      name: name,
      x: coords[1].toDouble(), // MoveNet returns [y, x, score]
      y: coords[0].toDouble(),
      confidence: coords[2].toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'x': x,
        'y': y,
        'confidence': confidence,
      };

  @override
  String toString() => '$name: ($x, $y) @ ${confidence.toStringAsFixed(2)}';
}

/// MoveNet keypoint names (17 keypoints - Single Pose Lightning/Thunder)
class KeypointNames {
  static const String nose = 'nose';
  static const String leftEye = 'left_eye';
  static const String rightEye = 'right_eye';
  static const String leftEar = 'left_ear';
  static const String rightEar = 'right_ear';
  static const String leftShoulder = 'left_shoulder';
  static const String rightShoulder = 'right_shoulder';
  static const String leftElbow = 'left_elbow';
  static const String rightElbow = 'right_elbow';
  static const String leftWrist = 'left_wrist';
  static const String rightWrist = 'right_wrist';
  static const String leftHip = 'left_hip';
  static const String rightHip = 'right_hip';
  static const String leftKnee = 'left_knee';
  static const String rightKnee = 'right_knee';
  static const String leftAnkle = 'left_ankle';
  static const String rightAnkle = 'right_ankle';

  static const List<String> all = [
    nose,
    leftEye,
    rightEye,
    leftEar,
    rightEar,
    leftShoulder,
    rightShoulder,
    leftElbow,
    rightElbow,
    leftWrist,
    rightWrist,
    leftHip,
    rightHip,
    leftKnee,
    rightKnee,
    leftAnkle,
    rightAnkle,
  ];

  /// Skeleton connections for drawing pose overlay
  static const List<List<String>> connections = [
    // Face
    [nose, leftEye],
    [leftEye, leftEar],
    [nose, rightEye],
    [rightEye, rightEar],
    // Torso
    [leftShoulder, rightShoulder],
    [leftShoulder, leftHip],
    [rightShoulder, rightHip],
    [leftHip, rightHip],
    // Left arm
    [leftShoulder, leftElbow],
    [leftElbow, leftWrist],
    // Right arm
    [rightShoulder, rightElbow],
    [rightElbow, rightWrist],
    // Left leg
    [leftHip, leftKnee],
    [leftKnee, leftAnkle],
    // Right leg
    [rightHip, rightKnee],
    [rightKnee, rightAnkle],
  ];
}
