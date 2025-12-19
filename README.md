# pres_app

Flutter application with on-device MoveNet pose estimation, exercise rep counting, and video annotation.

## Features

- **Real-time Camera Pose Estimation**: Live pose detection using MoveNet TFLite model
- **Exercise Rep Counting**: Automatic counting for push-ups, pull-ups, and sit-ups
- **Video Processing**: Pick video files and analyze them frame-by-frame
- **Annotated Video Export**: Generate MP4 videos with pose skeleton and rep count overlay
- **Smooth Pose Tracking**: Temporal smoothing for stable skeleton rendering
- **Multi-exercise Support**: Switch between different exercise types with dedicated detection logic

## Architecture

```
lib/
├── models/
│   ├── keypoint.dart          # Pose keypoint data model (17 MoveNet keypoints)
│   ├── video_frame.dart       # Video frame container with timestamp
│   └── rep_counter.dart       # Exercise-specific rep counting logic
├── services/
│   ├── camera_service.dart    # Real-time camera stream management
│   ├── video_service.dart     # Video picking, frame extraction, export
│   └── pose_estimator.dart    # MoveNet TFLite inference engine
├── utils/
│   └── pose_utils.dart        # Drawing, smoothing, frame annotation
├── widgets/
│   └── pose_painter.dart      # Custom painter for pose skeleton overlay
└── presentation/
    └── screens/
        └── pose_rep_screen.dart # Main UI (camera/video modes)
```

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Download MoveNet Model

Download the **MoveNet Single Pose Lightning (Int8)** TFLite model:

- Source: [TensorFlow Hub - MoveNet](https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/int8/4)
- File: `movenet_single_pose_lightning_int8.tflite`

Place the model in your project:

```
assets/
└── models/
    └── movenet_single_pose_lightning_int8.tflite
```

Update `pubspec.yaml` to include the model:

```yaml
flutter:
  assets:
    - assets/
    - assets/images/
    - assets/models/ # Add this line
```

### 3. Platform-Specific Configuration

#### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

Update `android/app/build.gradle` to support TFLite:

```gradle
android {
    aaptOptions {
        noCompress 'tflite'
    }
}
```

#### iOS

Add permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for pose estimation</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for video recording</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to pick videos</string>
```

### 4. Run the App

```bash
flutter run
```

## Usage

### Real-Time Camera Mode

1. Tap **Camera** button to start live pose detection
2. Select exercise type from dropdown (Push-up, Pull-up, Sit-up)
3. Perform exercise - rep count updates automatically
4. Tap **Stop** to end session

### Video Processing Mode

1. Tap **Pick Video** to select a video file from gallery
2. Tap **Analyze** to process video frames (extracts at 15 fps)
3. Wait for analysis to complete (progress shown)
4. Tap **Export** to generate annotated MP4 with pose skeleton and rep count
5. Exported video saved to temporary directory (path shown in success message)

### Exercise Detection Logic

- **Push-ups**: Detects elbow angle (straight = up, bent = down)
- **Pull-ups**: Measures shoulder-to-wrist vertical distance (close = up, far = down)
- **Sit-ups**: Calculates hip angle (90° = up, 180° = down)

Configurable thresholds in `RepCounter`:

- `upThreshold`: Default 0.7 (normalized signal)
- `downThreshold`: Default 0.3
- `transitionDebounce`: Default 300ms (prevents jitter)

## Video Export

### FFmpeg Commands

The app uses `ffmpeg_kit_flutter_min` for video export. Key commands:

#### Export with Audio (recommended)

```bash
ffmpeg -framerate 15 -i "frames_dir/frame_%04d.png" \
  -i "source_video.mp4" \
  -map 0:v -map 1:a? \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p \
  -c:a copy "output.mp4" -y
```

#### Export without Audio

```bash
ffmpeg -framerate 15 -i "frames_dir/frame_%04d.png" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p \
  "output.mp4" -y
```

#### Parameters

- `-framerate 15`: Output video FPS (matches analysis fps)
- `-crf 18`: Quality (0-51, lower = better, 18 = high quality)
- `-preset fast`: Encoding speed (ultrafast, fast, medium, slow)
- `-pix_fmt yuv420p`: Pixel format for compatibility

### Performance Considerations

For long videos:

- **Downsample FPS**: Process at 10-15 fps instead of 30 fps
- **Batch Processing**: Process frames in chunks to manage memory
- **Resolution**: Consider downscaling input resolution (e.g., 720p)
- **Isolate Processing**: Run frame extraction/inference in isolate (see TODO comments)

Example: 60-second video at 15 fps = 900 frames

- ~30-45 seconds for analysis
- ~20-30 seconds for export

## API Reference

### PoseEstimator

```dart
final estimator = PoseEstimator();
await estimator.initialize();

// Camera frames
List<Keypoint> keypoints = await estimator.estimatePose(cameraImage);

// Video frames
List<Keypoint> keypoints = await estimator.estimateFromBytes(
  rgbBytes, width, height,
  rotation: 0, mirrored: false,
);
```

### RepCounter

```dart
final counter = RepCounter(
  exerciseType: ExerciseType.pushUp,
  upThreshold: 0.7,
  downThreshold: 0.3,
);

bool newRep = counter.update(keypoints, timestampMillis);
int reps = counter.repCount;

// For video annotation
int repsAt = counter.getRepCountAt(timestampMillis);
RepState state = counter.getStateAt(timestampMillis);
```

### VideoService

```dart
final service = VideoService();

// Pick video
String? path = await service.pickVideo();

// Extract frames
List<String> frames = await service.extractFramesWithFFmpeg(
  videoPath, targetFps: 15,
);

// Export annotated video
String? output = await service.exportAnnotatedVideo(
  sourceVideoPath: videoPath,
  framesDir: 'path/to/annotated_frames',
  outputPath: 'output.mp4',
  fps: 15,
  includeAudio: true,
);
```

## Testing

Run unit tests:

```bash
flutter test
```

Tests cover:

- Rep counting logic for all exercise types
- Pose keypoint smoothing
- Bounding box calculation
- Timeline tracking
- Debouncing behavior

## Known Limitations & TODOs

1. **Frame Extraction**: Current implementation uses ffmpeg for reliability. Direct video_player frame extraction has platform limitations.

2. **Isolate Processing**: Heavy video processing should run in isolates to avoid UI blocking (commented examples provided).

3. **Model Integration**: MoveNet model must be manually downloaded and added to assets.

4. **Permission Handling**: Permission requests need UI integration (helper code provided in comments).

5. **Video Playback Sync**: Video overlay shows analyzed frames but doesn't sync perfectly during playback scrubbing.

6. **Export Location**: Videos export to temp directory - add gallery save or share functionality.

7. **Progress Cancellation**: Long exports cannot be cancelled mid-process.

## Troubleshooting

### "Model not found" Error

Ensure model file exists at `assets/models/movenet_single_pose_lightning_int8.tflite` and is listed in pubspec.yaml assets.

### Camera Permission Denied

Check platform-specific permission strings in AndroidManifest.xml / Info.plist and request at runtime.

### FFmpeg Export Fails

Check logs for detailed error. Common issues:

- Missing source video file
- Invalid frame directory path
- Insufficient storage space
- Frame numbering mismatch (must be frame_0001.png, frame_0002.png, etc.)

### Low FPS / Laggy

- Enable hardware acceleration: `useNnApiForAndroid = true` in PoseEstimator
- Reduce camera resolution: `ResolutionPreset.medium` or `.low`
- Increase frame skip: process every 2nd or 3rd frame
- Run inference in isolate

### Inaccurate Rep Counts

Adjust thresholds in RepCounter:

- Increase `upThreshold` / decrease `downThreshold` for stricter counting
- Increase `transitionDebounce` to reduce jitter
- Ensure proper camera angle (side view for push-ups/sit-ups, front view for pull-ups)

## License

MIT License - see LICENSE file for details

## Contributing

Contributions welcome! Areas for improvement:

- Additional exercise types (squats, lunges, etc.)
- Multi-person pose detection
- Real-time performance metrics (speed, ROM)
- Cloud model updates
- Social sharing features
