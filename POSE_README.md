# MoveNet Pose Estimation & Rep Counter

On-device pose estimation using TensorFlow Lite MoveNet for exercise rep counting (push-ups, pull-ups, sit-ups) with real-time camera feed and video file processing capabilities.

## Features

- **Real-time Camera Pose Estimation**: Live skeleton overlay with rep counting
- **Video Processing**: Pick videos, analyze frame-by-frame, annotate with pose overlays
- **Annotated Video Export**: Generate MP4 files with pose skeleton and rep counter overlay
- **Exercise-Specific Rep Counting**: Intelligent algorithms for push-ups, pull-ups, and sit-ups
- **Smooth Tracking**: Keypoint smoothing to reduce jitter
- **High-Performance**: Optimized for mobile devices with configurable FPS downsampling

## Setup Instructions

### 1. Install Dependencies

Dependencies are already added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

### 2. Download MoveNet Model

Download the TFLite model from [TensorFlow Hub](https://tfhub.dev/google/movenet/singlepose/lightning):

- Model: **MoveNet Single Pose Lightning (INT8 Quantized)**
- File: `movenet_single_pose_lightning_int8.tflite`

Place the model file in your project:

```
assets/models/movenet_single_pose_lightning_int8.tflite
```

Update `pubspec.yaml` to include the model:

```yaml
flutter:
  assets:
    - assets/
    - assets/images/
    - assets/models/movenet_single_pose_lightning_int8.tflite
```

### 3. Platform-Specific Configuration

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add camera and storage permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Android 13+ photo picker -->
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for camera and video features
    }
}
```

#### iOS (`ios/Runner/Info.plist`)

Add camera and photo library usage descriptions:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access for real-time pose estimation and rep counting.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record video with audio.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select videos for analysis.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need photo library access to save annotated videos.</string>
```

Set minimum iOS version in `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

## Usage

### Real-Time Camera Mode

1. Launch the app and tap **"Camera"** button
2. Select exercise type from dropdown (Push-Up, Pull-Up, or Sit-Up)
3. Position yourself in frame and start exercising
4. Rep counter updates automatically as you perform reps
5. Pose skeleton overlay shows detected keypoints in real-time

### Video Processing Mode

1. Tap **"Pick Video"** to select a video from gallery
2. Once loaded, tap **"Analyze"** to process the video
3. Wait for frame-by-frame analysis (progress bar shows status)
4. After analysis, video playback shows rep count overlay
5. Tap **"Export"** to generate annotated MP4 with skeleton overlay

### Video Export Details

The export process:

1. Extracts frames from original video at target FPS (default: 15 fps)
2. Runs pose estimation on each frame
3. Renders skeleton overlay and rep counter on each frame
4. Stitches frames back into MP4 using FFmpeg
5. Optionally copies audio from original video

**Export Command (FFmpeg):**

```bash
# Video with audio
ffmpeg -framerate 15 -i frames/frame_%04d.png -i original.mp4 \
  -map 0:v -map 1:a? -c:v libx264 -preset fast -crf 18 \
  -pix_fmt yuv420p -c:a copy output.mp4

# Video only (no audio)
ffmpeg -framerate 15 -i frames/frame_%04d.png \
  -c:v libx264 -preset fast -crf 18 \
  -pix_fmt yuv420p output.mp4
```

## Architecture

### Core Components

- **PoseEstimator** (`lib/services/pose_estimator.dart`): TFLite MoveNet inference wrapper
- **RepCounter** (`lib/models/rep_counter.dart`): Exercise-specific rep counting logic
- **CameraService** (`lib/services/camera_service.dart`): Real-time camera stream management
- **VideoService** (`lib/services/video_service.dart`): Video file processing and FFmpeg export
- **PoseUtils** (`lib/utils/pose_utils.dart`): Drawing utilities for skeleton overlay
- **PosePainter** (`lib/widgets/pose_painter.dart`): Custom painter for pose visualization

### Data Flow

**Camera Mode:**

```
CameraService → CameraImage → PoseEstimator → Keypoints → RepCounter → UI Update
```

**Video Mode:**

```
VideoService → Extract Frames → PoseEstimator → Keypoints + Timeline →
  RepCounter → Annotate Frames → FFmpeg Export → MP4
```

## Performance Optimization

### For Long Videos

- **Downsample FPS**: Process at 10-15 fps instead of original 30 fps
- **Batch Processing**: Process frames in batches to manage memory
- **Isolate Execution**: Run inference in background isolate to avoid blocking UI
- **Progress Tracking**: Show progress bar during analysis and export

### Frame Extraction Methods

1. **FFmpeg (Recommended)**: More reliable, extracts all frames to disk first
2. **video_player**: Direct frame extraction (platform-dependent, may have limitations)

To use FFmpeg extraction:

```dart
final frames = await videoService.extractFramesWithFFmpeg(
  videoPath,
  targetFps: 15,
);
```

### Hardware Acceleration

Enable GPU delegates for faster inference:

**Android:**

```dart
InterpreterOptions()
  ..useNnApiForAndroid = true  // Android Neural Networks API
```

**iOS:**

```dart
InterpreterOptions()
  ..useMetalDelegate = true  // Metal GPU acceleration
```

## Testing

Run unit tests:

```bash
flutter test
```

Tests cover:

- Rep counter logic for all exercise types
- Keypoint smoothing algorithms
- Frame timestamp mapping
- Bounding box calculations

## Troubleshooting

### Issue: Model not found

**Solution**: Ensure `movenet_single_pose_lightning_int8.tflite` is in `assets/models/` and listed in `pubspec.yaml`

### Issue: Camera permission denied

**Solution**: Check platform-specific permission strings and request permissions at runtime

### Issue: Video export fails

**Solution**: Verify FFmpeg is working (`ffmpeg_kit_flutter_min` package). Check logs for FFmpeg error messages

### Issue: Frame extraction slow

**Solution**: Reduce `targetFps` parameter (try 10-12 fps) and ensure hardware acceleration is enabled

### Issue: Poor rep counting accuracy

**Solution**:

- Adjust `upThreshold` and `downThreshold` in RepCounter
- Ensure proper camera angle (side view for push-ups, front view for pull-ups)
- Increase lighting for better keypoint detection

## TODO: Project-Specific Wiring

These items require manual integration into your existing app:

1. **Add to Navigation**: Wire `PoseRepScreen` into your app's navigation/routing
2. **Theme Integration**: Apply your app's theme colors to pose overlay
3. **Permission Handling**: Implement permission request flow (see camera_service.dart comments)
4. **Storage Management**: Configure output directory for exported videos
5. **Sharing**: Add share functionality for exported videos (use `share_plus`)
6. **Gallery Save**: Add option to save exported videos to device gallery

## Sample FFmpeg Commands

### Extract frames at 15 fps:

```bash
ffmpeg -i input.mp4 -vf fps=15 frames/frame_%04d.png
```

### Combine frames with audio:

```bash
ffmpeg -framerate 15 -i frames/frame_%04d.png -i input.mp4 \
  -map 0:v -map 1:a -c:v libx264 -crf 18 -c:a copy output.mp4
```

### Reduce output size (lower quality):

```bash
ffmpeg -framerate 15 -i frames/frame_%04d.png \
  -c:v libx264 -preset ultrafast -crf 28 -s 720x480 output.mp4
```

## Additional Resources

- [TensorFlow Lite Flutter](https://pub.dev/packages/tflite_flutter)
- [MoveNet Models](https://tfhub.dev/google/movenet)
- [FFmpeg Kit Flutter](https://pub.dev/packages/ffmpeg_kit_flutter_min)
- [Camera Plugin](https://pub.dev/packages/camera)
- [Video Player Plugin](https://pub.dev/packages/video_player)

## License

MIT License - See LICENSE file for details

---

**Note**: This implementation prioritizes accuracy and flexibility. For production use, consider additional optimizations based on target devices and performance requirements.
