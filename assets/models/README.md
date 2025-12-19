# MoveNet Model

Download the **MoveNet Single Pose Lightning (Int8)** TFLite model and place it in this directory.

## Download Link

https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/int8/4

## File Name

`movenet_single_pose_lightning_int8.tflite`

## Model Details

- **Input**: 192x192x3 RGB image (uint8)
- **Output**: 1x1x17x3 tensor (y, x, confidence for 17 keypoints)
- **Keypoints**: 17 body joints (nose, eyes, ears, shoulders, elbows, wrists, hips, knees, ankles)
- **Size**: ~3 MB
- **Inference Speed**: ~30ms on modern mobile devices

## Download Instructions

1. Visit the TensorFlow Hub link above
2. Click "Download" button
3. Extract the .tflite file from the downloaded archive
4. Rename to `movenet_single_pose_lightning_int8.tflite` (if needed)
5. Place in this directory (`assets/models/`)

## Verification

After adding the model, verify it's included in your build:

```bash
flutter clean
flutter pub get
flutter run
```

The app will fail with a clear error message if the model is missing.
