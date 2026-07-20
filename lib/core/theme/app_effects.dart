import 'package:flutter/material.dart';

import 'app_colors.dart';

/// TECH_VOID effects — dual theme.
///
/// DARK (VOID LUXE): glow champagne tiết chế + bóng ambient sâu trên void-black.
/// LIGHT (VOID PAPER): KHÔNG glow — sang trên nền giấy là nhờ bóng đổ mềm,
/// rộng, alpha thấp (K-premium). Các token glow tự đổi thành soft-shadow ở
/// light để call-site giữ nguyên.
class AppEffects {
  AppEffects._();

  static bool get _light => AppColors.isLight;

  // ---- Ambient elevation shadows ----
  static List<BoxShadow> get shadowSm => _light
      ? const [
          // 2 lớp: bóng rộng mềm nâng card "bồng" lên + bóng tiếp xúc mảnh.
          BoxShadow(
            color: Color(0x1A101819),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0D101819),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ];
  static List<BoxShadow> get shadowMd => _light
      ? const [
          BoxShadow(
            color: Color(0x1A101819),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ];
  static List<BoxShadow> get shadowLg => _light
      ? const [
          BoxShadow(
            color: Color(0x22101819),
            blurRadius: 40,
            offset: Offset(0, 14),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ];

  /// Bóng "nổi" mềm cho glass primitive (search/nav/sheet nổi) — alpha thấp,
  /// blur rộng, offset dọc vừa (theo brief Green-SM: α~.07 blur26 y10).
  static List<BoxShadow> get shadowFloat => _light
      ? const [
          BoxShadow(
            color: Color(0x12101819),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ];

  // ---- Accent emphasis ----
  // Dark: glow champagne. Light: glow trên giấy nhìn bẩn → soft shadow trung
  // tính, elevation nhẹ (call-site không cần biết khác biệt).
  static List<BoxShadow> get glowAccentSm => _light
      ? shadowSm
      : const [BoxShadow(color: Color(0x33CDAA62), blurRadius: 12)];
  static List<BoxShadow> get glowAccentMd => _light
      ? shadowMd
      : const [BoxShadow(color: Color(0x40CDAA62), blurRadius: 20)];
  static List<BoxShadow> get glowAccentLg => _light
      ? shadowLg
      : const [BoxShadow(color: Color(0x4DCDAA62), blurRadius: 36)];

  /// CTA glow (dark) / bóng nút đen (light).
  static List<BoxShadow> get glowCta => _light
      ? const [
          BoxShadow(
            color: Color(0x28101819),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x38CDAA62),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ];

  /// Cyan text glow — CHỈ wordmark TECH_VOID. Light: dịu gần tắt.
  static List<Shadow> get textGlowCyan => _light
      ? const [Shadow(color: Color(0x26028E9C), blurRadius: 10)]
      : const [Shadow(color: Color(0x6600F0FF), blurRadius: 16)];

  /// Gold text glow — cực tiết chế; light tắt hẳn.
  static List<Shadow> get textGlowGold => _light
      ? const []
      : const [Shadow(color: Color(0x40CDAA62), blurRadius: 14)];

  /// Focus ring (TvInput khi focus).
  static List<BoxShadow> get focusRing => _light
      ? const [
          BoxShadow(color: Color(0x3D2DCCD3), blurRadius: 0, spreadRadius: 3),
        ]
      : const [
          BoxShadow(color: Color(0x40CDAA62), blurRadius: 0, spreadRadius: 3),
        ];

  // ---- Motion (chung 2 theme) ----
  static const Curve easeStandard = Cubic(0.2, 0, 0, 1);
  static const Curve easeEmphasized = Cubic(0.2, 0, 0, 1.1);
  static const Duration durFast = Duration(milliseconds: 120);
  static const Duration durBase = Duration(milliseconds: 200);
  static const Duration durSlow = Duration(milliseconds: 320);

  // Motion grammar: mọi entrance = fadeIn + moveY(begin: entranceRise).
  static const Duration durEnter = Duration(milliseconds: 400);
  static const Duration durMorph = Duration(milliseconds: 450);
  static const Duration staggerStep = Duration(milliseconds: 60);
  static const double entranceRise = 24;

  /// Tôn trọng cài đặt giảm chuyển động của hệ điều hành.
  static double motionScale(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? 0.0 : 1.0;

  /// Glass (BackdropFilter) bật/tắt toàn cục.
  static const bool kGlassEnabled = true;
  static const double glassSigma = 14;
  static Color get glassFill => _light
      ? const Color(0xD1FFFFFF) // white @ ~82% (trong brief 0.74–0.88)
      : const Color(0xB8050505); // ink950 @ ~72%
  static Color get glassFallbackFill =>
      _light ? const Color(0xF5FFFFFF) : const Color(0xF50A0A0C);

  /// Subtle dotted texture overlay — mức "tiềm thức".
  static Color get dotColor =>
      _light ? const Color(0x0F0E2226) : const Color(0x06FFFFFF);
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
  bool shouldRepaint(covariant DotGridPainter oldDelegate) => false; // repaint theo theme do cây widget rebuild khi đổi theme
}
