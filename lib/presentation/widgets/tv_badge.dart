import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum TvBadgeVariant { gradient, accent, glass, neutral, success, danger }

enum TvBadgeSize { sm, md }

/// Small status / promo pill. Mirrors `components/core/Badge.jsx`.
class TvBadge extends StatelessWidget {
  const TvBadge(
    this.label, {
    super.key,
    this.variant = TvBadgeVariant.gradient,
    this.size = TvBadgeSize.sm,
  });

  final String label;
  final TvBadgeVariant variant;
  final TvBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final pad = size == TvBadgeSize.sm
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
    final fontSize = size == TvBadgeSize.sm ? 10.0 : 12.0;

    final (Color? bg, Gradient? grad, Color text, Color? border) = switch (variant) {
      TvBadgeVariant.gradient => (null, AppColors.gradientBadge, Colors.white, null),
      TvBadgeVariant.accent => (AppColors.accent, null, AppColors.textOnAccent, null),
      TvBadgeVariant.glass => (AppColors.glassCyan, null, AppColors.cyan300, AppColors.accentSoftLine),
      TvBadgeVariant.neutral => (AppColors.bgOverlay, null, AppColors.textSecondary, AppColors.borderDefault),
      TvBadgeVariant.success => (AppColors.successSoft, null, AppColors.success500, AppColors.successLine),
      TvBadgeVariant.danger => (AppColors.dangerSoft, null, AppColors.danger500, AppColors.dangerLine),
    };

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        gradient: grad,
        borderRadius: BorderRadius.circular(6),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.label(text).copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: fontSize * 0.08,
        ),
      ),
    );
  }
}
