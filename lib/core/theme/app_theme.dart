import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Assembles the global [ThemeData] from the TECH_VOID tokens.
///
/// Hai theme: dark "VOID LUXE" và light "VOID PAPER". Widget tuỳ biến đọc
/// thẳng AppColors (đã tự đổi theo [AppColors.configure]); ThemeData ở đây lo
/// phần Material mặc định (canvas, selection, transitions, dialog...).
class AppTheme {
  AppTheme._();

  /// Theme khớp palette đang active của [AppColors].
  static ThemeData current() => AppColors.isLight ? light() : dark();

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        scheme: ColorScheme.dark(
          brightness: Brightness.dark,
          primary: AppColors.gold500,
          onPrimary: const Color(0xFF161006),
          secondary: AppColors.gold700,
          onSecondary: const Color(0xFFF6F4EF),
          surface: const Color(0xFF101013),
          onSurface: const Color(0xFFF6F4EF),
          error: AppColors.danger500,
          onError: Colors.white,
        ),
      );

  static ThemeData light() => _base(
        brightness: Brightness.light,
        scheme: ColorScheme.light(
          brightness: Brightness.light,
          primary: const Color(0xFF17140E), // CTA đen Musinsa
          onPrimary: const Color(0xFFFDF9F0),
          secondary: AppColors.gold600,
          onSecondary: const Color(0xFF1A1712),
          surface: Colors.white,
          onSurface: const Color(0xFF1A1712),
          error: AppColors.sale500,
          onError: Colors.white,
        ),
      );

  static ThemeData _base(
      {required Brightness brightness, required ColorScheme scheme}) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      canvasColor: AppColors.bgBase,
      splashColor: AppColors.accentSoft,
      highlightColor: AppColors.accentSoft,
      textTheme: AppText.textTheme(),
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 20),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accentSoft,
        selectionHandleColor: AppColors.accent,
      ),
      dividerTheme: DividerThemeData(
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
