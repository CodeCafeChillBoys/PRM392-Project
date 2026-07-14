import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum TvInputSize { md, lg }

/// Text / search input on a dark surface, with an optional leading icon and
/// trailing slot. Set [dashed] for the cart voucher field's dashed outline.
///
/// VOID LUXE: có focus state thật — border chuyển gold, focus ring toả nhẹ,
/// icon dẫn chuyển màu (AnimatedContainer 200ms).
/// Mirrors `components/forms/Input.jsx`.
class TvInput extends StatefulWidget {
  const TvInput({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
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
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
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

  /// Số dòng tối đa — > 1 biến ô thành textarea (bỏ chiều cao cố định).
  final int maxLines;

  @override
  State<TvInput> createState() => _TvInputState();
}

class _TvInputState extends State<TvInput> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.size == TvInputSize.lg ? 52.0 : 44.0;
    final multiline = widget.maxLines > 1;

    Widget field = AnimatedContainer(
      duration: AppEffects.durBase,
      curve: AppEffects.easeStandard,
      height: multiline ? null : height,
      padding:
          EdgeInsets.symmetric(horizontal: 14, vertical: multiline ? 10 : 0),
      decoration: BoxDecoration(
        color: widget.fillColor ??
            (widget.dashed ? Colors.transparent : AppColors.bgElevated),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: widget.dashed
            ? null
            : Border.all(
                color:
                    _focused ? AppColors.borderAccent : AppColors.borderDefault,
              ),
        boxShadow: _focused && !widget.dashed ? AppEffects.focusRing : null,
      ),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (widget.leading != null) ...[
            AnimatedSwitcher(
              duration: AppEffects.durBase,
              child: IconTheme.merge(
                key: ValueKey(_focused),
                data: IconThemeData(
                  color:
                      _focused ? AppColors.gold400 : AppColors.textTertiary,
                  size: 18,
                ),
                child: widget.leading!,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onEditingComplete: widget.onEditingComplete,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofocus: widget.autofocus,
              cursorColor: AppColors.accent,
              style: AppText.body(),
              maxLines: widget.maxLines,
              textAlignVertical:
                  multiline ? TextAlignVertical.top : TextAlignVertical.center,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: AppText.body(AppColors.textTertiary),
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 10),
            widget.trailing!,
          ],
        ],
      ),
    );

    if (widget.dashed) {
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
