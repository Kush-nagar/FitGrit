/// Unit tests for RepCounter model
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/models/keypoint.dart';
import 'package:nutriscan/models/rep_counter.dart';

void main() {
  group('RepCounter - Push-up Tests', () {
    late RepCounter repCounter;

    setUp(() {
      repCounter = RepCounter(exerciseType: ExerciseType.pushUp);
    });

    test('should initialize with zero reps', () {
      expect(repCounter.repCount, 0);
      expect(repCounter.currentState, RepState.up);
    });

    test('should count a complete push-up rep', () {
      final timestamp = 0;

      // Start position (arms extended)
      final upKeypoints = _createPushUpKeypoints(elbowAngle: 170);
      repCounter.update(upKeypoints, timestamp);
      expect(repCounter.currentState, RepState.up);

      // Down position (arms bent)
      final downKeypoints = _createPushUpKeypoints(elbowAngle: 90);
      repCounter.update(downKeypoints, timestamp + 500);
      expect(repCounter.currentState, RepState.down);

      // Back up (complete rep)
      repCounter.update(upKeypoints, timestamp + 1000);
      expect(repCounter.currentState, RepState.up);
      expect(repCounter.repCount, 1);
    });

    test('should not count partial reps', () {
      final timestamp = 0;

      final upKeypoints = _createPushUpKeypoints(elbowAngle: 170);
      final partialDownKeypoints = _createPushUpKeypoints(elbowAngle: 130);

      repCounter.update(upKeypoints, timestamp);
      repCounter.update(partialDownKeypoints, timestamp + 500);
      repCounter.update(upKeypoints, timestamp + 1000);

      // Should not count as full rep (didn't go below threshold)
      expect(repCounter.repCount, 0);
    });

    test('should reset counter', () {
      final keypoints = _createPushUpKeypoints(elbowAngle: 170);
      repCounter.update(keypoints, 0);

      repCounter.reset();

      expect(repCounter.repCount, 0);
      expect(repCounter.currentState, RepState.up);
      expect(repCounter.repTimeline.isEmpty, true);
    });

    test('should track rep timeline', () {
      final upKeypoints = _createPushUpKeypoints(elbowAngle: 170);
      final downKeypoints = _createPushUpKeypoints(elbowAngle: 90);

      repCounter.update(upKeypoints, 0);
      repCounter.update(downKeypoints, 500);
      repCounter.update(upKeypoints, 1000);

      expect(repCounter.getRepCountAt(0), 0);
      expect(repCounter.getRepCountAt(500), 0);
      expect(repCounter.getRepCountAt(1000), 1);
    });

    test('should create snapshot with correct data', () {
      final keypoints = _createPushUpKeypoints(elbowAngle: 170);
      repCounter.update(keypoints, 0);

      final snapshot = repCounter.snapshot();

      expect(snapshot['repCount'], 0);
      expect(snapshot['state'], 'up');
      expect(snapshot['exerciseType'], 'pushUp');
    });
  });

  group('RepCounter - Pull-up Tests', () {
    late RepCounter repCounter;

    setUp(() {
      repCounter = RepCounter(exerciseType: ExerciseType.pullUp);
    });

    test('should count a complete pull-up rep', () {
      // Down position (hanging)
      final downKeypoints = _createPullUpKeypoints(shoulderWristDistance: 0.35);
      repCounter.update(downKeypoints, 0);
      expect(repCounter.currentState, RepState.down);

      // Up position (chin over bar)
      final upKeypoints = _createPullUpKeypoints(shoulderWristDistance: 0.1);
      repCounter.update(upKeypoints, 800);
      expect(repCounter.currentState, RepState.up);

      // Back down (complete rep)
      repCounter.update(downKeypoints, 1600);
      expect(repCounter.repCount, 1);
    });
  });

  group('RepCounter - Sit-up Tests', () {
    late RepCounter repCounter;

    setUp(() {
      repCounter = RepCounter(exerciseType: ExerciseType.sitUp);
    });

    test('should count a complete sit-up rep', () {
      // Lying down
      final downKeypoints = _createSitUpKeypoints(hipAngle: 170);
      repCounter.update(downKeypoints, 0);

      // Sitting up
      final upKeypoints = _createSitUpKeypoints(hipAngle: 90);
      repCounter.update(upKeypoints, 700);
      expect(repCounter.currentState, RepState.up);

      // Back down (complete rep)
      repCounter.update(downKeypoints, 1400);
      expect(repCounter.repCount, 1);
    });
  });

  group('RepCounter - Debouncing Tests', () {
    test('should debounce rapid transitions', () {
      final repCounter = RepCounter(
        exerciseType: ExerciseType.pushUp,
        transitionDebounce: 300,
      );

      final upKeypoints = _createPushUpKeypoints(elbowAngle: 170);
      final downKeypoints = _createPushUpKeypoints(elbowAngle: 90);

      repCounter.update(upKeypoints, 0);
      repCounter.update(downKeypoints, 100); // Too soon
      repCounter.update(upKeypoints, 200); // Too soon

      expect(repCounter.repCount, 0); // Should not count due to debounce

      repCounter.update(downKeypoints, 500); // After debounce
      repCounter.update(upKeypoints, 1000); // After debounce

      expect(repCounter.repCount, 1); // Should count now
    });
  });
}

// Helper functions to create synthetic keypoints for testing

List<Keypoint> _createPushUpKeypoints({required double elbowAngle}) {
  // Simplified keypoints for push-up detection
  // Elbow angle: 180° = straight (up), 90° = bent (down)

  final shoulderY = 0.3;
  final wristY = 0.5;

  // Calculate elbow position based on desired angle
  final angleRad = elbowAngle * 3.14159 / 180;
  final elbowY = shoulderY + (wristY - shoulderY) * 0.5;
  final elbowX = 0.3 + (1 - angleRad / 3.14159) * 0.1;

  return [
    const Keypoint(
        name: KeypointNames.leftShoulder, x: 0.3, y: 0.3, confidence: 0.9),
    Keypoint(
        name: KeypointNames.leftElbow, x: elbowX, y: elbowY, confidence: 0.9),
    const Keypoint(
        name: KeypointNames.leftWrist, x: 0.25, y: 0.5, confidence: 0.9),
    const Keypoint(
        name: KeypointNames.rightShoulder, x: 0.7, y: 0.3, confidence: 0.9),
    Keypoint(
        name: KeypointNames.rightElbow,
        x: 1 - elbowX,
        y: elbowY,
        confidence: 0.9),
    const Keypoint(
        name: KeypointNames.rightWrist, x: 0.75, y: 0.5, confidence: 0.9),
  ];
}

List<Keypoint> _createPullUpKeypoints({required double shoulderWristDistance}) {
  // Distance: small = up, large = down
  final shoulderY = 0.2 + shoulderWristDistance;

  return [
    Keypoint(
        name: KeypointNames.leftShoulder,
        x: 0.4,
        y: shoulderY,
        confidence: 0.9),
    Keypoint(
        name: KeypointNames.rightShoulder,
        x: 0.6,
        y: shoulderY,
        confidence: 0.9),
    const Keypoint(
        name: KeypointNames.leftWrist, x: 0.4, y: 0.2, confidence: 0.9),
    const Keypoint(
        name: KeypointNames.rightWrist, x: 0.6, y: 0.2, confidence: 0.9),
  ];
}

List<Keypoint> _createSitUpKeypoints({required double hipAngle}) {
  // Hip angle: 90° = sitting up, 180° = lying down

  final kneeY = 0.6;
  final hipY = 0.5;
  final shoulderY = hipY - (hipAngle - 90) / 180 * 0.2;

  return [
    Keypoint(
        name: KeypointNames.leftShoulder,
        x: 0.45,
        y: shoulderY,
        confidence: 0.9),
    Keypoint(
        name: KeypointNames.rightShoulder,
        x: 0.55,
        y: shoulderY,
        confidence: 0.9),
    Keypoint(name: KeypointNames.leftHip, x: 0.45, y: hipY, confidence: 0.9),
    Keypoint(name: KeypointNames.rightHip, x: 0.55, y: hipY, confidence: 0.9),
    Keypoint(name: KeypointNames.leftKnee, x: 0.45, y: kneeY, confidence: 0.9),
    Keypoint(name: KeypointNames.rightKnee, x: 0.55, y: kneeY, confidence: 0.9),
  ];
}
