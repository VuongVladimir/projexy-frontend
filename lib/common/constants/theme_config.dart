import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';

class ThemeConfig {
  static const _dialogRadius = 20.0;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Inter',
    primaryColor: GlobalVariables.primaryBlue,
    colorScheme: const ColorScheme.light(
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
    appBarTheme: const AppBarTheme(
      backgroundColor: GlobalVariables.white,
      foregroundColor: GlobalVariables.textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
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
        color: GlobalVariables.textPrimary,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.4,
        color: GlobalVariables.textPrimary,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.4,
        color: GlobalVariables.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        color: GlobalVariables.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: GlobalVariables.textSecondary,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.4,
        color: GlobalVariables.textSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: GlobalVariables.surfaceCard,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GlobalVariables.surfaceCard,
      hintStyle: const TextStyle(color: GlobalVariables.textSecondary),
      labelStyle: const TextStyle(color: GlobalVariables.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlobalVariables.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlobalVariables.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: GlobalVariables.primaryBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlobalVariables.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: GlobalVariables.errorRed,
          width: 1.5,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: GlobalVariables.surfaceDialog,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: GlobalVariables.surfaceDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_dialogRadius),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: GlobalVariables.surfaceDialog,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_dialogRadius)),
      ),
      titleTextStyle: TextStyle(
        color: GlobalVariables.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: GlobalVariables.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: GlobalVariables.surfaceDialog,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(color: GlobalVariables.textPrimary),
    ),
    dividerColor: GlobalVariables.divider,
    dividerTheme: const DividerThemeData(
      color: GlobalVariables.divider,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GlobalVariables.primaryBlue,
      foregroundColor: GlobalVariables.white,
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

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    primaryColor: GlobalVariables.darkPrimaryBlue,
    colorScheme: const ColorScheme.dark(
      primary: GlobalVariables.darkPrimaryBlue,
      secondary: GlobalVariables.darkSecondaryCoral,
      surface: GlobalVariables.darkSurfacePrimary,
      error: GlobalVariables.errorRedLight,
      onPrimary: GlobalVariables.darkTextOnPrimary,
      onSecondary: GlobalVariables.darkTextOnPrimary,
      onSurface: GlobalVariables.darkTextPrimary,
      onError: GlobalVariables.white,
      surfaceContainer: GlobalVariables.darkSurfaceCard,
      outline: GlobalVariables.darkBorderPrimary,
    ),
    scaffoldBackgroundColor: GlobalVariables.darkBackgroundPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: GlobalVariables.darkAppBarBackground,
      foregroundColor: GlobalVariables.darkTextPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: GlobalVariables.darkTextPrimary,
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
        color: GlobalVariables.darkTextPrimary,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.4,
        color: GlobalVariables.darkTextPrimary,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.4,
        color: GlobalVariables.darkTextSecondary,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.5,
        color: GlobalVariables.darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: GlobalVariables.darkTextSecondary,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.4,
        color: GlobalVariables.darkTextSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: GlobalVariables.darkSurfaceCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GlobalVariables.darkSurfaceCard,
      hintStyle: const TextStyle(color: GlobalVariables.darkTextSecondary),
      labelStyle: const TextStyle(color: GlobalVariables.darkTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlobalVariables.darkBorderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlobalVariables.darkBorderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: GlobalVariables.darkPrimaryBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GlobalVariables.errorRedLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: GlobalVariables.errorRedLight,
          width: 1.5,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: GlobalVariables.darkSurfaceDialog,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: GlobalVariables.darkSurfaceDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_dialogRadius),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: GlobalVariables.darkSurfaceDialog,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_dialogRadius)),
      ),
      titleTextStyle: TextStyle(
        color: GlobalVariables.darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: GlobalVariables.darkTextSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: GlobalVariables.darkSurfaceDialog,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(color: GlobalVariables.darkTextPrimary),
    ),
    dividerColor: GlobalVariables.darkDivider,
    dividerTheme: const DividerThemeData(
      color: GlobalVariables.darkDivider,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GlobalVariables.darkPrimaryBlue,
      foregroundColor: GlobalVariables.white,
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
