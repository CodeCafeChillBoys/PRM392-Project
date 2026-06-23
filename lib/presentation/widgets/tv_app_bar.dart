import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'tv_icon.dart';
import 'tv_icon_button.dart';

enum TvAppBarMode { brand, page }

/// Top app bar — `brand` mode (logo + actions) or `page` mode (back + title +
/// actions). Designed to be the first child of a screen's column (it handles
/// its own status-bar inset via [SafeArea]). Mirrors
/// `components/navigation/AppBar.jsx`.
class TvAppBar extends StatelessWidget {
  const TvAppBar({
    super.key,
    this.mode = TvAppBarMode.page,
    this.title = '',
    this.brand,
    this.onBack,
    this.leading,
    this.actions = const [],
  });

  final TvAppBarMode mode;
  final String title;
  final Widget? brand;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.ink900, AppColors.bgBase],
        ),
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (mode == TvAppBarMode.page && onBack != null)
                  TvIconButton(
                    icon: const TvIcon('arrow-left', size: 22, color: AppColors.textAccent),
                    onPressed: onBack,
                    tooltip: 'Quay lại',
                  ),
                ?leading,
                if (mode == TvAppBarMode.brand)
                  brand ?? const SizedBox.shrink()
                else
                  Text(
                    title,
                    style: AppText.h2(AppColors.textAccent).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                const Spacer(),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  actions[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
