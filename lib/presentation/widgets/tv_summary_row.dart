import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum SummaryTone { normal, accent, success, danger, muted }

/// Single label/value row for invoice & order summaries. The [emphasis] variant
/// renders the grand total (large cyan glowing value).
/// Mirrors `components/data/SummaryRow.jsx`.
class TvSummaryRow extends StatelessWidget {
  const TvSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
    this.tone = SummaryTone.normal,
  });

  final String label;
  final String value;
  final bool emphasis;
  final SummaryTone tone;

  Color get _valueColor => switch (tone) {
    SummaryTone.normal => AppColors.textPrimary,
    SummaryTone.accent => AppColors.textAccent,
    SummaryTone.success => AppColors.success500,
    SummaryTone.danger => AppColors.danger500,
    SummaryTone.muted => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: emphasis ? 6 : 4),
      child: Row(
        crossAxisAlignment: emphasis
            ? CrossAxisAlignment.baseline
            : CrossAxisAlignment.center,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: emphasis
                  ? AppText.h2().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )
                  : AppText.body(
                      AppColors.textSecondary,
                    ).copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            // Grand total: priceXL gold KHÔNG glow — sự tiết chế chính là
            // tín hiệu luxury (glow neon đã nghỉ hưu ở đây).
            style: emphasis
                ? AppText.priceXL()
                : AppText.body(
                    _valueColor,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
