import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';

/// Generic dark-surface container with a hairline border and ambient shadow;
/// optional neon cyan edge + glow. Mirrors `components/data/Card.jsx`.
class TvCard extends StatelessWidget {
  const TvCard({
    super.key,
    required this.child,
    this.padding = 16,
    this.accent = false,
    this.glow = false,
    this.margin,
  });

  final Widget child;
  final double padding;
  final bool accent;
  final bool glow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent ? AppColors.accentSoftLine : AppColors.borderSubtle,
        ),
        boxShadow: glow ? AppEffects.glowCyanSm : AppEffects.shadowSm,
      ),
      child: child,
    );
  }
}
