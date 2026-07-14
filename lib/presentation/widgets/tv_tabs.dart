import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';

/// A tab in a [TvTabs] strip.
class TvTab {
  const TvTab(this.value, this.label);
  final String value;
  final String label;
}

/// Underline tabs (product detail "Mô tả / Đánh giá", notifications
/// "KHUYẾN MÃI / ĐƠN HÀNG"). The active tab is cyan with a glowing underline.
/// Mirrors `components/navigation/Tabs.jsx`.
class TvTabs extends StatelessWidget {
  const TvTabs({
    super.key,
    required this.tabs,
    required this.value,
    this.onChanged,
    this.distribute = false,
  });

  final List<TvTab> tabs;
  final String value;
  final ValueChanged<String>? onChanged;

  /// When true, tabs spread evenly across the width (notifications); otherwise
  /// they sit left-aligned with a 24px gap (product detail).
  final bool distribute;

  @override
  Widget build(BuildContext context) {
    final tabWidgets = [
      for (final t in tabs)
        _TabButton(
          tab: t,
          selected: t.value == value,
          onTap: () => onChanged?.call(t.value),
        ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment:
            distribute ? MainAxisAlignment.spaceAround : MainAxisAlignment.start,
        children: [
          for (var i = 0; i < tabWidgets.length; i++) ...[
            if (!distribute && i > 0) const SizedBox(width: 24),
            tabWidgets[i],
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final TvTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUpper = tab.label == tab.label.toUpperCase();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Text(
              tab.label,
              textAlign: TextAlign.center,
              style: AppText.body(
                selected ? AppColors.textAccent : AppColors.textSecondary,
              ).copyWith(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: isUpper ? 1.12 : 0,
              ),
            ),
          ),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: selected ? AppEffects.glowAccentSm : null,
            ),
          ),
        ],
      )),
    );
  }
}
