import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  static const _prefsKey = 'propkart_dark_mode';

  ThemeManager._internal() {
    _isDarkMode = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    _loadPersisted();
  }

  bool _isDarkMode = false;
  bool _loaded = false;
  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _loaded;

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefsKey)) {
        _isDarkMode = prefs.getBool(_prefsKey) ?? _isDarkMode;
        _loaded = true;
        notifyListeners();
      } else {
        _loaded = true;
      }
    } catch (_) {
      _loaded = true;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDarkMode);
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDarkMode);
    } catch (_) {}
  }
}
