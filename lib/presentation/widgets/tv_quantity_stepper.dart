import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';
import 'pressable.dart';

/// Quantity stepper — minus / value / plus, as seen on cart line items and
/// the product detail screen.
///
/// VOID LUXE: nút có press-scale + haptic selection; con số đổi bằng
/// AnimatedSwitcher trượt dọc (tăng trượt lên, giảm trượt xuống).
/// Mirrors `components/forms/QuantityStepper.jsx`.
class TvQuantityStepper extends StatelessWidget {
  const TvQuantityStepper({
    super.key,
    this.value = 1,
    this.min = 1,
    this.max = 99,
    this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  void _set(int next) {
    final clamped = next.clamp(min, max);
    if (onChanged != null && clamped != value) onChanged!(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(icon: Icons.remove, onTap: () => _set(value - 1)),
        const SizedBox(width: 10),
        SizedBox(
          width: 22,
          height: 22,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              switchInCurve: AppEffects.easeStandard,
              switchOutCurve: AppEffects.easeStandard,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: AppText.mono(size: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _StepButton(icon: Icons.add, onTap: () => _set(value + 1)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.88,
      haptic: PressHaptic.selection,
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgOverlay,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}
