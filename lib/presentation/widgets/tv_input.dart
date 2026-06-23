import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum TvInputSize { md, lg }

/// Text / search input on a dark surface, with an optional leading icon and
/// trailing slot. Set [dashed] for the cart voucher field's dashed outline.
/// Mirrors `components/forms/Input.jsx`.
class TvInput extends StatelessWidget {
  const TvInput({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = '',
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.size = TvInputSize.md,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.fillColor,
    this.dashed = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final Widget? leading;
  final Widget? trailing;
  final bool obscureText;
  final TvInputSize size;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final Color? fillColor;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final height = size == TvInputSize.lg ? 52.0 : 44.0;

    Widget field = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fillColor ?? (dashed ? Colors.transparent : AppColors.bgElevated),
        borderRadius: BorderRadius.circular(12),
        border: dashed ? null : Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            IconTheme.merge(
              data: const IconThemeData(color: AppColors.textTertiary, size: 18),
              child: leading!,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofocus: autofocus,
              cursorColor: AppColors.accent,
              style: AppText.body(),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: AppText.body(AppColors.textTertiary),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );

    if (dashed) {
      field = CustomPaint(
        foregroundPainter: _DashedRRectPainter(color: AppColors.borderDefault),
        child: field,
      );
    }
    return field;
  }
}

/// Paints a dashed rounded-rectangle outline (cart voucher field).
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color});

  final Color color;

  static const double _radius = 12;
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );
    final source = Path()..addRRect(rrect);
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        dashedPath.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + _gap;
      }
    }
    canvas.drawPath(
      dashedPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color;
}
