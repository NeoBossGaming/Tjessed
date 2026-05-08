import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyBoardTheme = 'board_theme';
  static const String _keyPieceStyle = 'piece_style';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyAnimIntensity = 'anim_intensity';

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Board Theme
  String get boardTheme => _prefs.getString(_keyBoardTheme) ?? 'Classic Wood';
  Future<void> setBoardTheme(String theme) async {
    await _prefs.setString(_keyBoardTheme, theme);
    notifyListeners();
  }

  // Piece Style
  String get pieceStyle => _prefs.getString(_keyPieceStyle) ?? 'Solid';
  Future<void> setPieceStyle(String style) async {
    await _prefs.setString(_keyPieceStyle, style);
    notifyListeners();
  }

  // Sound
  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_keySoundEnabled, enabled);
    notifyListeners();
  }

  // Animation Intensity
  double get animIntensity => _prefs.getDouble(_keyAnimIntensity) ?? 1.0;
  Future<void> setAnimIntensity(double intensity) async {
    await _prefs.setDouble(_keyAnimIntensity, intensity);
    notifyListeners();
  }
}
