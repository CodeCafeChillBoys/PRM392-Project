import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'tv_icon.dart';

/// One entry in the [TvBottomNav].
class TvNavItem {
  const TvNavItem({required this.label, required this.iconName});
  final String label;
  final String iconName;
}

/// Fixed bottom tab bar. The active item shows a cyan icon + label inside a
/// soft glowing pill. Mirrors `components/navigation/BottomNav.jsx`.
class TvBottomNav extends StatelessWidget {
  const TvBottomNav({
    super.key,
    required this.items,
    required this.activeIndex,
    this.onChanged,
  });

  final List<TvNavItem> items;
  final int activeIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _NavButton(
                  item: items[i],
                  active: i == activeIndex,
                  onTap: () => onChanged?.call(i),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});

  final TvNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.textAccent : AppColors.textTertiary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppEffects.durBase,
              curve: AppEffects.easeStandard,
              width: 40,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: active ? AppEffects.glowCyanSm : null,
              ),
              child: TvIcon(item.iconName, size: 20, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppText.label(color).copyWith(
                fontSize: 10.5,
                letterSpacing: 0.4,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
