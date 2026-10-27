import 'package:flutter/material.dart';

import 'storage_service.dart';

class ThemeService {
  ThemeService._internal();

  static final ThemeService instance = ThemeService._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  void init() {
    themeMode.value = StorageService.getDarkModeEnabled()
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await StorageService.setDarkModeEnabled(enabled);
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      cardColor: Colors.white,
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      cardColor: const Color(0xFF111111),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF111111)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}
