import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/models/keypoint.dart';
import 'package:nutriscan/utils/angle_utils.dart';

void main() {
  group('AngleUtils', () {
    group('midpoint', () {
      test('calculates correct midpoint', () {
        final p1 = Keypoint(name: 'p1', x: 0, y: 0, confidence: 1.0);
        final p2 = Keypoint(name: 'p2', x: 10, y: 10, confidence: 0.8);

        final mid = AngleUtils.midpoint(p1, p2);

        expect(mid.x, 5.0);
        expect(mid.y, 5.0);
        expect(mid.confidence, closeTo(0.9, 0.01));
      });
    });

    group('angleBetweenVectors', () {
      test('returns 0° for parallel vectors', () {
        final angle = AngleUtils.angleBetweenVectors(1, 0, 1, 0);
        expect(angle, closeTo(0, 0.01));
      });

      test('returns 90° for perpendicular vectors', () {
        final angle = AngleUtils.angleBetweenVectors(1, 0, 0, 1);
        expect(angle, closeTo(90, 0.01));
      });

      test('returns 180° for opposite vectors', () {
        final angle = AngleUtils.angleBetweenVectors(1, 0, -1, 0);
        expect(angle, closeTo(180, 0.01));
      });

      test('returns 45° for diagonal vectors', () {
        final angle = AngleUtils.angleBetweenVectors(1, 0, 1, 1);
        expect(angle, closeTo(45, 0.01));
      });
    });

    group('angleAtJoint', () {
      test('returns 180° for straight line', () {
        final a = Keypoint(name: 'test', x: 0, y: 0, confidence: 1.0);
        final joint = Keypoint(name: 'test', x: 5, y: 0, confidence: 1.0);
        final b = Keypoint(name: 'test', x: 10, y: 0, confidence: 1.0);

        final angle = AngleUtils.angleAtJoint(a, joint, b);
        expect(angle, closeTo(180, 0.01));
      });

      test('returns 90° for right angle', () {
        final a = Keypoint(name: 'test', x: 0, y: 0, confidence: 1.0);
        final joint = Keypoint(name: 'test', x: 0, y: 5, confidence: 1.0);
        final b = Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);

        final angle = AngleUtils.angleAtJoint(a, joint, b);
        expect(angle, closeTo(90, 0.01));
      });
    });

    group('computeLegSpreadAngle', () {
      test('returns small angle for narrow stance', () {
        final leftHip = Keypoint(name: 'test', x: 4, y: 0, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 6, y: 0, confidence: 1.0);
        final leftKnee = Keypoint(name: 'test', x: 4, y: 5, confidence: 1.0);
        final rightKnee = Keypoint(name: 'test', x: 6, y: 5, confidence: 1.0);

        final angle = AngleUtils.computeLegSpreadAngle(
          leftHip: leftHip,
          rightHip: rightHip,
          leftKnee: leftKnee,
          rightKnee: rightKnee,
        );

        // Knees nearly vertical from hip midpoint
        expect(angle, lessThan(30));
      });

      test('returns ~90° for V-shape', () {
        final leftHip = Keypoint(name: 'test', x: 4, y: 0, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 6, y: 0, confidence: 1.0);
        final leftKnee = Keypoint(name: 'test', x: 0, y: 5, confidence: 1.0);
        final rightKnee = Keypoint(name: 'test', x: 10, y: 5, confidence: 1.0);

        final angle = AngleUtils.computeLegSpreadAngle(
          leftHip: leftHip,
          rightHip: rightHip,
          leftKnee: leftKnee,
          rightKnee: rightKnee,
        );

        // V-shape spread
        expect(angle, greaterThan(80));
        expect(angle, lessThan(100));
      });

      test('returns ~180° for split', () {
        final leftHip = Keypoint(name: 'test', x: 5, y: 0, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 5, y: 0, confidence: 1.0);
        final leftKnee = Keypoint(name: 'test', x: 0, y: 0, confidence: 1.0);
        final rightKnee = Keypoint(name: 'test', x: 10, y: 0, confidence: 1.0);

        final angle = AngleUtils.computeLegSpreadAngle(
          leftHip: leftHip,
          rightHip: rightHip,
          leftKnee: leftKnee,
          rightKnee: rightKnee,
        );

        // Full split
        expect(angle, greaterThan(170));
      });
    });

    group('computeKneeExtensionAngle', () {
      test('returns 180° for straight leg', () {
        final hip = Keypoint(name: 'test', x: 5, y: 0, confidence: 1.0);
        final knee = Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);
        final ankle = Keypoint(name: 'test', x: 5, y: 10, confidence: 1.0);

        final angle = AngleUtils.computeKneeExtensionAngle(
          hip: hip,
          knee: knee,
          ankle: ankle,
        );

        expect(angle, closeTo(180, 0.01));
      });

      test('returns ~90° for bent knee', () {
        final hip = Keypoint(name: 'test', x: 5, y: 0, confidence: 1.0);
        final knee = Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);
        final ankle = Keypoint(name: 'test', x: 10, y: 5, confidence: 1.0);

        final angle = AngleUtils.computeKneeExtensionAngle(
          hip: hip,
          knee: knee,
          ankle: ankle,
        );

        expect(angle, closeTo(90, 0.01));
      });
    });

    group('computeTorsoAngle', () {
      test('returns small angle for upright posture', () {
        final leftHip = Keypoint(name: 'test', x: 4, y: 10, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 6, y: 10, confidence: 1.0);
        final leftShoulder =
            Keypoint(name: 'test', x: 4, y: 0, confidence: 1.0);
        final rightShoulder =
            Keypoint(name: 'test', x: 6, y: 0, confidence: 1.0);

        final angle = AngleUtils.computeTorsoAngle(
          leftHip: leftHip,
          rightHip: rightHip,
          leftShoulder: leftShoulder,
          rightShoulder: rightShoulder,
        );

        // Should be close to 0° for vertical spine
        expect(angle, lessThan(10));
      });

      test('returns larger angle for forward lean', () {
        final leftHip = Keypoint(name: 'test', x: 4, y: 10, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 6, y: 10, confidence: 1.0);
        final leftShoulder =
            Keypoint(name: 'test', x: 8, y: 5, confidence: 1.0);
        final rightShoulder =
            Keypoint(name: 'test', x: 10, y: 5, confidence: 1.0);

        final angle = AngleUtils.computeTorsoAngle(
          leftHip: leftHip,
          rightHip: rightHip,
          leftShoulder: leftShoulder,
          rightShoulder: rightShoulder,
        );

        // Should be larger angle for leaning forward
        expect(angle, greaterThan(30));
      });
    });

    group('computeForwardReach', () {
      test('returns positive value for forward reach', () {
        final leftHip = Keypoint(name: 'test', x: 5, y: 10, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 5, y: 10, confidence: 1.0);
        final leftShoulder =
            Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);
        final rightShoulder =
            Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);
        final leftWrist = Keypoint(name: 'test', x: 10, y: 5, confidence: 1.0);
        final rightWrist = Keypoint(name: 'test', x: 10, y: 5, confidence: 1.0);

        final reach = AngleUtils.computeForwardReach(
          leftHip: leftHip,
          rightHip: rightHip,
          leftShoulder: leftShoulder,
          rightShoulder: rightShoulder,
          leftWrist: leftWrist,
          rightWrist: rightWrist,
        );

        // Wrists are forward of hips
        expect(reach, greaterThan(0));
      });

      test('returns 0 for arms at sides', () {
        final leftHip = Keypoint(name: 'test', x: 5, y: 10, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 5, y: 10, confidence: 1.0);
        final leftShoulder =
            Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);
        final rightShoulder =
            Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);
        final leftWrist = Keypoint(name: 'test', x: 3, y: 8, confidence: 1.0);
        final rightWrist = Keypoint(name: 'test', x: 2, y: 8, confidence: 1.0);

        final reach = AngleUtils.computeForwardReach(
          leftHip: leftHip,
          rightHip: rightHip,
          leftShoulder: leftShoulder,
          rightShoulder: rightShoulder,
          leftWrist: leftWrist,
          rightWrist: rightWrist,
        );

        // Wrists behind hips
        expect(reach, equals(0));
      });
    });

    group('distance', () {
      test('calculates correct Euclidean distance', () {
        final a = Keypoint(name: 'test', x: 0, y: 0, confidence: 1.0);
        final b = Keypoint(name: 'test', x: 3, y: 4, confidence: 1.0);

        final dist = AngleUtils.distance(a, b);
        expect(dist, closeTo(5.0, 0.01));
      });

      test('returns 0 for same point', () {
        final a = Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);
        final b = Keypoint(name: 'test', x: 5, y: 5, confidence: 1.0);

        final dist = AngleUtils.distance(a, b);
        expect(dist, equals(0));
      });
    });

    group('hasGoodConfidence', () {
      test('returns true for high confidence keypoints', () {
        final keypoints = [
          Keypoint(name: 'test', x: 0, y: 0, confidence: 0.9),
          Keypoint(name: 'test', x: 1, y: 1, confidence: 0.8),
          Keypoint(name: 'test', x: 2, y: 2, confidence: 0.95),
        ];

        expect(AngleUtils.hasGoodConfidence(keypoints), isTrue);
      });

      test('returns false for low confidence keypoints', () {
        final keypoints = [
          Keypoint(name: 'test', x: 0, y: 0, confidence: 0.3),
          Keypoint(name: 'test', x: 1, y: 1, confidence: 0.2),
          Keypoint(name: 'test', x: 2, y: 2, confidence: 0.4),
        ];

        expect(AngleUtils.hasGoodConfidence(keypoints), isFalse);
      });

      test('returns false for empty list', () {
        expect(AngleUtils.hasGoodConfidence([]), isFalse);
      });
    });

    group('computeLegSymmetry', () {
      test('returns 0 for symmetric legs', () {
        final leftHip = Keypoint(name: 'test', x: 4, y: 0, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 6, y: 0, confidence: 1.0);
        final leftKnee = Keypoint(name: 'test', x: 2, y: 5, confidence: 1.0);
        final rightKnee = Keypoint(name: 'test', x: 8, y: 5, confidence: 1.0);

        final symmetry = AngleUtils.computeLegSymmetry(
          leftHip: leftHip,
          rightHip: rightHip,
          leftKnee: leftKnee,
          rightKnee: rightKnee,
        );

        expect(symmetry, closeTo(0, 5)); // Allow small tolerance
      });

      test('returns large value for asymmetric legs', () {
        final leftHip = Keypoint(name: 'test', x: 4, y: 0, confidence: 1.0);
        final rightHip = Keypoint(name: 'test', x: 6, y: 0, confidence: 1.0);
        final leftKnee = Keypoint(name: 'test', x: 1, y: 5, confidence: 1.0);
        final rightKnee = Keypoint(name: 'test', x: 7, y: 5, confidence: 1.0);

        final symmetry = AngleUtils.computeLegSymmetry(
          leftHip: leftHip,
          rightHip: rightHip,
          leftKnee: leftKnee,
          rightKnee: rightKnee,
        );

        expect(symmetry, greaterThan(10));
      });
    });
  });
}
