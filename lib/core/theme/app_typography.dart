import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// TECH_VOID typography — "VOID LUXE".
///
///  * Display = Archivo Expanded (variable font bundle, wdth 125) — lockup,
///    titles, eyebrows. Grotesque hiện đại, hỗ trợ tiếng Việt đầy đủ.
///  * Body/UI = Be Vietnam Pro (bundled statics — no FOUT, đủ dấu tiếng Việt).
///  * Mono   = JetBrains Mono — spec values, SKUs, OTP, qty ("tech data" voice).
///
/// Luxury = size contrast hơn weight contrast: ưu tiên w500/600 cỡ lớn,
/// w700 chỉ dành cho display/CTA/price.
class AppText {
  AppText._();

  // Archivo variable font: trục width 62–125. Expanded = 125.
  static const String _archivoFamily = 'Archivo';
  static const FontVariation _wdthExpanded = FontVariation('wdth', 125);
  static const FontVariation _wdthNormal = FontVariation('wdth', 100);

  static FontVariation _wght(FontWeight w) =>
      FontVariation('wght', w.value.toDouble());

  /// Archivo Expanded — giọng display chính của VOID LUXE.
  static TextStyle _archivoX({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
    List<Shadow>? shadows,
  }) =>
      TextStyle(
        fontFamily: _archivoFamily,
        fontVariations: [_wdthExpanded, _wght(weight)],
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
        shadows: shadows,
      );

  /// Archivo width thường — label/button (đanh gọn, không choán chỗ).
  static TextStyle _archivo({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
  }) =>
      TextStyle(
        fontFamily: _archivoFamily,
        fontVariations: [_wdthNormal, _wght(weight)],
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  // ---- Display scale ----

  /// Hero lockup (login, khoảnh khắc lớn). Nếu dấu tiếng Việt chồng bị cắt,
  /// nâng height 1.02 -> 1.1.
  static TextStyle displayXL([Color color = AppColors.textPrimary]) =>
      _archivoX(
        size: 40,
        weight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle display([Color color = AppColors.textPrimary]) => _archivoX(
        size: 34,
        weight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle h1([Color color = AppColors.textPrimary]) => _archivoX(
        size: 26,
        weight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle h2([Color color = AppColors.textPrimary]) => _archivoX(
        size: 20,
        weight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  static TextStyle h3([Color color = AppColors.textPrimary]) =>
      GoogleFonts.beVietnamPro(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color,
      );

  // ---- Body scale (Be Vietnam Pro — bundled, đủ dấu) ----

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

  /// UPPERCASE eyebrow label, tracking rộng kiểu luxury (0.16em).
  /// (apply `.toUpperCase()` to text).
  static TextStyle label([Color color = AppColors.textSecondary]) => _archivo(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 1.8, // 0.16em
        height: 1.2,
        color: color,
      );

  /// Price emphasis — Archivo Expanded, gold, chữ số tabular thẳng cột.
  static TextStyle price([Color color = AppColors.textAccent]) => _archivoX(
        size: 20,
        weight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Hero price (product detail, grand total).
  static TextStyle priceXL([Color color = AppColors.textAccent]) => _archivoX(
        size: 28,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

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
  static TextStyle button(
          {double size = 15, Color color = AppColors.textOnAccent}) =>
      _archivo(
        size: size,
        weight: FontWeight.w700,
        letterSpacing: size * 0.08,
        color: color,
      );

  /// The TECH_VOID wordmark — cyan signal + glow là DNA sống sót duy nhất
  /// của thời neon. KHÔNG dùng [AppColors.accent] ở đây (accent giờ là gold).
  static TextStyle wordmark(
          {double size = 20, Color color = AppColors.signal}) =>
      _archivoX(
        size: size,
        weight: FontWeight.w700,
        height: 1,
        letterSpacing: size * 0.04,
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
