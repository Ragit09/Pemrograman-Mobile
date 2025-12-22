import 'package:flutter/material.dart';
import '../services/shared_preferences_service.dart';

class ThemeManager {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  static ThemeData get lightTheme => ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
        ),
      );

  static Future<void> init() async {
    isDarkMode.value = await SharedPreferencesService.getDarkMode();
  }

  static Future<void> toggleDarkMode() async {
    isDarkMode.value = !isDarkMode.value;
    await SharedPreferencesService.saveDarkMode(isDarkMode.value);
  }
}