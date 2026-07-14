import 'package:flutter/material.dart';

/// TECH_VOID effects — "VOID LUXE": shadows, champagne glows & motion grammar.
///
/// Luxury reads as RESTRAINT: glow alpha thấp hơn thời neon, đổ bóng ambient
/// sâu tách card khỏi nền void-black, và một ngữ pháp chuyển động thống nhất
/// (fade + rise 24px) cho mọi entrance.
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

  // ---- Champagne glows — accent elements emit warm light (khẽ thôi) ----
  static const List<BoxShadow> glowAccentSm = [
    BoxShadow(color: Color(0x33CDAA62), blurRadius: 12),
  ];
  static const List<BoxShadow> glowAccentMd = [
    BoxShadow(color: Color(0x40CDAA62), blurRadius: 20),
  ];
  static const List<BoxShadow> glowAccentLg = [
    BoxShadow(color: Color(0x4DCDAA62), blurRadius: 36),
  ];

  /// Single soft gold CTA glow (thay dual cyan+violet cũ).
  static const List<BoxShadow> glowCta = [
    BoxShadow(color: Color(0x38CDAA62), blurRadius: 20, offset: Offset(0, 6)),
  ];

  /// Cyan text glow — CHỈ dành cho wordmark TECH_VOID (DNA signal).
  static const List<Shadow> textGlowCyan = [
    Shadow(color: Color(0x6600F0FF), blurRadius: 16),
  ];

  /// Gold text glow — dùng cực kỳ tiết chế (hero price lúc đặc biệt).
  static const List<Shadow> textGlowGold = [
    Shadow(color: Color(0x40CDAA62), blurRadius: 14),
  ];

  /// Focus ring (gold, spread 3) — TvInput dùng khi focus.
  static const List<BoxShadow> focusRing = [
    BoxShadow(color: Color(0x40CDAA62), blurRadius: 0, spreadRadius: 3),
  ];

  // ---- Motion ----
  static const Curve easeStandard = Cubic(0.2, 0, 0, 1);
  static const Curve easeEmphasized = Cubic(0.2, 0, 0, 1.1);
  static const Duration durFast = Duration(milliseconds: 120);
  static const Duration durBase = Duration(milliseconds: 200);
  static const Duration durSlow = Duration(milliseconds: 320);

  // Motion grammar (VOID LUXE): mọi entrance dùng chung một "câu" —
  // fadeIn + moveY(begin: entranceRise) — để maximal motion vẫn đọc là 1 hệ.
  static const Duration durEnter = Duration(milliseconds: 400);
  static const Duration durMorph = Duration(milliseconds: 450);
  static const Duration staggerStep = Duration(milliseconds: 60);
  static const double entranceRise = 24;

  /// Tôn trọng cài đặt giảm chuyển động của hệ điều hành: nhân duration với
  /// hệ số này (0 nghĩa là tắt gần hết animation trang trí).
  static double motionScale(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? 0.0 : 1.0;

  /// Glass (BackdropFilter) bật/tắt toàn cục — emulator yếu thì đặt false,
  /// app bar/bottom nav tự fallback nền mờ đặc (ink900 @ 96%).
  static const bool kGlassEnabled = true;
  static const double glassSigma = 14;
  static const Color glassFill = Color(0xB8050505); // ink950 @ ~72%
  static const Color glassFallbackFill = Color(0xF50A0A0C); // ink900 @ 96%

  /// Subtle dotted texture overlay — hạ xuống mức "tiềm thức" cho luxury.
  static const Color dotColor = Color(0x06FFFFFF); // ~rgba(255,255,255,0.024)
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
