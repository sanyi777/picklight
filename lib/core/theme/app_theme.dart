import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A90D9);
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE74C3C);
}

class AppTextTheme {
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: CupertinoColors.secondaryLabel,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: CupertinoColors.label,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: CupertinoColors.secondaryLabel,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: CupertinoColors.label,
  );

  static const TextStyle highlight = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

ThemeData getTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    brightness: brightness,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: isDark
        ? CupertinoColors.systemBackground.darkColor
        : AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: isDark
          ? CupertinoColors.systemBackground.darkColor
          : AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      bodySmall: AppTextTheme.caption,
      bodyMedium: AppTextTheme.body,
      bodyLarge: AppTextTheme.subtitle,
      titleMedium: AppTextTheme.title,
      headlineLarge: AppTextTheme.largeTitle,
      headlineMedium: AppTextTheme.highlight,
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: isDark
          ? CupertinoColors.systemBackground.darkColor
          : AppColors.background,
      textTheme: CupertinoTextThemeData(
        textStyle: AppTextTheme.body,
        primaryColor: AppColors.primary,
      ),
    ),
  );
}
