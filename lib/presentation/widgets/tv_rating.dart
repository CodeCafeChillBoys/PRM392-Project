import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Star rating chip — gold star + numeric value (e.g. "4.9/5").
/// Mirrors `components/core/Rating.jsx`.
class TvRating extends StatelessWidget {
  const TvRating({
    super.key,
    this.value = 4.9,
    this.scale = 5,
    this.showScale = true,
    this.size = 13,
  });

  final double value;
  final int scale;
  final bool showScale;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.star500, size: size + 3),
        const SizedBox(width: 4),
        Text(
          '$value${showScale ? '/$scale' : ''}',
          style: AppText.body().copyWith(
            fontSize: size,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
