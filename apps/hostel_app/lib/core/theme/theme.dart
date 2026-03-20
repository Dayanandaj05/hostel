import 'package:flutter/material.dart';

abstract class AppTheme {
  static const _brandNavy = Color(0xFF0D2137);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandNavy,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(8),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandNavy,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: _brandNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(8),
      ),
    );
  }
}
