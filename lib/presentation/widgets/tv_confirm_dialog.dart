import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'tv_button.dart';

/// Hộp thoại xác nhận theo tông app (nền surface, bo góc, 2 nút).
/// Trả về `true` nếu người dùng đồng ý, ngược lại `false`/`null`.
Future<bool?> showTvConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  String cancelLabel = 'Đóng',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.h3()),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppText.body(
                AppColors.textSecondary,
              ).copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TvButton(
                    label: cancelLabel,
                    variant: TvButtonVariant.ghost,
                    size: TvButtonSize.md,
                    fullWidth: true,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TvButton(
                    label: confirmLabel,
                    size: TvButtonSize.md,
                    fullWidth: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
