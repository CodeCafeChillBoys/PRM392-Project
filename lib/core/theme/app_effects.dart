import 'package:flutter/material.dart';

/// TECH_VOID effects — shadows, neon glows & motion. Port of `tokens/effects.css`.
///
/// The brand reads "neon": cyan glows on accent elements, deep ambient shadows
/// separating dark cards from the dark base.
class AppEffects {
  AppEffects._();

  // ---- Ambient elevation shadows ----
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x8C000000), blurRadius: 40, offset: Offset(0, 16)),
  ];

  // ---- Neon glows — accent elements emit light ----
  static const List<BoxShadow> glowCyanSm = [
    BoxShadow(color: Color(0x4D00F0FF), blurRadius: 12),
  ];
  static const List<BoxShadow> glowCyanMd = [
    BoxShadow(color: Color(0x6600F0FF), blurRadius: 22),
  ];
  static const List<BoxShadow> glowCyanLg = [
    BoxShadow(color: Color(0x7300F0FF), blurRadius: 40),
  ];
  static const List<BoxShadow> glowViolet = [
    BoxShadow(color: Color(0x737C3AED), blurRadius: 24),
  ];

  /// Dual cyan+violet CTA glow.
  static const List<BoxShadow> glowCta = [
    BoxShadow(color: Color(0x5200C8F0), blurRadius: 22, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x476D28D9), blurRadius: 22, offset: Offset(0, 6)),
  ];

  /// Cyan text glow used on the wordmark, prices and grand totals.
  static const List<Shadow> textGlowCyan = [
    Shadow(color: Color(0x6600F0FF), blurRadius: 16),
  ];

  /// Focus ring (cyan, 0.35 alpha).
  static const List<BoxShadow> focusRing = [
    BoxShadow(color: Color(0x5900F0FF), blurRadius: 0, spreadRadius: 3),
  ];

  // ---- Motion ----
  static const Curve easeStandard = Cubic(0.2, 0, 0, 1);
  static const Curve easeEmphasized = Cubic(0.2, 0, 0, 1.1);
  static const Duration durFast = Duration(milliseconds: 120);
  static const Duration durBase = Duration(milliseconds: 200);
  static const Duration durSlow = Duration(milliseconds: 320);

  /// Subtle dotted texture overlay matching the Stitch canvas grain.
  /// Painted by a CustomPainter ([DotGridPainter]) since CSS radial dots have
  /// no 1:1 Flutter primitive.
  static const Color dotColor = Color(0x09FFFFFF); // ~rgba(255,255,255,0.035)
  static const double dotSpacing = 22;
}

/// Paints the faint dotted grid used on the app canvas (`--dot-grid`).
class DotGridPainter extends CustomPainter {
  const DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppEffects.dotColor;
    const spacing = AppEffects.dotSpacing;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) => false;
}
