// frontend/lib/common/constants/theme_config.dart
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';

class ThemeConfig {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Inter',
    primaryColor: GlobalVariables.primaryBlue,

    colorScheme: ColorScheme.light(
      primary: GlobalVariables.primaryBlue,
      secondary: GlobalVariables.secondaryCoral,
      surface: GlobalVariables.backgroundPrimary,
      error: GlobalVariables.errorRed,
      onPrimary: GlobalVariables.textOnPrimary,
      onSecondary: GlobalVariables.textOnPrimary,
      onSurface: GlobalVariables.textPrimary,
      onError: GlobalVariables.white,
      surfaceContainer: GlobalVariables.surfaceCard,
      outline: GlobalVariables.borderPrimary,
    ),

    scaffoldBackgroundColor: GlobalVariables.white,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: GlobalVariables.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: GlobalVariables.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        height: 1.2,
        color: GlobalVariables.textPrimary,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.3,
        color: GlobalVariables.textPrimary
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.4,
        color: GlobalVariables.textPrimary
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.4,
        color: GlobalVariables.textSecondary
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        color: GlobalVariables.textPrimary
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: GlobalVariables.textSecondary
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.4,
        color: GlobalVariables.textSecondary
      ),
    ),

    cardTheme: CardThemeData(
      color: GlobalVariables.surfaceCard,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GlobalVariables.primaryBlue,
        foregroundColor: GlobalVariables.white,
        disabledBackgroundColor: GlobalVariables.primaryBlue.withValues(
          alpha: 0.32,
        ),
        disabledForegroundColor: GlobalVariables.white.withValues(alpha: 0.75),
        overlayColor: GlobalVariables.primaryBlueDark.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    primaryColor: GlobalVariables.darkPrimaryBlue,

    colorScheme: ColorScheme.dark(
      primary: GlobalVariables.darkPrimaryBlue,
      secondary: GlobalVariables.darkSecondaryCoral,
      surface: GlobalVariables.darkBackgroundPrimary,
      error: GlobalVariables.errorRedLight,
      onPrimary: GlobalVariables.darkTextOnPrimary,
      onSecondary: GlobalVariables.darkTextOnPrimary,
      onSurface: GlobalVariables.darkTextPrimary,
      onError: GlobalVariables.white,
      surfaceContainer: GlobalVariables.darkSurfaceCard,
      outline: GlobalVariables.darkBorderPrimary,
    ),

    scaffoldBackgroundColor: GlobalVariables.darkBackgroundSecondary,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        height: 1.2,
        color: GlobalVariables.darkTextPrimary,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.3,
        color: GlobalVariables.darkTextPrimary
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.4,
        color: GlobalVariables.darkTextPrimary
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.4,
        color: GlobalVariables.darkTextSecondary
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        color: GlobalVariables.darkTextPrimary
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: GlobalVariables.darkTextSecondary
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.4,
        color: GlobalVariables.darkTextSecondary
      ),
    ),

    cardTheme: CardThemeData(
      color: GlobalVariables.darkSurfaceCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GlobalVariables.darkPrimaryBlue,
        foregroundColor: GlobalVariables.white,
        disabledBackgroundColor: GlobalVariables.darkPrimaryBlue.withValues(
          alpha: 0.28,
        ),
        disabledForegroundColor: GlobalVariables.white.withValues(alpha: 0.75),
        overlayColor: GlobalVariables.darkPrimaryBlueDark.withValues(
          alpha: 0.16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
