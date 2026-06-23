import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

enum TvPriceSize { sm, md, lg, xl }

/// Formatted VND price — accent cyan by default, optional struck-through
/// original. Mirrors `components/core/Price.jsx`.
class TvPrice extends StatelessWidget {
  const TvPrice({
    super.key,
    required this.value,
    this.original,
    this.size = TvPriceSize.md,
    this.color = AppColors.textAccent,
  });

  final num value;
  final num? original;
  final TvPriceSize size;
  final Color color;

  double get _fs => switch (size) {
        TvPriceSize.sm => 15,
        TvPriceSize.md => 20,
        TvPriceSize.lg => 26,
        TvPriceSize.xl => 34,
      };

  @override
  Widget build(BuildContext context) {
    final fs = _fs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatVnd(value),
          style: GoogleFonts.beVietnamPro(
            fontSize: fs,
            fontWeight: FontWeight.w700,
            letterSpacing: -fs * 0.01,
            color: color,
          ),
        ),
        if (original != null) ...[
          const SizedBox(width: 8),
          Text(
            formatVnd(original!),
            style: GoogleFonts.beVietnamPro(
              fontSize: (fs * 0.55).clamp(11, fs),
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }
}
