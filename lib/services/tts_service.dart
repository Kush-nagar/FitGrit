import 'package:flutter_tts/flutter_tts.dart';

/// Service for text-to-speech feedback
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isEnabled = true;

  /// Initialize TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Slower for clarity
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // iOS specific settings
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
      );

      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  /// Speak text with TTS
  Future<void> speak(String text) async {
    if (!_isEnabled || !_isInitialized) return;

    try {
      // Stop any ongoing speech
      await _tts.stop();

      // Speak new text
      await _tts.speak(text);
    } catch (e) {
      print('TTS speak error: $e');
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
  }

  /// Enable or disable TTS
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  /// Check if TTS is enabled
  bool get isEnabled => _isEnabled;

  /// Check if TTS is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose TTS resources
  Future<void> dispose() async {
    await _tts.stop();
  }
}
