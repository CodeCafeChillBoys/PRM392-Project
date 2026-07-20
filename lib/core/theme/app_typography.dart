import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// TECH_VOID typography — dual theme (VOID LUXE dark / VOID PAPER light).
///
///  * Display = Archivo Expanded (variable font bundle, wdth 125) — lockup,
///    titles, eyebrows. Grotesque hiện đại, hỗ trợ tiếng Việt đầy đủ.
///  * Body/UI = Be Vietnam Pro (bundled statics — no FOUT, đủ dấu tiếng Việt).
///  * Mono   = JetBrains Mono — spec values, SKUs, OTP, qty ("tech data" voice).
///
/// Màu mặc định của mỗi style đọc từ AppColors TẠI THỜI ĐIỂM GỌI (theme-aware)
/// nên tham số màu là nullable — truyền màu = override, bỏ trống = theo theme.
class AppText {
  AppText._();

  // Archivo variable font: trục width 62–125. Expanded = 125.
  static const String _archivoFamily = 'Archivo';
  static const FontVariation _wdthExpanded = FontVariation('wdth', 125);
  static const FontVariation _wdthNormal = FontVariation('wdth', 100);

  static FontVariation _wght(FontWeight w) =>
      FontVariation('wght', w.value.toDouble());

  /// Archivo Expanded — giọng display chính.
  static TextStyle _archivoX({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
    Color? color,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: _archivoFamily,
    fontVariations: [_wdthExpanded, _wght(weight)],
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? AppColors.textPrimary,
    shadows: shadows,
  );

  /// Archivo width thường — label/button (đanh gọn, không choán chỗ).
  static TextStyle _archivo({
    required double size,
    required FontWeight weight,
    double? height,
    double letterSpacing = 0,
    Color? color,
  }) => TextStyle(
    fontFamily: _archivoFamily,
    fontVariations: [_wdthNormal, _wght(weight)],
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color ?? AppColors.textPrimary,
  );

  // ---- Display scale ----

  /// Hero lockup (login, khoảnh khắc lớn).
  static TextStyle displayXL([Color? color]) => _archivoX(
    size: 40,
    weight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: color,
  );

  static TextStyle display([Color? color]) => _archivoX(
    size: 34,
    weight: FontWeight.w700,
    height: 1.08,
    letterSpacing: -0.4,
    color: color,
  );

  static TextStyle h1([Color? color]) => _archivoX(
    size: 26,
    weight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.2,
    color: color,
  );

  static TextStyle h2([Color? color]) =>
      _archivoX(size: 20, weight: FontWeight.w600, height: 1.2, color: color);

  static TextStyle h3([Color? color]) => GoogleFonts.beVietnamPro(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: color ?? AppColors.textPrimary,
  );

  // ---- Body scale (Be Vietnam Pro — bundled, đủ dấu) ----

  static TextStyle body([Color? color]) => GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle bodyStrong([Color? color]) => GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: color ?? AppColors.textPrimary,
  );

  static TextStyle sm([Color? color]) => GoogleFonts.beVietnamPro(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color ?? AppColors.textSecondary,
  );

  static TextStyle xs([Color? color]) => GoogleFonts.beVietnamPro(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color ?? AppColors.textSecondary,
  );

  /// UPPERCASE eyebrow label, tracking rộng kiểu luxury (0.16em).
  static TextStyle label([Color? color]) => _archivo(
    size: 11,
    weight: FontWeight.w600,
    letterSpacing: 1.8, // 0.16em
    height: 1.2,
    color: color ?? AppColors.textSecondary,
  );

  /// Price emphasis — Archivo Expanded, accent theme-aware, tabular figures.
  static TextStyle price([Color? color]) => _archivoX(
    size: 20,
    weight: FontWeight.w600,
    letterSpacing: 0,
    color: color ?? AppColors.textAccent,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Hero price (product detail, grand total).
  static TextStyle priceXL([Color? color]) => _archivoX(
    size: 28,
    weight: FontWeight.w600,
    letterSpacing: -0.2,
    color: color ?? AppColors.textAccent,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Monospace token — spec values, SKUs, qty, OTP digits.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textPrimary,
  );

  /// Uppercase CTA button label (mặc định = chữ trên fill đậm theo theme).
  static TextStyle button({double size = 15, Color? color}) => _archivo(
    size: size,
    weight: FontWeight.w700,
    letterSpacing: size * 0.08,
    color: color ?? AppColors.textOnAccent,
  );

  /// The TECH_VOID wordmark — cyan signal + glow là DNA sống sót duy nhất
  /// của thời neon. Light mode: cyan đậm hơn, glow dịu gần tắt.
  static TextStyle wordmark({double size = 20, Color? color}) => _archivoX(
    size: size,
    weight: FontWeight.w700,
    height: 1,
    letterSpacing: size * 0.04,
    color: color ?? AppColors.signal,
    shadows: AppColors.isLight
        ? const [Shadow(color: Color(0x26028E9C), blurRadius: 10)]
        : const [Shadow(color: Color(0x7300F0FF), blurRadius: 14)],
  );

  /// Base text theme for [ThemeData] — theo brightness của theme đang active.
  static TextTheme textTheme() =>
      GoogleFonts.beVietnamProTextTheme(
        AppColors.isLight
            ? ThemeData.light().textTheme
            : ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      );
}
