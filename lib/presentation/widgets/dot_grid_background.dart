import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';

/// Near-black canvas with the faint dotted grid grain from `base.css`
/// (`--dot-grid`). Wrap a screen body to add the subtle cyberpunk texture.
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({
    super.key,
    required this.child,
    this.baseColor,
  });

  final Widget child;

  /// null = nền theo theme (AppColors.bgBase).
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: baseColor ?? AppColors.bgBase),
      child: CustomPaint(
        painter: const DotGridPainter(),
        child: child,
      ),
    );
  }
}
