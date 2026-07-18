import 'package:flutter/material.dart';

/// TECH_VOID color tokens — dual theme:
///  * DARK  = "VOID LUXE"  — obsidian & champagne (tech-luxury).
///  * LIGHT = "VOID PAPER" — K-Commerce Premium: giấy ấm, card trắng, CTA đen
///    kiểu Musinsa/29CM; gold chỉ còn ở giá/badge/active; sale đỏ ấm.
///
/// KIẾN TRÚC: mọi token THEO THEME là `static get` đọc từ palette đang active
/// (đổi theme qua [AppColors.configure]) — call site giữ nguyên `AppColors.x`.
/// Hằng thương hiệu (gold/cyan/violet raw, semantic 500s) là const vì không
/// đổi giữa 2 theme. LƯU Ý: token getter KHÔNG dùng được trong `const` widget.
///
/// LUXURY RULES (chống lòe loẹt):
///  * DARK: text gold nhỏ <15px dùng gold400; fill gold tối đa 2 chỗ/màn.
///  * LIGHT: chữ gold trên nền sáng phải dùng gold600/700 (gold500 fail AA);
///    fill đậm (CTA/badge) là ĐEN ấm, chữ trắng ấm — gold không làm fill lớn.
///  * KHÔNG BAO GIỜ chữ gold trên nền gold.
class AppColors {
  AppColors._();

  // ===== THEME SWITCH =====
  // MẶC ĐỊNH = LIGHT (VOID PAPER) — vibe shopping tươi sáng; dark là lựa chọn
  // trong Cá nhân. Phải khớp default của ThemeController._isLight.
  static bool _isLight = true;

  /// Theme hiện tại (ThemeController là nơi duy nhất nên gọi [configure]).
  static bool get isLight => _isLight;

  static void configure({required bool isLight}) => _isLight = isLight;

  // ---- Brand: Champagne Gold (const — chung 2 theme) ----
  static const Color gold300 = Color(0xFFEBD9AC); // highlight text, glints
  static const Color gold400 = Color(0xFFDEC58C); // hover, small text (dark)
  static const Color gold500 = Color(0xFFCDAA62); // CORE ACCENT — champagne
  static const Color gold600 = Color(0xFFAE8A47); // press / light-mode accent
  static const Color gold700 = Color(0xFF8A6B35); // deep bronze, eyebrows

  // ---- Signal: Neon Cyan (wordmark/AI/live ONLY) ----
  static const Color cyan300 = Color(0xFF7DF8FF);
  static const Color cyan400 = Color(0xFF38F1FF);
  static const Color cyan500 = Color(0xFF00F0FF);
  static const Color cyan600 = Color(0xFF00C2D6);
  static const Color cyan700 = Color(0xFF028E9C);

  /// Cyan chỉ được phép ở wordmark, badge AI, live dot.
  /// Light mode tự đậm hoá (cyan500 vô hình trên nền trắng).
  static Color get signal => _isLight ? cyan700 : cyan500;

  // ---- Electric Violet (legacy — giữ định nghĩa cho an toàn compile) ----
  static const Color violet400 = Color(0xFF9D6BFF);
  static const Color violet500 = Color(0xFF7C3AED);
  static const Color violet600 = Color(0xFF6D28D9);
  static const Color violet700 = Color(0xFF581C9E);
  static const Color gradBlue = Color(0xFF1B8FEA);

  // ---- Semantic 500s (const — chung 2 theme) ----
  static const Color success500 = Color(0xFF22E0A1);
  static const Color warning500 = Color(0xFFFFB020);
  static const Color danger500 = Color(0xFFFF4D6D);
  static const Color star500 = Color(0xFFFFC107);

  /// Đỏ sale K-Commerce (badge -%, flash sale) — ấm hơn danger, hợp nền giấy.
  static const Color sale500 = Color(0xFFE5484D);

  // ===== NEUTRAL "INK" SCALE (theo theme — light là bản ĐẢO warm-paper) =====
  // Ngữ nghĩa theo ĐỘ SÂU bề mặt/chữ, không theo sắc độ tuyệt đối:
  // 950=nền trang · 900=hõm chìm (ô ảnh) · 850=card · 800=input/elevated ·
  // 700=hover/overlay · 400..000=thang chữ (000 = chữ chính).
  static Color get ink950 =>
      _isLight ? const Color(0xFFF7F4EF) : const Color(0xFF050505);
  static Color get ink900 =>
      _isLight ? const Color(0xFFF0EBE2) : const Color(0xFF0A0A0C);
  static Color get ink850 =>
      _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF101013);
  static Color get ink800 =>
      _isLight ? const Color(0xFFFFFFFF) : const Color(0xFF17171B);
  static Color get ink700 =>
      _isLight ? const Color(0xFFF2EDE5) : const Color(0xFF1E1E23);
  static Color get ink600 =>
      _isLight ? const Color(0xFFE9E4DB) : const Color(0xFF28282E);
  static Color get ink500 =>
      _isLight ? const Color(0xFFD8D2C6) : const Color(0xFF38383F);
  static Color get ink400 =>
      _isLight ? const Color(0xFF8A8378) : const Color(0xFF5D5D66);
  static Color get ink300 =>
      _isLight ? const Color(0xFF6E675C) : const Color(0xFF9A9AA1);
  static Color get ink200 =>
      _isLight ? const Color(0xFF4B453C) : const Color(0xFFC8C8CC);
  static Color get ink100 =>
      _isLight ? const Color(0xFF2B261F) : const Color(0xFFEAE9E6);
  static Color get ink000 =>
      _isLight ? const Color(0xFF1A1712) : const Color(0xFFF6F4EF);

  // ===== SEMANTIC ALIASES (theo theme) =====
  // Surfaces
  static Color get bgBase => ink950;
  static Color get bgSurface => ink850;
  static Color get bgElevated => ink800;
  static Color get bgOverlay => ink700;
  static Color get bgInverse => ink000;

  // Text
  static Color get textPrimary => ink000;
  static Color get textSecondary => ink300;
  static Color get textTertiary => ink400;

  /// Chữ/icon accent: dark = gold sáng; light = bronze đậm (đủ tương phản).
  static Color get textAccent => _isLight ? gold700 : gold400;

  /// Chữ trên fill đậm: dark = espresso trên gold; light = trắng ấm trên ĐEN.
  static Color get textOnAccent =>
      _isLight ? const Color(0xFFFDF9F0) : const Color(0xFF161006);
  static Color get textOnViolet => const Color(0xFFFFFFFF);

  // Borders (dark: translucent-white · light: translucent-black ấm)
  static Color get borderSubtle =>
      _isLight ? const Color(0x14201A10) : const Color(0x12FFFFFF);
  static Color get borderDefault =>
      _isLight ? const Color(0x1F201A10) : const Color(0x1FFFFFFF);
  static Color get borderStrong =>
      _isLight ? const Color(0x33201A10) : const Color(0x33FFFFFF);
  static Color get borderAccent => _isLight ? gold600 : gold500;
  static Color get edgeTop =>
      _isLight ? const Color(0x0D201A10) : const Color(0x0DFFFFFF);

  // Brand fills / tints
  static Color get accent => _isLight ? gold600 : gold500;
  static Color get accentHover => _isLight ? gold500 : gold400;
  static Color get accentPress => _isLight ? gold700 : gold600;
  static Color get accentSoft =>
      _isLight ? const Color(0x24CDAA62) : const Color(0x1FCDAA62);
  static Color get accentSoftLine =>
      _isLight ? const Color(0x59AE8A47) : const Color(0x4DCDAA62);

  // Giữ tên cũ cho call-site (gold ramp tints)
  static Color get goldSoft => accentSoft;
  static Color get goldSoftLine => accentSoftLine;
  static Color get glassGold =>
      _isLight ? const Color(0x24CDAA62) : const Color(0x29CDAA62);

  // Tints reused by components
  static Color get glassCyan =>
      _isLight ? const Color(0x29028E9C) : const Color(0x2900F0FF);
  static Color get violetSoft =>
      _isLight ? const Color(0x1FAE8A47) : const Color(0x24AE8A47);
  /// Skeleton loading (skeletonizer): base/highlight phải tách nhau và tách
  /// khỏi nền card ở CẢ 2 theme (light: card trắng nên base là giấy sẫm).
  static Color get skeletonBase =>
      _isLight ? const Color(0xFFECE7DE) : const Color(0xFF17171B);
  static Color get skeletonHighlight =>
      _isLight ? const Color(0xFFF6F2EB) : const Color(0xFF1E1E23);

  static Color get successSoft => const Color(0x2922E0A1);
  static Color get successLine => const Color(0x4D22E0A1);
  static Color get dangerSoft => const Color(0x29FF4D6D);
  static Color get dangerLine => const Color(0x4DFF4D6D);

  // ===== Signature gradients (theo theme) =====
  /// CTA chính. Dark = champagne brushed-metal. Light = ĐEN ấm kiểu Musinsa
  /// (K-premium: nút đen chữ trắng; gold nhường chỗ cho giá/badge).
  static LinearGradient get gradientCta => _isLight
      ? const LinearGradient(
          begin: Alignment(-0.88, -0.47),
          end: Alignment(0.88, 0.47),
          colors: [Color(0xFF2E2921), Color(0xFF17140E)],
        )
      : const LinearGradient(
          begin: Alignment(-0.88, -0.47),
          end: Alignment(0.88, 0.47),
          colors: [Color(0xFFE7CE96), gold500, Color(0xFFA07A3B)],
          stops: [0.0, 0.52, 1.0],
        );

  // soft tinted variant (method-select card, etc.)
  static LinearGradient get gradientCtaSoft => _isLight
      ? const LinearGradient(
          begin: Alignment(-0.88, -0.47),
          end: Alignment(0.88, 0.47),
          colors: [Color(0x1A2E2921), Color(0x1A17140E)],
        )
      : const LinearGradient(
          begin: Alignment(-0.88, -0.47),
          end: Alignment(0.88, 0.47),
          colors: [Color(0x24E7CE96), Color(0x24A07A3B)],
        );

  /// Badge đậm. Dark = gold. Light = đen ấm (đồng bộ luật fill-đậm-là-đen).
  static LinearGradient get gradientBadge => _isLight
      ? const LinearGradient(
          begin: Alignment(-0.87, -0.5),
          end: Alignment(0.87, 0.5),
          colors: [Color(0xFF2E2921), Color(0xFF14110C)],
        )
      : const LinearGradient(
          begin: Alignment(-0.87, -0.5),
          end: Alignment(0.87, 0.5),
          colors: [gold400, gold600],
        );

  /// Faint radial gold glow behind hero imagery / login lockup.
  static RadialGradient get heroGlow => _isLight
      ? const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.9,
          colors: [Color(0x1ACDAA62), Color(0x00CDAA62)],
        )
      : const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.9,
          colors: [Color(0x16CDAA62), Color(0x00CDAA62)],
        );
}
