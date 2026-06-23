import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Uppercase section header with an optional leading cyan icon and trailing
/// action, used across checkout & summaries.
/// Mirrors `components/navigation/SectionHeader.jsx`.
class TvSectionHeader extends StatelessWidget {
  const TvSectionHeader({
    super.key,
    this.icon,
    required this.title,
    this.action,
  });

  final Widget? icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          IconTheme.merge(
            data: const IconThemeData(color: AppColors.textAccent, size: 18),
            child: icon!,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppText.h2().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.72,
              height: 1.2,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}
