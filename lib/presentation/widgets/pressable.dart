import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_effects.dart';

/// Loại haptic phát khi nhấn — ánh xạ sang [HapticFeedback].
enum PressHaptic { none, light, selection, medium, heavy }

/// Wraps a child with the design system's tactile press feedback — a quick
/// scale-down on tap (buttons → 0.97, icon buttons → 0.92), nhả tay nảy nhẹ
/// theo [AppEffects.easeEmphasized], kèm haptic (mặc định lightImpact).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.enabled = true,
    this.haptic = PressHaptic.light,
    this.pressedOpacity = 1.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enabled;

  /// Haptic khi tap. `selection` cho stepper/toggle, `medium` cho hành động
  /// quan trọng (thêm giỏ hàng), `none` để tắt.
  final PressHaptic haptic;

  /// Giảm opacity nhẹ khi đè (1.0 = tắt). 0.9 hợp cho card lớn.
  final double pressedOpacity;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (_active) setState(() => _pressed = value);
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case PressHaptic.none:
        break;
      case PressHaptic.light:
        HapticFeedback.lightImpact();
      case PressHaptic.selection:
        HapticFeedback.selectionClick();
      case PressHaptic.medium:
        HapticFeedback.mediumImpact();
      case PressHaptic.heavy:
        HapticFeedback.heavyImpact();
    }
  }

  void _handleTap() {
    _fireHaptic();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => _setPressed(true) : null,
      onTapUp: _active ? (_) => _setPressed(false) : null,
      onTapCancel: _active ? () => _setPressed(false) : null,
      onTap: _active ? _handleTap : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppEffects.durFast,
        // Nhấn xuống gọn theo easeStandard; nhả tay nảy nhẹ (spring-back).
        curve: _pressed ? AppEffects.easeStandard : AppEffects.easeEmphasized,
        child: AnimatedOpacity(
          opacity: _pressed ? widget.pressedOpacity : 1.0,
          duration: AppEffects.durFast,
          child: widget.child,
        ),
      ),
    );
  }
}
