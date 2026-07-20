import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../widgets/widgets.dart';
import '../../../core/theme/app_typography.dart';

/// Nội dung panel liquid-glass của màn theo dõi đơn: tài xế + trạng thái,
/// ETA hero, timeline 3 mốc, danh sách sản phẩm đang giao, địa chỉ.
///
/// Stateless — mọi dữ liệu sống (waiting/live/eta/updatedAt) do màn cha bơm
/// xuống mỗi lần setState. Root là ListView dùng [scrollController] được
/// DraggableScrollableSheet cấp (bắt buộc, không thì kéo sheet hỏng).
class TrackingPanel extends StatelessWidget {
  const TrackingPanel({
    super.key,
    required this.order,
    required this.scrollController,
    required this.waiting,
    required this.live,
    required this.delivered,
    this.error,
    this.updatedAtIso,
    this.etaMinutes,
    this.etaArrival,
  });

  final OrderModel order;
  final ScrollController scrollController;

  /// Chưa có GPS shipper (đang chờ nhận đơn).
  final bool waiting;
  final bool live;
  final bool delivered;
  final String? error;
  final String? updatedAtIso;

  /// Phút dự kiến (từ Goong duration) — null thì ẩn hero.
  final int? etaMinutes;
  final DateTime? etaArrival;

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _orderPlacedLabel {
    final t = DateTime.tryParse(order.orderDate)?.toLocal();
    if (t == null) return '';
    return '${_hhmm(t)} · ${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(18, 8, 18, 24 + bottomInset),
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _driverRow(context),
        const SizedBox(height: 14),
        _etaHero(),
        const SizedBox(height: 14),
        Divider(height: 1, color: AppColors.borderSubtle),
        const SizedBox(height: 14),
        _timeline(),
        if (order.lines.isNotEmpty) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 14),
          Text(
            'SẢN PHẨM (${order.itemCount ?? order.lines.length})',
            style: AppText.label(
              AppColors.textTertiary,
            ).copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          for (final line in order.lines) _itemRow(line),
        ],
        const SizedBox(height: 14),
        Divider(height: 1, color: AppColors.borderSubtle),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvIcon('map-pin', size: 15, color: AppColors.textAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                order.shippingAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.sm(),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              TvIcon('x-circle', size: 14, color: AppColors.danger500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(error!, style: AppText.xs(AppColors.dangerStrong)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Hàng tài xế + pill trạng thái ─────────────────────────────────────────

  Widget _driverRow(BuildContext context) {
    final hasStaff = order.staffId.isNotEmpty;
    final staffCode = hasStaff
        ? '#${order.staffId.length >= 8 ? order.staffId.substring(0, 8) : order.staffId}'
        : 'Chưa phân công';
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(color: AppColors.accentSoftLine),
          ),
          child: TvIcon('user', size: 18, color: AppColors.textAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài xế TechStore',
                style: AppText.sm().copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                staffCode,
                style: AppText.xs(
                  AppColors.textTertiary,
                ).copyWith(fontSize: 10.5),
              ),
            ],
          ),
        ),
        _statusPill(context),
      ],
    );
  }

  Widget _statusPill(BuildContext context) {
    final (String icon, String label, Color color, bool pulse) = delivered
        ? ('check-circle', 'Đã giao', AppColors.success500, false)
        : waiting
        ? ('clock', 'Chờ nhận đơn', AppColors.textSecondary, false)
        : live
        ? ('zap', 'Trực tiếp', AppColors.success500, true)
        : ('clock', 'Đang kết nối…', AppColors.textSecondary, false);

    Widget dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
    if (pulse && AppEffects.motionScale(context) > 0) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(
            begin: 0.35,
            end: 1,
            duration: const Duration(milliseconds: 700),
          );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            dot,
            const SizedBox(width: 6),
          ] else ...[
            TvIcon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.xs(
              color,
            ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── ETA hero ──────────────────────────────────────────────────────────────

  Widget _etaHero() {
    final String sub;
    if (delivered) {
      sub = 'Giao thành công 🎉';
    } else if (waiting) {
      sub = 'Ước tính khi shipper nhận đơn';
    } else if (etaArrival != null) {
      sub = 'Dự kiến đến ${_hhmm(etaArrival!)}';
    } else {
      sub = 'Đang tính thời gian…';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (etaMinutes != null && !delivered) ...[
          Text(
            '$etaMinutes',
            style: AppText.display().copyWith(fontSize: 40, height: 1),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text('phút', style: AppText.sm(AppColors.textSecondary)),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sub,
                style:
                    AppText.sm(
                      delivered
                          ? AppColors.success500
                          : AppColors.textSecondary,
                    ).copyWith(
                      fontWeight: delivered ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
              if (updatedAtIso != null && !delivered) ...[
                const SizedBox(height: 2),
                Text(
                  'Cập nhật ${formatRelativeFromIso(updatedAtIso!)}',
                  style: AppText.xs(
                    AppColors.textTertiary,
                  ).copyWith(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Timeline 3 mốc ────────────────────────────────────────────────────────

  Widget _timeline() {
    final shipping = !waiting; // đã có shipper chạy (hoặc đã giao)
    return Column(
      children: [
        _timelineRow(
          icon: 'package',
          title: 'Đặt hàng',
          subtitle: _orderPlacedLabel,
          state: _TlState.done,
          showLine: true,
        ),
        _timelineRow(
          icon: 'truck',
          title: 'Đang giao',
          subtitle: delivered
              ? ''
              : live
              ? 'Realtime'
              : waiting
              ? 'Chờ shipper'
              : '',
          state: delivered
              ? _TlState.done
              : shipping
              ? _TlState.active
              : _TlState.pending,
          showLine: true,
        ),
        _timelineRow(
          icon: 'package-check',
          title: 'Giao thành công',
          subtitle: '',
          state: delivered ? _TlState.done : _TlState.pending,
          showLine: false,
        ),
      ],
    );
  }

  Widget _timelineRow({
    required String icon,
    required String title,
    required String subtitle,
    required _TlState state,
    required bool showLine,
  }) {
    final Color color = switch (state) {
      _TlState.done => AppColors.success500,
      _TlState.active => AppColors.accent,
      _TlState.pending => AppColors.textTertiary,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                child: state == _TlState.done
                    ? TvIcon('check', size: 12, color: color)
                    : TvIcon(icon, size: 11, color: color),
              ),
              if (showLine)
                Expanded(
                  child: Container(width: 2, color: AppColors.borderSubtle),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 14 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppText.sm().copyWith(
                        fontWeight: state == _TlState.pending
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: state == _TlState.pending
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppText.xs(
                        AppColors.textTertiary,
                      ).copyWith(fontSize: 10.5),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dòng sản phẩm ─────────────────────────────────────────────────────────

  Widget _itemRow(OrderLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ink900,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: ProductImage(url: line.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sm().copyWith(fontWeight: FontWeight.w600),
                ),
                if (line.brand.isNotEmpty)
                  Text(
                    line.brand,
                    style: AppText.xs(
                      AppColors.textTertiary,
                    ).copyWith(fontSize: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x${line.quantity}',
            style: AppText.mono(size: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Text(
            formatVnd(line.unitPrice),
            style: AppText.price().copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

enum _TlState { done, active, pending }
