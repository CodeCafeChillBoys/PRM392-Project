import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/admin_stats.dart';
import '../../../data/models/order_status.dart';
import '../../widgets/order_status_badge.dart';

/// Biểu đồ TRÒN (donut) tỉ trọng trạng thái đơn + chú thích bên phải. Tự vẽ
/// [CustomPainter], mỗi cung một màu semantic khớp badge trạng thái; tâm hiện
/// tổng số đơn. Cung "quét" ra từ đỉnh khi vào màn.
class AdminStatusDonut extends StatelessWidget {
  const AdminStatusDonut({super.key, required this.data});

  final List<StatusCount> data;

  @override
  Widget build(BuildContext context) {
    final items = [...data]..sort((a, b) => b.count.compareTo(a.count));
    final total = items.fold<int>(0, (s, e) => s + e.count);
    if (items.isEmpty || total == 0) {
      return Text('Chưa có đơn trong khoảng này',
          style: AppText.sm(AppColors.textSecondary));
    }
    final animate = AppEffects.motionScale(context) > 0;
    final slices = [
      for (final e in items)
        _StatusSlice(color: _statusColor(e.status), value: e.count),
    ];

    return Row(
      children: [
        SizedBox(
          width: 128,
          height: 128,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0 : 1, end: 1),
            duration: AppEffects.durMorph,
            curve: AppEffects.easeStandard,
            builder: (context, t, _) => CustomPaint(
              painter: _DonutPainter(
                slices: slices,
                total: total,
                progress: t,
                trackColor: AppColors.bgOverlay,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$total',
                        style: AppText.price().copyWith(fontSize: 24)),
                    Text('đơn', style: AppText.xs(AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 11),
                _legendRow(items[i], total),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(StatusCount sc, int total) {
    final pct = ((sc.count / total) * 100).round();
    final label = orderStatusBadgeData(sc.status).$1;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _statusColor(sc.status),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sm(AppColors.textPrimary).copyWith(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text('${sc.count}', style: AppText.bodyStrong().copyWith(fontSize: 13)),
        const SizedBox(width: 6),
        SizedBox(
          width: 38,
          child: Text('$pct%',
              textAlign: TextAlign.right,
              style: AppText.xs(AppColors.textTertiary)),
        ),
      ],
    );
  }
}

/// Màu semantic cho từng trạng thái — đồng bộ tinh thần badge (giao=xanh lá,
/// đang giao=cyan, huỷ=đỏ...), đủ tách nhau trên donut.
Color _statusColor(String status) {
  switch (status) {
    case OrderStatus.delivered:
      return AppColors.success500;
    case OrderStatus.shipped:
      return AppColors.signal;
    case OrderStatus.confirmed:
      return AppColors.accent;
    case OrderStatus.pending:
      return AppColors.warning500;
    case OrderStatus.pendingPayment:
      return AppColors.violet400;
    case OrderStatus.cancelled:
      return AppColors.danger500;
    default:
      return AppColors.textTertiary;
  }
}

class _StatusSlice {
  const _StatusSlice({required this.color, required this.value});
  final Color color;
  final int value;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.progress,
    required this.trackColor,
  });

  final List<_StatusSlice> slices;
  final int total;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = (Offset.zero & size).center;
    const stroke = 16.0;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    if (radius <= 0) return;

    // Vòng nền (track).
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (total <= 0) return;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    const gap = 0.045; // khe radian giữa các cung
    var start = -math.pi / 2;
    for (final s in slices) {
      final full = (s.value / total) * 2 * math.pi;
      final sweep = ((full - gap).clamp(0.0, 2 * math.pi)) * progress;
      if (sweep > 0) {
        canvas.drawArc(
          arcRect,
          start + gap / 2,
          sweep,
          false,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round,
        );
      }
      start += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.slices != slices ||
      old.total != total;
}
