import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';

/// Liquid glass THẬT (kiểu Apple) — không phải "trắng 20% + blur 10":
///  1. Backdrop = blur GHÉP với ma trận TĂNG BÃO HOÀ (x1.6) — màu bản đồ
///     "nở" xuyên qua kính thay vì xám chết. Đây là điểm khác biệt cốt lõi.
///  2. Fill gradient dọc: đỉnh loãng hơn đáy — kính "mỏng" nơi bắt sáng.
///  3. Hairline highlight cạnh trên (fade 2 đầu) — gờ kính bắt sáng.
///  4. Vệt specular chéo TĨNH alpha thấp — ánh phản chiếu.
///
/// Light theme = frosted trắng; dark = smoked glass (token tự đổi theo theme).
/// [AppEffects.kGlassEnabled] = false → fallback nền mờ đặc (máy yếu).
class LiquidGlassPanel extends StatelessWidget {
  const LiquidGlassPanel({super.key, required this.child, this.radius = 26});

  final Widget child;

  /// Bo góc TRÊN của panel (dưới chạm mép màn hình).
  final double radius;

  static const double _sigma = 20;

  /// Lối thoát: nếu compose(ColorFilter, blur) render sai trên thiết bị nào
  /// đó → đặt false: rơi về blur thuần (vẫn đẹp, mất phần "nở màu").
  static const bool _kSaturate = true;

  /// Ma trận bão hoà (s>1 = đậm màu hơn) — công thức luminance chuẩn Rec.709.
  static List<double> _saturationMatrix(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final sr = (1 - s) * lr, sg = (1 - s) * lg, sb = (1 - s) * lb;
    return [
      sr + s, sg, sb, 0, 0, //
      sr, sg + s, sb, 0, 0, //
      sr, sg, sb + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final light = AppColors.isLight;
    final br = BorderRadius.vertical(top: Radius.circular(radius));

    if (!AppEffects.kGlassEnabled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppEffects.glassFallbackFill,
          borderRadius: br,
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppEffects.shadowLg,
        ),
        child: child,
      );
    }

    // Fill: gradient dọc — đỉnh loãng hơn.
    final topFill =
        light ? const Color(0x99FFFFFF) : const Color(0x8C050505);
    final bottomFill = AppEffects.glassFill;

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topFill, bottomFill],
        ),
        borderRadius: br,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Stack(
        children: [
          // Hairline highlight cạnh trên — gờ kính bắt sáng.
          Positioned(
            top: 1,
            left: radius * 0.6,
            right: radius * 0.6,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: light ? 0.85 : 0.22),
                  Colors.white.withValues(alpha: 0),
                ]),
              ),
            ),
          ),
          // Vệt specular chéo tĩnh, alpha cực thấp.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: br,
                  gradient: LinearGradient(
                    begin: const Alignment(-1, -1.4),
                    end: const Alignment(0.4, 0.3),
                    colors: [
                      Colors.white.withValues(alpha: light ? 0.30 : 0.07),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    final blur = ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma);
    final filter = _kSaturate
        ? ImageFilter.compose(
            outer: ColorFilter.matrix(_saturationMatrix(1.6)),
            inner: blur,
          )
        : blur;

    // Bóng đổ đặt NGOÀI ClipRRect — đặt trong sẽ bị clip cắt mất.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: br, boxShadow: AppEffects.shadowLg),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(filter: filter, child: surface),
      ),
    );
  }
}
