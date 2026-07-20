import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';

/// The signature gradient pill toast (e.g. "Đã thêm … vào giỏ"). A single
/// instance lives in the root overlay: pops in, holds ~1.6s, fades out.
class TvToast {
  TvToast._();

  static OverlayEntry? _current;

  static void show(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TvToastView(
        message: message,
        onComplete: () {
          entry.remove();
          if (identical(_current, entry)) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _TvToastView extends StatefulWidget {
  const _TvToastView({required this.message, required this.onComplete});

  final String message;
  final VoidCallback onComplete;

  @override
  State<_TvToastView> createState() => _TvToastViewState();
}

class _TvToastViewState extends State<_TvToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppEffects.durSlow,
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _controller,
    curve: AppEffects.easeEmphasized,
  );
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    if (!mounted) return;
    _holdTimer = Timer(const Duration(milliseconds: 1600), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 96,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FadeTransition(
            opacity: _anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(_anim),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientCta,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: AppEffects.glowCta,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.get('check-circle'),
                      size: 16,
                      color: AppColors.textOnAccent,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.button(size: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
