import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for managing meditation audio playback
class MeditationAudioService {
  static final MeditationAudioService _instance =
      MeditationAudioService._internal();
  factory MeditationAudioService() => _instance;
  MeditationAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentMeditationId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Getters
  bool get isPlaying => _isPlaying;
  String? get currentMeditationId => _currentMeditationId;
  Duration get position => _position;
  Duration get duration => _duration;

  /// Initialize the audio player with listeners
  Future<void> initialize() async {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _duration = duration;
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _position = position;
    });

    // Auto-stop when completed
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentMeditationId = null;
      _position = Duration.zero;
    });
  }

  /// Play a meditation audio with ambient sounds
  /// Since we don't have actual meditation audio files, we'll generate calming tones
  Future<void> playMeditation(String meditationId, int durationMinutes) async {
    try {
      // Stop current playback if any
      await stop();

      _currentMeditationId = meditationId;

      // For demo purposes, we'll use a placeholder audio
      // In production, you would use: await _audioPlayer.play(AssetSource('audio/meditation_$meditationId.mp3'));
      
      // Since we don't have audio files, we'll simulate playback
      // You can add actual audio files to assets/audio/ directory
      
      // For now, play a low-frequency note generator (calming sound)
      // This is a workaround - ideally you'd have actual meditation audio files
      
      // Option 1: Use a URL to a meditation audio (temporary solution)
      // You can replace this with actual asset files later
      await _audioPlayer.play(UrlSource(
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ));

      _isPlaying = true;

      if (kDebugMode) {
        print('Playing meditation: $meditationId for $durationMinutes minutes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing meditation: $e');
      }
      _isPlaying = false;
      _currentMeditationId = null;
    }
  }

  /// Play from asset file
  Future<void> playFromAsset(String assetPath) async {
    try {
      await stop();
      await _audioPlayer.play(AssetSource(assetPath));
      _isPlaying = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error playing from asset: $e');
      }
      _isPlaying = false;
    }
  }

  /// Pause the current meditation
  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  /// Resume the current meditation
  Future<void> resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
  }

  /// Stop the current meditation
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentMeditationId = null;
    _position = Duration.zero;
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Dispose of the audio player
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  /// Stream for listening to player state changes
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;

  /// Stream for listening to position changes
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;

  /// Stream for listening to duration changes
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
}
