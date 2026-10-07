import 'package:flutter/material.dart';

class AppColors {
  static const Color deepBlue = Color(0xFF0A2540);
  static const Color petrol = Color(0xFF0B4F6C);
  static const Color sky = Color(0xFF7CC6E8);
  static const Color mist = Color(0xFFEAF4F9);
  static const Color background = Color(0xFFF5F8FA);
  static const Color border = Color(0xFFD5E0E8);
  static const Color textMuted = Color(0xFF5B6B79);
  static const Color error = Color(0xFFB3261E);
  static const Color errorBg = Color(0xFFFDECEA);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.petrol,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.petrol,
      onPrimary: Colors.white,
      secondary: AppColors.sky,
    );

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.deepBlue,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.petrol, 2),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
