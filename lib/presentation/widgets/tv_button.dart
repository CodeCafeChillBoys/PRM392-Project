import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';
import 'pressable.dart';

enum TvButtonVariant { gradient, accent, secondary, ghost }

enum TvButtonSize { sm, md, lg }

/// Primary action button. The signature variant is the cyan→violet gradient
/// CTA. Supports a [loading] spinner (used by Login / Register / Checkout).
/// Mirrors `components/core/Button.jsx`.
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = TvButtonVariant.gradient,
    this.size = TvButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final TvButtonVariant variant;
  final TvButtonSize size;
  final bool fullWidth;
  final bool loading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  double get _height => switch (size) {
    TvButtonSize.sm => 36,
    TvButtonSize.md => 44,
    TvButtonSize.lg => 52,
  };

  double get _hPad => switch (size) {
    TvButtonSize.sm => 16,
    TvButtonSize.md => 20,
    TvButtonSize.lg => 24,
  };

  double get _fontSize => switch (size) {
    TvButtonSize.sm => 13,
    TvButtonSize.md => 15,
    TvButtonSize.lg => 16,
  };

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final (
      Color? bg,
      Gradient? grad,
      Color fg,
      BoxBorder? border,
      List<BoxShadow>? shadow,
    ) = switch (variant) {
      TvButtonVariant.gradient => (
        null,
        AppColors.gradientCta,
        AppColors.textOnAccent,
        null,
        AppEffects.glowCta,
      ),
      TvButtonVariant.accent => (
        AppColors.accent,
        null,
        AppColors.textOnAccent,
        null,
        AppEffects.glowAccentSm,
      ),
      TvButtonVariant.secondary => (
        Colors.transparent,
        null,
        AppColors.textAccent,
        Border.all(color: AppColors.accentSoftLine, width: 1.5),
        null,
      ),
      TvButtonVariant.ghost => (
        AppColors.bgElevated,
        null,
        AppColors.textPrimary,
        Border.all(color: AppColors.borderDefault),
        null,
      ),
    };

    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: fg, size: 18),
                  child: leadingIcon!,
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button(size: _fontSize, color: fg),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 10),
                IconTheme.merge(
                  data: IconThemeData(color: fg, size: 18),
                  child: trailingIcon!,
                ),
              ],
            ],
          );

    return PressableScale(
      onTap: disabled ? null : onPressed,
      enabled: !disabled,
      child: Opacity(
        opacity: loading ? 0.85 : (disabled ? 0.4 : 1.0),
        child: Container(
          height: _height,
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: _hPad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            gradient: grad,
            border: border,
            borderRadius: BorderRadius.circular(12),
            boxShadow: shadow,
          ),
          child: content,
        ),
      ),
    );
  }
}
