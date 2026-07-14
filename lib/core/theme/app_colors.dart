import 'package:flutter/material.dart';

/// TECH_VOID color tokens — "VOID LUXE" (tech-luxury rebrand).
///
/// Obsidian-and-champagne storefront: void-black canvas, champagne-gold
/// primary accent, warm paper-white text. The old neon cyan survives ONLY as
/// a "signal" color: the TECH_VOID wordmark, AI badges and live indicators.
///
/// Reference the SEMANTIC aliases (e.g. [bgSurface], [textAccent], [accent])
/// from widgets — not the raw scale — so the palette stays swappable.
///
/// LUXURY RULES (chống lòe loẹt):
///  * Text gold nhỏ hơn 15px dùng [gold400]; >=15px w600+ được dùng [gold500].
///  * KHÔNG BAO GIỜ chữ gold trên nền gold — trên fill gold dùng [textOnAccent]
///    (espresso).
///  * Gold FILL tối đa 2 chỗ mỗi màn (CTA chính + active pill). Còn lại gold
///    chỉ xuất hiện dưới dạng text, icon hoặc hairline 1px.
///  * Border mặc định vẫn translucent-white; hairline gold = selected/active.
class AppColors {
  AppColors._();

  // ---- Brand: Champagne Gold (primary) ----
  static const Color gold300 = Color(0xFFEBD9AC); // highlight text, glints
  static const Color gold400 = Color(0xFFDEC58C); // hover, small text accent
  static const Color gold500 = Color(0xFFCDAA62); // CORE ACCENT — champagne
  static const Color gold600 = Color(0xFFAE8A47); // press
  static const Color gold700 = Color(0xFF8A6B35); // deep bronze, eyebrows

  static const Color goldSoft = Color(0x1FCDAA62); // 0.12 fill — active pills
  static const Color goldSoftLine = Color(0x4DCDAA62); // 0.30 line
  static const Color glassGold = Color(0x29CDAA62); // 0.16 glass fill

  // ---- Signal: Neon Cyan (legacy brand DNA — wordmark/AI/live ONLY) ----
  static const Color cyan300 = Color(0xFF7DF8FF);
  static const Color cyan400 = Color(0xFF38F1FF);
  static const Color cyan500 = Color(0xFF00F0FF);
  static const Color cyan600 = Color(0xFF00C2D6);
  static const Color cyan700 = Color(0xFF028E9C);

  /// Alias tự-document: cyan chỉ được phép ở wordmark, badge AI, live dot.
  static const Color signal = cyan500;

  // ---- Electric Violet (legacy — giữ định nghĩa cho an toàn compile) ----
  static const Color violet400 = Color(0xFF9D6BFF);
  static const Color violet500 = Color(0xFF7C3AED);
  static const Color violet600 = Color(0xFF6D28D9);
  static const Color violet700 = Color(0xFF581C9E);
  static const Color gradBlue = Color(0xFF1B8FEA);

  // ---- Neutral ink scale (void black, warm white) ----
  static const Color ink950 = Color(0xFF050505); // page base — void black
  static const Color ink900 = Color(0xFF0A0A0C); // recessed wells
  static const Color ink850 = Color(0xFF101013); // card surface
  static const Color ink800 = Color(0xFF17171B); // elevated / input
  static const Color ink700 = Color(0xFF1E1E23); // overlay / hover
  static const Color ink600 = Color(0xFF28282E);
  static const Color ink500 = Color(0xFF38383F);
  static const Color ink400 = Color(0xFF5D5D66);
  static const Color ink300 = Color(0xFF9A9AA1);
  static const Color ink200 = Color(0xFFC8C8CC);
  static const Color ink100 = Color(0xFFEAE9E6); // warm
  static const Color ink000 = Color(0xFFF6F4EF); // primary text — warm white

  // ---- Semantic palette ----
  static const Color success500 = Color(0xFF22E0A1); // fast-shipping, online
  static const Color warning500 = Color(0xFFFFB020);
  static const Color danger500 = Color(0xFFFF4D6D); // unread dots, errors
  static const Color star500 = Color(0xFFFFC107); // star ratings

  // ===== SEMANTIC ALIASES =====
  // Surfaces
  static const Color bgBase = ink950;
  static const Color bgSurface = ink850;
  static const Color bgElevated = ink800;
  static const Color bgOverlay = ink700;
  static const Color bgInverse = ink000;

  // Text
  static const Color textPrimary = ink000;
  static const Color textSecondary = ink300;
  static const Color textTertiary = ink400;
  static const Color textAccent = gold400; // sáng hơn gold500 cho chữ nhỏ
  static const Color textOnAccent = Color(0xFF161006); // espresso trên gold
  static const Color textOnViolet = Color(0xFFFFFFFF);

  // Borders (translucent white)
  static const Color borderSubtle = Color(0x12FFFFFF); // 0.07
  static const Color borderDefault = Color(0x1FFFFFFF); // 0.12
  static const Color borderStrong = Color(0x33FFFFFF); // 0.20
  static const Color borderAccent = gold500;
  static const Color edgeTop = Color(0x0DFFFFFF); // inset top hairline 0.05

  // Brand fills / tints
  static const Color accent = gold500;
  static const Color accentHover = gold400;
  static const Color accentPress = gold600;
  static const Color accentSoft = goldSoft; // active tab pill
  static const Color accentSoftLine = goldSoftLine;

  // Tints reused by components
  static const Color glassCyan = Color(0x2900F0FF); // AI badge fuel (signal)
  static const Color violetSoft = Color(0x24AE8A47); // remap bronze 0.14 —
  // notifications tile tự hợp màu mà không đổi call-site
  static const Color successSoft = Color(0x2922E0A1); // 0.16
  static const Color successLine = Color(0x4D22E0A1); // 0.30
  static const Color dangerSoft = Color(0x29FF4D6D); // 0.16
  static const Color dangerLine = Color(0x4DFF4D6D); // 0.30

  // ===== Signature gradients =====
  /// Champagne sheen CTA — brushed metal, không cầu vồng.
  /// linear-gradient(118deg, #E7CE96 0%, #CDAA62 52%, #A07A3B 100%)
  static const LinearGradient gradientCta = LinearGradient(
    begin: Alignment(-0.88, -0.47),
    end: Alignment(0.88, 0.47),
    colors: [Color(0xFFE7CE96), gold500, Color(0xFFA07A3B)],
    stops: [0.0, 0.52, 1.0],
  );

  // soft tinted variant (method-select card, etc.)
  static const LinearGradient gradientCtaSoft = LinearGradient(
    begin: Alignment(-0.88, -0.47),
    end: Alignment(0.88, 0.47),
    colors: [Color(0x24E7CE96), Color(0x24A07A3B)], // ~0.14 alpha
  );

  // linear-gradient(120deg, gold400 -> gold600)
  static const LinearGradient gradientBadge = LinearGradient(
    begin: Alignment(-0.87, -0.5),
    end: Alignment(0.87, 0.5),
    colors: [gold400, gold600],
  );

  /// Faint radial gold glow used behind hero imagery and the login lockup.
  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 0.9,
    colors: [Color(0x16CDAA62), Color(0x00CDAA62)],
  );
}
