import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Fixed bottom tab bar — VOID LUXE glass: BackdropFilter blur nội dung cuộn
/// phía sau (tắt qua [AppEffects.kGlassEnabled] → nền mờ đặc). Active item =
/// icon + label gold trong pill goldSoft. Haptic selection khi chuyển tab.
/// Mirrors `components/navigation/BottomNav.jsx`.
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
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: AppEffects.kGlassEnabled
            ? AppEffects.glassFill
            : AppEffects.glassFallbackFill,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                    child: _NavButton(
                  item: items[i],
                  active: i == activeIndex,
                  onTap: () {
                    if (i != activeIndex) HapticFeedback.selectionClick();
                    onChanged?.call(i);
                  },
                )),
            ],
          ),
        ),
      ),
    );

    if (!AppEffects.kGlassEnabled) return bar;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppEffects.glassSigma,
          sigmaY: AppEffects.glassSigma,
        ),
        child: bar,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton(
      {required this.item, required this.active, required this.onTap});

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
