import 'dart:typed_data';

/// Represents a single video frame with timestamp for pose estimation.
class VideoFrame {
  final Uint8List rgbBytes;
  final int width;
  final int height;
  final int timestampMillis;
  final int rotation; // 0, 90, 180, 270

  const VideoFrame({
    required this.rgbBytes,
    required this.width,
    required this.height,
    required this.timestampMillis,
    this.rotation = 0,
  });

  /// Create from camera image-like buffer
  factory VideoFrame.fromBytes({
    required Uint8List bytes,
    required int width,
    required int height,
    required int timestampMillis,
    int rotation = 0,
  }) {
    return VideoFrame(
      rgbBytes: bytes,
      width: width,
      height: height,
      timestampMillis: timestampMillis,
      rotation: rotation,
    );
  }

  @override
  String toString() =>
      'VideoFrame(${width}x$height, ${timestampMillis}ms, rot:$rotation°)';
}
