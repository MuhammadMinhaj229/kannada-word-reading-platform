import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color ink = Color(0xFF183247);
  static const Color deepInk = Color(0xFF10283B);
  static const Color teal = Color(0xFF147D78);
  static const Color tealDark = Color(0xFF0F625F);
  static const Color mint = Color(0xFFE2F2EC);
  static const Color canvas = Color(0xFFF5F7F4);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF637783);
  static const Color line = Color(0xFFDCE5E1);
  static const Color gold = Color(0xFFF1C66D);
  static const Color coral = Color(0xFFE98269);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      secondary: gold,
      surface: paper,
      error: const Color(0xFFB54742),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSansKannada',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: deepInk,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: deepInk,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: deepInk,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: ink,
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: muted,
          fontSize: 13,
          height: 1.45,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBFCFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(color: muted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: teal, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB6C9C5),
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tealDark,
          side: const BorderSide(color: line),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
    );
  }
}
