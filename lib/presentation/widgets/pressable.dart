import 'package:flutter/material.dart';

import '../../core/theme/app_effects.dart';

/// Wraps a child with the design system's tactile press feedback — a quick
/// scale-down on tap (buttons → 0.97, icon buttons → 0.92).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (_active) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => _setPressed(true) : null,
      onTapUp: _active ? (_) => _setPressed(false) : null,
      onTapCancel: _active ? () => _setPressed(false) : null,
      onTap: _active ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: AppEffects.durFast,
        curve: AppEffects.easeStandard,
        child: widget.child,
      ),
    );
  }
}
