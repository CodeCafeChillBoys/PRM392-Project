import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Quantity stepper — minus / value / plus, as seen on cart line items and
/// the product detail screen. Mirrors `components/forms/QuantityStepper.jsx`.
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
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppText.mono(size: 15),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
