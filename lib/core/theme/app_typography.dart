import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// TECH_VOID typography — port of `tokens/typography.css`.
///
///  * Display = Chakra Petch (squared, technical) — wordmark, titles, UPPERCASE
///    section labels.
///  * Body/UI = Be Vietnam Pro (complete Vietnamese diacritics).
///  * Mono   = JetBrains Mono — spec values, SKUs, prices-as-data, OTP, qty.
///
/// Letter-spacing is expressed in logical pixels (CSS `em` × font-size).
///
/// NOTE: Fonts are pulled via `google_fonts` (cached after first load). If the
/// device is offline on first launch the framework falls back to a system font;
/// to ship fully offline, bundle the .ttf files and declare them in pubspec.
class AppText {
  AppText._();

  // ---- Families (use when you need the raw TextStyle, e.g. inside InputDecoration) ----
  static TextStyle display([Color color = AppColors.textPrimary]) =>
      GoogleFonts.chakraPetch(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: 0.3,
        color: color,
      );

  static TextStyle h1([Color color = AppColors.textPrimary]) =>
      GoogleFonts.chakraPetch(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.24,
        color: color,
      );

  static TextStyle h2([Color color = AppColors.textPrimary]) =>
      GoogleFonts.chakraPetch(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle h3([Color color = AppColors.textPrimary]) =>
      GoogleFonts.beVietnamPro(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color,
      );

  static TextStyle body([Color color = AppColors.textPrimary]) =>
      GoogleFonts.beVietnamPro(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyStrong([Color color = AppColors.textPrimary]) =>
      GoogleFonts.beVietnamPro(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: color,
      );

  static TextStyle sm([Color color = AppColors.textSecondary]) =>
      GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle xs([Color color = AppColors.textSecondary]) =>
      GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  /// UPPERCASE display label with wide tracking (apply `.toUpperCase()` to text).
  static TextStyle label([Color color = AppColors.textSecondary]) =>
      GoogleFonts.chakraPetch(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.32, // 0.12em
        height: 1.2,
        color: color,
      );

  /// Price emphasis — Be Vietnam Pro bold, accent cyan by default.
  static TextStyle price([Color color = AppColors.textAccent]) =>
      GoogleFonts.beVietnamPro(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color,
      );

  /// Monospace token — spec values, SKUs, qty, OTP digits.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  /// Uppercase CTA button label.
  static TextStyle button({double size = 15, Color color = AppColors.textOnAccent}) =>
      GoogleFonts.chakraPetch(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * 0.06,
        color: color,
      );

  /// The TECH_VOID wordmark style.
  static TextStyle wordmark({double size = 20, Color color = AppColors.accent}) =>
      GoogleFonts.chakraPetch(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * 0.04,
        height: 1,
        color: color,
        shadows: const [Shadow(color: Color(0x7300F0FF), blurRadius: 14)],
      );

  /// Base text theme for [ThemeData], so any stray default text uses the body
  /// family with the right color on the dark canvas.
  static TextTheme textTheme() => GoogleFonts.beVietnamProTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );
}
