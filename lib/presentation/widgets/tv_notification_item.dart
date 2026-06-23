import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/app_notification.dart';
import 'tv_icon.dart';

/// Notification / promo list row — leading icon tile, title, body, timestamp,
/// and an unread dot. Mirrors `components/data/NotificationItem.jsx`.
class TvNotificationItem extends StatelessWidget {
  const TvNotificationItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  (Color, Color) get _tone => switch (notification.tone) {
        NotificationTone.accent => (AppColors.accentSoft, AppColors.textAccent),
        NotificationTone.violet => (AppColors.violetSoft, AppColors.violet400),
        NotificationTone.neutral => (AppColors.bgOverlay, AppColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final (tileBg, tileFg) = _tone;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TvIcon(notification.iconName, size: 18, color: tileFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppText.body().copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (notification.unread)
                        Container(
                          margin: const EdgeInsets.only(top: 5, left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: AppText.sm().copyWith(fontSize: 12.5, height: 1.45),
                    ),
                  ],
                  if (notification.time.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      notification.time,
                      style: AppText.xs(AppColors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
