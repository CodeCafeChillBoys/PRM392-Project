import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/admin_stats.dart';

/// Champagne trong suốt cho vùng tô dưới đường (đáy gradient = alpha 0).
const Color _accentClear = Color(0x00CDAA62);

/// Biểu đồ ĐƯỜNG số đơn theo ngày — bổ trợ cho biểu đồ cột doanh thu (cùng dải
/// ngày, khác chỉ số). Tự vẽ [CustomPainter] như [AdminRevenueChart] để giữ
/// trọn token theme, không thêm gói ngoài. Đường "vẽ" từ trái sang khi vào màn.
class AdminOrdersLineChart extends StatelessWidget {
  const AdminOrdersLineChart({
    super.key,
    required this.points,
    this.height = 168,
  });

  final List<RevenuePoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return _empty();
    final maxOrders =
        points.map((p) => p.orders).fold<int>(0, (m, v) => v > m ? v : m);
    if (maxOrders <= 0) return _empty();

    final totalOrders = points.fold<int>(0, (s, p) => s + p.orders);
    final animate = AppEffects.motionScale(context) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Đỉnh: $maxOrders đơn/ngày',
                style: AppText.xs(AppColors.textTertiary)),
            const Spacer(),
            Text('$totalOrders đơn · ${points.length} ngày',
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
              painter: _OrdersLinePainter(
                points: points,
                maxOrders: maxOrders,
                progress: t,
                lineColor: AppColors.accent,
                fillTop: AppColors.accentSoft,
                fillBottom: _accentClear,
                dotColor: AppColors.accent,
                dotCore: AppColors.bgSurface,
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
          Icon(Icons.show_chart_rounded,
              size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text('Chưa có đơn trong khoảng này',
              style: AppText.sm(AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _OrdersLinePainter extends CustomPainter {
  _OrdersLinePainter({
    required this.points,
    required this.maxOrders,
    required this.progress,
    required this.lineColor,
    required this.fillTop,
    required this.fillBottom,
    required this.dotColor,
    required this.dotCore,
    required this.gridColor,
    required this.labelColor,
  });

  final List<RevenuePoint> points;
  final int maxOrders;
  final double progress;
  final Color lineColor;
  final Color fillTop;
  final Color fillBottom;
  final Color dotColor;
  final Color dotCore;
  final Color gridColor;
  final Color labelColor;

  static const double _labelBand = 18;
  static const double _topPad = 8;
  static const double _sidePad = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - _labelBand - _topPad;
    if (chartH <= 0 || points.isEmpty || maxOrders <= 0) return;
    final baseY = _topPad + chartH;

    // Lưới ngang 3 mức (0/50/100%).
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = _topPad + chartH * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final n = points.length;
    final usableW = size.width - _sidePad * 2;
    double xAt(int i) =>
        _sidePad + (n == 1 ? usableW / 2 : usableW * i / (n - 1));
    double yAt(int orders) =>
        baseY - chartH * (orders / maxOrders).clamp(0.0, 1.0);

    final pts = [for (var i = 0; i < n; i++) Offset(xAt(i), yAt(points[i].orders))];

    // Reveal trái→phải bằng cách cắt theo tiến độ.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    // Vùng tô dưới đường.
    final fillPath = Path()..moveTo(pts.first.dx, baseY);
    for (final p in pts) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(pts.last.dx, baseY)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTop, fillBottom],
      ).createShader(Rect.fromLTWH(0, _topPad, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Đường nối.
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < n; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);
    canvas.restore();

    // Chấm tại mỗi ngày (chỉ khi ít điểm cho đỡ rối) — vẽ sau clip cho sắc nét.
    final revealX = size.width * progress;
    if (n <= 14) {
      final ringPaint = Paint()..color = dotColor;
      final corePaint = Paint()..color = dotCore;
      for (final p in pts) {
        if (p.dx > revealX) continue;
        canvas.drawCircle(p, 3.5, ringPaint);
        canvas.drawCircle(p, 1.6, corePaint);
      }
    }

    // Nhãn ngày thưa (tối đa ~6) — luôn hiện, không bị clip.
    final labelEvery = (n / 6).ceil().clamp(1, n);
    for (var i = 0; i < n; i++) {
      if (i % labelEvery != 0) continue;
      final lbl = points[i].shortLabel;
      if (lbl.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: lbl,
          style: AppText.xs(labelColor).copyWith(fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(xAt(i) - tp.width / 2, size.height - _labelBand + 4),
      );
    }
  }

  @override
  bool shouldRepaint(_OrdersLinePainter old) =>
      old.progress != progress ||
      old.points != points ||
      old.maxOrders != maxOrders ||
      old.lineColor != lineColor;
}
