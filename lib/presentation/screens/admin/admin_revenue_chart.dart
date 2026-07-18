import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_stats.dart';

/// Biểu đồ cột doanh thu theo ngày cho khu Admin — Tổng quan.
///
/// Tự vẽ bằng [CustomPainter] (tiền lệ `DotGridPainter`) thay vì thêm gói chart
/// ngoài: giữ trọn token thị giác theo theme (cột champagne `gradientBadge`,
/// lưới `borderSubtle`, nhãn `AppText.xs`) và tránh rủi ro phụ thuộc trên Dart
/// 3.11.5. Cột "mọc" từ đáy khi vào màn (gate theo `motionScale`).
class AdminRevenueChart extends StatelessWidget {
  const AdminRevenueChart({super.key, required this.points, this.height = 168});

  final List<RevenuePoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return _empty();

    final maxRevenue = points
        .map((p) => p.revenue)
        .fold<double>(0, (m, v) => v > m ? v : m);

    // Reduce-motion: bỏ qua animation "mọc" (bắt đầu ở trạng thái đầy đủ).
    final animate = AppEffects.motionScale(context) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Đỉnh: ${formatVnd(maxRevenue)}',
                style: AppText.xs(AppColors.textTertiary)),
            const Spacer(),
            Text('${points.length} ngày',
                style: AppText.xs(AppColors.textTertiary)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0 : 1, end: 1),
            duration: AppEffects.durMorph,
            curve: AppEffects.easeStandard,
            builder: (context, t, _) => CustomPaint(
              painter: _RevenueBarsPainter(
                points: points,
                maxRevenue: maxRevenue,
                progress: t,
                barColorTop: AppColors.isLight
                    ? const Color(0xFF2E2921)
                    : AppColors.gold400,
                barColorBottom: AppColors.isLight
                    ? const Color(0xFF14110C)
                    : AppColors.gold600,
                gridColor: AppColors.borderSubtle,
                labelColor: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text('Chưa có doanh thu trong khoảng này',
              style: AppText.sm(AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _RevenueBarsPainter extends CustomPainter {
  _RevenueBarsPainter({
    required this.points,
    required this.maxRevenue,
    required this.progress,
    required this.barColorTop,
    required this.barColorBottom,
    required this.gridColor,
    required this.labelColor,
  });

  final List<RevenuePoint> points;
  final double maxRevenue;
  final double progress;
  final Color barColorTop;
  final Color barColorBottom;
  final Color gridColor;
  final Color labelColor;

  static const double _labelBand = 18; // chừa đáy cho nhãn ngày
  static const double _topPad = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - _labelBand - _topPad;
    if (chartH <= 0) return;
    final baseY = _topPad + chartH;

    // Lưới ngang 3 mức (0/50/100%).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = _topPad + chartH * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty || maxRevenue <= 0) return;

    // Bề rộng mỗi cột + khe; giới hạn cột không quá mập khi ít ngày.
    final slot = size.width / points.length;
    final barW = (slot * 0.6).clamp(3.0, 22.0);

    // Nhãn ngày thưa dần để không chồng (tối đa ~6 nhãn).
    final labelEvery = (points.length / 6).ceil().clamp(1, points.length);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = slot * i + slot / 2;
      final ratio = (p.revenue / maxRevenue).clamp(0.0, 1.0);
      final barH = chartH * ratio * progress;
      if (barH > 0) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barW / 2, baseY - barH, barW, barH),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [barColorTop, barColorBottom],
          ).createShader(Rect.fromLTWH(cx - barW / 2, baseY - barH, barW, barH));
        canvas.drawRRect(rect, paint);
      }

      if (i % labelEvery == 0 && p.shortLabel.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: p.shortLabel,
            style: AppText.xs(labelColor).copyWith(fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(cx - tp.width / 2, size.height - _labelBand + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RevenueBarsPainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.maxRevenue != maxRevenue ||
      old.barColorTop != barColorTop;
}
