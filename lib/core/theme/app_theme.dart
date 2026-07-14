import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Assembles the global dark [ThemeData] from the TECH_VOID tokens (VOID LUXE).
///
/// Most component styling lives in the dedicated widgets under
/// `presentation/widgets/`; this theme sets the canvas, base text, selection
/// colors and a gold-seeded dark [ColorScheme] so default Material surfaces
/// also read as VOID LUXE. Page transitions dùng FadeThrough (Android) cho
/// cảm giác morph mềm toàn app.
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.gold500,
      onPrimary: AppColors.textOnAccent,
      secondary: AppColors.gold700,
      onSecondary: AppColors.textPrimary,
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
      // Chuyển trang mềm toàn app: fade-through thay slide Material mặc định.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
