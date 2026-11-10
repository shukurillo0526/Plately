// Plately — App Settings Provider
// ==================================
// Manages language, theme, and app mode preferences with persistence
// using SharedPreferences. Notifies the widget tree of changes.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two main modes of the app.
enum AppMode { order, cook }

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  static const String _keyLocale = 'app_locale';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyAppMode = 'app_mode';

  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;
  AppMode _appMode = AppMode.cook; // Default to Cook (existing experience)

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  AppMode get appMode => _appMode;

  /// Supported languages with display names and flags
  static const Map<String, Map<String, String>> supportedLanguages = {
    'en': {'name': 'English', 'flag': '🇺🇸'},
    'ko': {'name': '한국어', 'flag': '🇰🇷'},
    'uz': {'name': "O'zbekcha (Lotin)", 'flag': '🇺🇿'},
    'uz_Cyrl': {'name': 'Ўзбекча (Кирил)', 'flag': '🇺🇿'},
    'ru': {'name': 'Русский', 'flag': '🇷🇺'},
  };

  /// Helper to convert string like 'uz_Cyrl' to Locale
  static Locale parseLocale(String code) {
    if (code.contains('_')) {
      final parts = code.split('_');
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
    }
    return Locale(code);
  }

  /// Helper to convert Locale to string like 'uz_Cyrl'
  String _localeToString(Locale locale) {
    if (locale.scriptCode != null) {
      return '${locale.languageCode}_${locale.scriptCode}';
    }
    return locale.languageCode;
  }

  /// Initialize settings from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Language logic: saved pref > system locale > 'en'
    final savedLocaleCode = prefs.getString(_keyLocale);
    if (savedLocaleCode != null) {
      _locale = parseLocale(savedLocaleCode);
    } else {
      // First launch: detect system locale
      final sysLocale = ui.PlatformDispatcher.instance.locale;
      final langCode = sysLocale.languageCode;
      
      if (langCode == 'uz') {
        if (sysLocale.scriptCode == 'Cyrl') {
          _locale = parseLocale('uz_Cyrl');
        } else {
          _locale = parseLocale('uz');
        }
      } else if (supportedLanguages.containsKey(langCode)) {
        _locale = Locale(langCode);
      } else {
        _locale = const Locale('en');
      }
    }

    // Theme logic: saved pref > 'system'
    final themeName = prefs.getString(_keyThemeMode) ?? 'system';
    _themeMode = _themeModeFromString(themeName);

    final modeName = prefs.getString(_keyAppMode) ?? 'cook';
    _appMode = modeName == 'order' ? AppMode.order : AppMode.cook;

    notifyListeners();
  }

  /// Change app locale
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, _localeToString(newLocale));
    notifyListeners();
  }

  /// Change app theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeModeToString(mode));
    notifyListeners();
  }

  /// Switch between Order and Cook modes
  Future<void> setAppMode(AppMode mode) async {
    if (_appMode == mode) return;
    _appMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppMode, mode == AppMode.order ? 'order' : 'cook');
    notifyListeners();
  }

  String get currentLanguageName =>
      supportedLanguages[_localeToString(_locale)]?['name'] ?? 'English';

  String get currentLanguageFlag =>
      supportedLanguages[_localeToString(_locale)]?['flag'] ?? '🇺🇸';

  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
