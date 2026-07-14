import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';
import 'pressable.dart';

enum TvIconButtonVariant { plain, accent, elevated }

enum TvIconButtonSize { sm, md, lg }

enum TvIconButtonShape { rounded, circle }

/// Square/round icon button for app bars and toolbars. The `accent` variant is
/// the cyan "add to cart" tile. Supports an optional count [badge].
/// Mirrors `components/core/IconButton.jsx`.
class TvIconButton extends StatelessWidget {
  const TvIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = TvIconButtonVariant.plain,
    this.size = TvIconButtonSize.md,
    this.shape = TvIconButtonShape.rounded,
    this.badge,
    this.tooltip,
    this.enabled = true,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final TvIconButtonVariant variant;
  final TvIconButtonSize size;
  final TvIconButtonShape shape;
  final int? badge;
  final String? tooltip;
  final bool enabled;

  double get _dim => switch (size) {
        TvIconButtonSize.sm => 32,
        TvIconButtonSize.md => 40,
        TvIconButtonSize.lg => 48,
      };

  @override
  Widget build(BuildContext context) {
    final (Color? bg, Color fg, BoxBorder? border, List<BoxShadow>? shadow) =
        switch (variant) {
      TvIconButtonVariant.plain => (null, AppColors.textPrimary, null, null),
      TvIconButtonVariant.accent => (
          AppColors.accent,
          AppColors.textOnAccent,
          null,
          AppEffects.glowAccentMd
        ),
      TvIconButtonVariant.elevated => (
          AppColors.bgElevated,
          AppColors.textPrimary,
          Border.all(color: AppColors.borderDefault),
          null
        ),
    };

    final radius = shape == TvIconButtonShape.circle ? 999.0 : 12.0;

    Widget button = PressableScale(
      scale: 0.92,
      onTap: enabled ? onPressed : null,
      enabled: enabled,
      child: Container(
        width: _dim,
        height: _dim,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: 20),
          child: icon,
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    if (badge == null) return button;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16),
            height: 16,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.danger500,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.bgBase, width: 2),
            ),
            child: Text(
              '$badge',
              style: AppText.mono(
                  size: 10, weight: FontWeight.w700, color: Colors.white),
            ),
          )
              // Badge NẢY mỗi khi con số đổi (thêm/bớt giỏ) — key theo giá trị
              // để Animate dựng lại và chạy lần nữa.
              .animate(key: ValueKey('badge-$badge'))
              .scaleXY(
                begin: 0.4,
                end: 1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.elasticOut,
              ),
        ),
      ],
    );
  }
}
