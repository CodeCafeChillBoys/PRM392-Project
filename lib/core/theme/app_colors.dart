import 'package:flutter/material.dart';

/// TECH_VOID color tokens — a direct port of `tokens/colors.css`.
///
/// Dark neon-cyberpunk tech storefront: near-black canvas, electric-cyan
/// primary, electric-violet secondary, signature cyan→blue→violet gradient.
///
/// Reference the SEMANTIC aliases (e.g. [bgSurface], [textAccent], [accent])
/// from widgets — not the raw scale — so the palette stays swappable.
class AppColors {
  AppColors._();

  // ---- Brand: Neon Cyan (primary) ----
  static const Color cyan300 = Color(0xFF7DF8FF);
  static const Color cyan400 = Color(0xFF38F1FF);
  static const Color cyan500 = Color(0xFF00F0FF); // core brand accent
  static const Color cyan600 = Color(0xFF00C2D6);
  static const Color cyan700 = Color(0xFF028E9C);

  // ---- Brand: Electric Violet (secondary) ----
  static const Color violet400 = Color(0xFF9D6BFF);
  static const Color violet500 = Color(0xFF7C3AED);
  static const Color violet600 = Color(0xFF6D28D9);
  static const Color violet700 = Color(0xFF581C9E);

  // ---- Gradient anchor (cyan -> blue -> violet) ----
  static const Color gradBlue = Color(0xFF1B8FEA);

  // ---- Neutral ink scale (dark UI) ----
  static const Color ink950 = Color(0xFF09090B); // page base
  static const Color ink900 = Color(0xFF0E0E12);
  static const Color ink850 = Color(0xFF131317); // card surface
  static const Color ink800 = Color(0xFF1A1B20); // elevated / input
  static const Color ink700 = Color(0xFF202127); // overlay / hover
  static const Color ink600 = Color(0xFF2A2C33);
  static const Color ink500 = Color(0xFF3A3D45);
  static const Color ink400 = Color(0xFF5E626B);
  static const Color ink300 = Color(0xFF9A9DA5);
  static const Color ink200 = Color(0xFFC7CACF);
  static const Color ink100 = Color(0xFFE9EAEC);
  static const Color ink000 = Color(0xFFF4F5F7);

  // ---- Semantic palette ----
  static const Color success500 = Color(0xFF22E0A1); // fast-shipping, online
  static const Color warning500 = Color(0xFFFFB020);
  static const Color danger500 = Color(0xFFFF4D6D); // unread dots, errors
  static const Color gold500 = Color(0xFFFFC107); // star ratings

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
  static const Color textAccent = cyan500;
  static const Color textOnAccent = Color(0xFF04121A); // dark text on cyan
  static const Color textOnViolet = Color(0xFFFFFFFF);

  // Borders (translucent white)
  static const Color borderSubtle = Color(0x12FFFFFF); // 0.07
  static const Color borderDefault = Color(0x1FFFFFFF); // 0.12
  static const Color borderStrong = Color(0x33FFFFFF); // 0.20
  static const Color borderAccent = cyan500;
  static const Color edgeTop = Color(0x0DFFFFFF); // inset top hairline 0.05

  // Brand fills / tints
  static const Color accent = cyan500;
  static const Color accentHover = cyan400;
  static const Color accentPress = cyan600;
  static const Color accentSoft = Color(0x1F00F0FF); // 0.12 — active tab pill
  static const Color accentSoftLine = Color(0x4D00F0FF); // 0.30

  // Tints reused by components
  static const Color glassCyan = Color(0x2900F0FF); // 0.16 — glass badge fill
  static const Color violetSoft = Color(0x297C3AED); // 0.16 — violet notif tile
  static const Color successSoft = Color(0x2922E0A1); // 0.16
  static const Color successLine = Color(0x4D22E0A1); // 0.30
  static const Color dangerSoft = Color(0x29FF4D6D); // 0.16
  static const Color dangerLine = Color(0x4DFF4D6D); // 0.30

  // ===== Signature gradients =====
  // linear-gradient(118deg, #00E6F3 0%, #1B8FEA 52%, #6D28D9 100%)
  static const LinearGradient gradientCta = LinearGradient(
    begin: Alignment(-0.88, -0.47),
    end: Alignment(0.88, 0.47),
    colors: [Color(0xFF00E6F3), gradBlue, violet600],
    stops: [0.0, 0.52, 1.0],
  );

  // soft tinted variant (method-select card, etc.)
  static const LinearGradient gradientCtaSoft = LinearGradient(
    begin: Alignment(-0.88, -0.47),
    end: Alignment(0.88, 0.47),
    colors: [Color(0x2900E6F3), Color(0x296D28D9)], // ~0.16 alpha
  );

  // linear-gradient(120deg, #7C3AED 0%, #1B8FEA 100%)
  static const LinearGradient gradientBadge = LinearGradient(
    begin: Alignment(-0.87, -0.5),
    end: Alignment(0.87, 0.5),
    colors: [violet500, gradBlue],
  );

  /// Faint radial cyan glow used behind hero imagery and the login lockup.
  static const RadialGradient heroGlow = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 0.9,
    colors: [Color(0x1F00F0FF), Color(0x0000F0FF)],
  );
}
