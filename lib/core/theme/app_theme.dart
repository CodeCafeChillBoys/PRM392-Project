import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Assembles the global dark [ThemeData] from the TECH_VOID tokens.
///
/// Most component styling lives in the dedicated widgets under
/// `presentation/widgets/`; this theme sets the canvas, base text, selection
/// colors and a cyan-seeded dark [ColorScheme] so default Material surfaces
/// also read as TECH_VOID.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.cyan500,
      onPrimary: AppColors.textOnAccent,
      secondary: AppColors.violet500,
      onSecondary: AppColors.textOnViolet,
      surface: AppColors.bgSurface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger500,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      canvasColor: AppColors.bgBase,
      splashColor: AppColors.accentSoft,
      highlightColor: AppColors.accentSoft,
      textTheme: AppText.textTheme(),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accentSoft,
        selectionHandleColor: AppColors.accent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
