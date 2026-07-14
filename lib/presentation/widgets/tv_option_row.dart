import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';

/// Selectable option row for shipping & payment methods on checkout. Selected
/// state draws a cyan border + soft fill + glow, and a cyan-filled radio.
/// Mirrors `components/forms/OptionRow.jsx`.
class TvOptionRow extends StatelessWidget {
  const TvOptionRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.showRadio = true,
  });

  final Widget? icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final bool showRadio;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppEffects.durFast,
        curve: AppEffects.easeStandard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? AppEffects.glowAccentSm : null,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bgOverlay,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: selected
                        ? AppColors.textAccent
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                  child: icon!,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppText.bodyStrong()),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppText.sm(selected
                              ? AppColors.textAccent
                              : AppColors.textSecondary)
                          .copyWith(fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Text(
                trailing!,
                style: AppText.body().copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
            if (showRadio) ...[
              const SizedBox(width: 12),
              _Radio(selected: selected),
            ],
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.accent : Colors.transparent,
        border: selected
            ? null
            : Border.all(color: AppColors.borderStrong, width: 2),
        boxShadow: selected ? AppEffects.glowAccentSm : null,
      ),
      child: selected
          ? const SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgBase,
                ),
              ),
            )
          : null,
    );
  }
}
