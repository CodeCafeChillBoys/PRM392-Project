import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum TvLogoSize { sm, md, lg }

/// The TECH_VOID wordmark — cyan SIGNAL + glow, DNA neon sống sót duy nhất
/// trong VOID LUXE (accent app giờ là gold nên KHÔNG dùng AppColors.accent
/// ở đây). Mirrors `components/core/Logo.jsx`.
class TvLogo extends StatelessWidget {
  const TvLogo({
    super.key,
    this.size = TvLogoSize.md,
    this.glyph = true,
    this.color = AppColors.signal,
  });

  final TvLogoSize size;
  final bool glyph;
  final Color color;

  double get _fs => switch (size) {
        TvLogoSize.sm => 16,
        TvLogoSize.md => 20,
        TvLogoSize.lg => 28,
      };

  @override
  Widget build(BuildContext context) {
    final fs = _fs;
    final wordmark = AppText.wordmark(size: fs, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph) ...[
          Container(
            width: fs * 1.05,
            height: fs * 1.05,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(4),
              // Glow cyan theo mau glyph (khong dung glowAccent — gio la gold).
              boxShadow: const [
                BoxShadow(color: Color(0x4D00F0FF), blurRadius: 12),
              ],
            ),
            child: Icon(Icons.grid_view_rounded, size: fs * 0.62, color: color),
          ),
          SizedBox(width: fs * 0.4),
        ],
        Text.rich(
          TextSpan(
            style: wordmark,
            children: [
              const TextSpan(text: 'TECH'),
              TextSpan(
                text: '_',
                style: wordmark.copyWith(
                  color: color.withValues(alpha: 0.85),
                ),
              ),
              const TextSpan(text: 'VOID'),
            ],
          ),
        ),
      ],
    );
  }
}
