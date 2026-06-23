import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';

/// A choice in a [TvSegmentedControl].
class TvSegment {
  const TvSegment(this.value, this.label);
  final String value;
  final String label;
}

/// Segmented selector (e.g. storage capacity 256GB / 512GB / 1TB). The selected
/// segment gets a cyan border + cyan text + glow.
/// Mirrors `components/forms/SegmentedControl.jsx`.
class TvSegmentedControl extends StatelessWidget {
  const TvSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
    this.fullWidth = true,
  });

  final List<TvSegment> options;
  final String value;
  final ValueChanged<String>? onChanged;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final children = options.map((o) {
      final selected = o.value == value;
      final segment = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged?.call(o.value),
        child: AnimatedContainer(
          duration: AppEffects.durFast,
          height: 46,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSoft : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.borderDefault,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? AppEffects.glowCyanSm : null,
          ),
          child: Text(
            o.label,
            style: AppText.label(
              selected ? AppColors.textAccent : AppColors.textSecondary,
            ).copyWith(
              fontSize: 14,
              letterSpacing: 0.3,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
        ),
      );
      return fullWidth ? Expanded(child: segment) : segment;
    }).toList();

    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          children[i],
        ],
      ],
    );
  }
}
