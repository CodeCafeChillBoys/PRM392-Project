/// TECH_VOID spacing, radii & layout tokens — port of `tokens/spacing.css`.
/// 4px base grid.
class AppSpacing {
  AppSpacing._();

  // Spacing scale
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  /// Screen gutter (VOID LUXE: 20px — khoảng thở rộng hơn cho luxury).
  static const double gutter = 20;

  // Control heights
  static const double controlSm = 36;
  static const double controlMd = 44; // min tap target
  static const double controlLg = 52; // primary CTA

  // Bottom tab bar height
  static const double bottomNavHeight = 64;
}

/// Corner radii tokens — exposed as [Radius]/[BorderRadius] for convenience.
class AppRadii {
  AppRadii._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12; // default card / input
  static const double lg = 20; // product cards, sheets (VOID LUXE: 16 -> 20)
  static const double xl = 24;
  static const double pill = 999;
}
