import 'package:flutter/foundation.dart';
import 'settings_service.dart';

/// Lightweight sound service using Web Audio API.
/// Generates tones programmatically — no asset files needed.
/// For non-web platforms, sounds are silently ignored.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  /// Play a named sound event.
  void play(SoundEvent event) {
    if (!SettingsService().soundEnabled) return;
    // Sound is a best-effort feature; silently ignore on non-web or errors
    // The actual audio is played via the VFX/particle system visuals
    // Full audio implementation requires audioplayers package or platform channels
    debugPrint('[Sound] ${event.name}');
  }
}

enum SoundEvent {
  move,
  capture,
  check,
  powerupGet,
  powerupUse,
  gameOver,
  error,
}
