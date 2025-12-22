import 'package:flutter/material.dart';
import '../services/shared_prefs_service.dart';
import '../utils/constants.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPrefsService _prefsService = SharedPrefsService();
  
  ThemeMode get themeMode => _themeMode;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final themeString = await _prefsService.getThemeMode();
    switch (themeString) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeString;
    switch (mode) {
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.light:
        modeString = 'light';
        break;
      default:
        modeString = 'system';
    }
    await _prefsService.setThemeMode(modeString);
    notifyListeners();
  }
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  ThemeData get currentTheme {
    return isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }
  
  Color get cardColor {
    return isDarkMode ? AppColors.darkCard : AppColors.cardBackground;
  }
  
  Color get backgroundColor {
    return isDarkMode ? AppColors.darkBackground : AppColors.background;
  }
  
  Color get textColor {
    return isDarkMode ? AppColors.darkText : AppColors.textPrimary;
  }
  
  Color get secondaryTextColor {
    return isDarkMode ? Colors.grey[400]! : AppColors.textSecondary;
  }
}