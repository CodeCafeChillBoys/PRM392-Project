import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import 'pressable.dart';

/// Bề mặt kính mờ TỔNG QUÁT (VOID CYAN) — dùng cho các bề mặt NỔI: floating
/// bottom nav, nút kính ở header, search capsule, sheet nổi trên bản đồ.
///
/// Cùng công thức [LiquidGlassPanel] (blur + tuỳ chọn tăng bão hoà cho màu "nở"
/// qua kính + hairline cạnh trên) nhưng bo GÓC 4 phía tuỳ biến, để tái dùng
/// ngoài bối cảnh bottom-sheet. LUẬT: chỉ đặt trên bề mặt NỔI có nội dung phía
/// sau — KHÔNG bọc item trong ListView/GridView dài (blur đắt).
///
/// [AppEffects.kGlassEnabled] = false → fallback nền mờ đặc (máy yếu).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.sigma = 20,
    this.fill,
    this.border,
    this.boxShadow,
    this.topHighlight = true,
    this.saturate = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double sigma;

  /// Màu nền kính (mặc định [AppEffects.glassFill] ~82% trắng ở light).
  final Color? fill;

  /// Viền hairline (mặc định trắng ~0.55 — gờ kính bắt sáng).
  final Border? border;

  /// Bóng nổi (mặc định [AppEffects.shadowFloat], đặt NGOÀI ClipRRect).
  final List<BoxShadow>? boxShadow;

  /// Vệt sáng mảnh cạnh trên (gờ kính). Tắt cho bề mặt nhỏ như nút tròn.
  final bool topHighlight;

  /// Ghép ma trận tăng bão hoà (màu backdrop "nở" qua kính) — như LiquidGlass.
  final bool saturate;

  /// Ma trận bão hoà Rec.709 (s>1 = đậm màu hơn).
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
    final shadow = boxShadow ?? AppEffects.shadowFloat;
    final resolvedBorder =
        border ?? Border.all(color: Colors.white.withValues(alpha: 0.55));

    if (!AppEffects.kGlassEnabled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppEffects.glassFallbackFill,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: shadow,
        ),
        child: child,
      );
    }

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: fill ?? AppEffects.glassFill,
        borderRadius: borderRadius,
        border: resolvedBorder,
      ),
      child: topHighlight
          ? Stack(
              children: [
                // Hairline cạnh trên — gờ kính bắt sáng.
                Positioned(
                  top: 1,
                  left: 16,
                  right: 16,
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(
                            alpha: AppColors.isLight ? 0.85 : 0.22,
                          ),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                child,
              ],
            )
          : child,
    );

    final blur = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    final filter = saturate
        ? ImageFilter.compose(
            outer: ColorFilter.matrix(_saturationMatrix(1.5)),
            inner: blur,
          )
        : blur;

    // Bóng NGOÀI ClipRRect (đặt trong bị clip cắt mất).
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(filter: filter, child: surface),
      ),
    );
  }
}

/// Nút tròn kính mờ cho header/map (kiểu Green-SM). Icon màu accent/primary.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = PressableScale(
      scale: 0.92,
      onTap: onPressed,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(999),
        sigma: 16,
        topHighlight: false,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(color: AppColors.textPrimary, size: 20),
              child: icon,
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}
