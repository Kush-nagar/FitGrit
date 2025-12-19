/// Unit tests for PoseUtils
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/models/keypoint.dart';
import 'package:nutriscan/utils/pose_utils.dart';

void main() {
  group('PoseUtils - Bounding Box Tests', () {
    test('should calculate correct bounding box for keypoints', () {
      final keypoints = [
        const Keypoint(name: 'nose', x: 0.5, y: 0.2, confidence: 0.9),
        const Keypoint(name: 'left_shoulder', x: 0.3, y: 0.4, confidence: 0.9),
        const Keypoint(name: 'right_shoulder', x: 0.7, y: 0.4, confidence: 0.9),
        const Keypoint(name: 'left_hip', x: 0.3, y: 0.7, confidence: 0.9),
        const Keypoint(name: 'right_hip', x: 0.7, y: 0.7, confidence: 0.9),
      ];

      const canvasSize = Size(640, 480);
      final bbox = PoseUtils.calculatePoseBoundingBox(keypoints, canvasSize);

      expect(bbox, isNotNull);
      expect(bbox!.left, lessThan(0.3 * 640));
      expect(bbox.right, greaterThan(0.7 * 640));
      expect(bbox.top, lessThan(0.2 * 480));
      expect(bbox.bottom, greaterThan(0.7 * 480));
    });

    test('should return null for empty keypoints', () {
      final bbox = PoseUtils.calculatePoseBoundingBox([], const Size(640, 480));
      expect(bbox, isNull);
    });
  });

  group('PoseUtils - Keypoint Smoothing Tests', () {
    test('should smooth keypoints using EMA', () {
      final current = [
        const Keypoint(name: 'nose', x: 0.5, y: 0.2, confidence: 0.9),
      ];

      final previous = [
        const Keypoint(name: 'nose', x: 0.4, y: 0.15, confidence: 0.85),
      ];

      final smoothed = PoseUtils.smoothKeypoints(
        current: current,
        previous: previous,
        alpha: 0.5,
      );

      expect(smoothed.length, 1);
      expect(smoothed[0].x, closeTo(0.45, 0.01)); // (0.5 + 0.4) / 2
      expect(smoothed[0].y, closeTo(0.175, 0.01)); // (0.2 + 0.15) / 2
    });

    test('should return current keypoints when previous is empty', () {
      final current = [
        const Keypoint(name: 'nose', x: 0.5, y: 0.2, confidence: 0.9),
      ];

      final smoothed = PoseUtils.smoothKeypoints(
        current: current,
        previous: [],
        alpha: 0.5,
      );

      expect(smoothed, equals(current));
    });

    test('should handle mismatched keypoints', () {
      final current = [
        const Keypoint(name: 'nose', x: 0.5, y: 0.2, confidence: 0.9),
        const Keypoint(name: 'left_eye', x: 0.45, y: 0.18, confidence: 0.85),
      ];

      final previous = [
        const Keypoint(name: 'nose', x: 0.4, y: 0.15, confidence: 0.85),
        // Missing left_eye in previous
      ];

      final smoothed = PoseUtils.smoothKeypoints(
        current: current,
        previous: previous,
        alpha: 0.5,
      );

      expect(smoothed.length, 2);

      // Nose should be smoothed
      final noseSmoothed = smoothed.firstWhere((kp) => kp.name == 'nose');
      expect(noseSmoothed.x, closeTo(0.45, 0.01));

      // Left eye should remain unchanged (no previous to smooth with)
      final eyeSmoothed = smoothed.firstWhere((kp) => kp.name == 'left_eye');
      expect(eyeSmoothed.x, 0.45);
      expect(eyeSmoothed.y, 0.18);
    });
  });

  group('PoseUtils - Color Selection Tests', () {
    test('should return correct color for push-up', () {
      expect(PoseColors.forExerciseType('pushUp'), PoseColors.pushUpColor);
      expect(PoseColors.forExerciseType('push_up'), PoseColors.pushUpColor);
    });

    test('should return correct color for pull-up', () {
      expect(PoseColors.forExerciseType('pullUp'), PoseColors.pullUpColor);
      expect(PoseColors.forExerciseType('pull_up'), PoseColors.pullUpColor);
    });

    test('should return correct color for sit-up', () {
      expect(PoseColors.forExerciseType('sitUp'), PoseColors.sitUpColor);
      expect(PoseColors.forExerciseType('sit_up'), PoseColors.sitUpColor);
    });

    test('should return default color for unknown exercise', () {
      expect(PoseColors.forExerciseType('unknown'), Colors.green);
    });
  });

  group('PoseUtils - Drawing Tests', () {
    testWidgets('should draw skeleton without errors', (tester) async {
      final keypoints = [
        const Keypoint(
            name: KeypointNames.nose, x: 0.5, y: 0.2, confidence: 0.9),
        const Keypoint(
            name: KeypointNames.leftShoulder, x: 0.4, y: 0.4, confidence: 0.9),
        const Keypoint(
            name: KeypointNames.rightShoulder, x: 0.6, y: 0.4, confidence: 0.9),
        const Keypoint(
            name: KeypointNames.leftElbow, x: 0.35, y: 0.5, confidence: 0.9),
        const Keypoint(
            name: KeypointNames.rightElbow, x: 0.65, y: 0.5, confidence: 0.9),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPosePainter(keypoints),
              size: const Size(400, 600),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });
}

/// Test painter to verify drawing works without errors
class _TestPosePainter extends CustomPainter {
  final List<Keypoint> keypoints;

  _TestPosePainter(this.keypoints);

  @override
  void paint(Canvas canvas, Size size) {
    PoseUtils.drawPoseSkeleton(
      canvas: canvas,
      size: size,
      keypoints: keypoints,
      repCount: 5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
