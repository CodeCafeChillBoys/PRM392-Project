import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/product.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';
import 'admin_common.dart';

/// Hai khu: Đơn hàng (giám sát) và Tồn kho (sửa nhanh).
enum _OsTab { orders, stock }

/// Khu Admin — Đơn & Kho: giám sát toàn bộ đơn (lọc theo trạng thái, tái dùng
/// [StaffTab] + [OrderStatusBadge]) và chỉnh nhanh tồn kho sản phẩm sắp hết
/// (`PUT /api/admin/products/{id}/stock`). Tab-page: tự có app bar.
class AdminOrdersStockScreen extends StatefulWidget {
  const AdminOrdersStockScreen({super.key});

  @override
  State<AdminOrdersStockScreen> createState() => _AdminOrdersStockScreenState();
}

class _AdminOrdersStockScreenState extends State<AdminOrdersStockScreen> {
  final _orderService = OrderService();
  final _adminService = AdminService();

  List<OrderModel> _orders = [];
  List<Product> _lowStock = [];
  bool _loading = true;
  _OsTab _tab = _OsTab.orders;
  StaffTab _orderFilter = StaffTab.all;

  /// Tồn kho đang chỉnh (chưa lưu) theo id sản phẩm — cho phép huỷ nếu chưa lưu.
  final Map<String, int> _pendingStock = {};

  /// Id sản phẩm đang gọi API lưu tồn (khoá stepper + hiện spinner).
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _orderService.fetchAllOrders(),
        _adminService.fetchLowStock(threshold: 10),
      ]);
      if (mounted) {
        setState(() {
          _orders = results[0] as List<OrderModel>;
          _lowStock = results[1] as List<Product>;
          _pendingStock.clear();
        });
      }
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được dữ liệu đơn & kho.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<OrderModel> get _visibleOrders =>
      _orders.where((o) => _orderFilter.accepts(o.status)).toList();

  Future<void> _saveStock(Product p) async {
    final target = _pendingStock[p.id];
    if (target == null || target == p.stockQuantity) return;
    setState(() => _saving.add(p.id));
    try {
      final updated = await _adminService.updateStock(p.id, target);
      if (!mounted) return;
      setState(() {
        final i = _lowStock.indexWhere((e) => e.id == p.id);
        if (i != -1) _lowStock[i] = updated;
        _pendingStock.remove(p.id);
      });
      TvToast.show(context, 'Đã cập nhật tồn kho "${p.name}".');
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không lưu được tồn kho. Thử lại sau.');
    } finally {
      if (mounted) setState(() => _saving.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.page,
          title: 'Đơn & Kho',
          actions: AdminActions.appBar(context, extra: [
            TvIconButton(
              icon: TvIcon('refresh-cw', color: AppColors.textAccent),
              tooltip: 'Tải lại',
              onPressed: _load,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TvTabs(
            distribute: true,
            value: _tab.name,
            tabs: [
              TvTab(_OsTab.orders.name, 'Đơn hàng (${_orders.length})'),
              TvTab(_OsTab.stock.name, 'Tồn thấp (${_lowStock.length})'),
            ],
            onChanged: (v) => setState(
                () => _tab = _OsTab.values.firstWhere((t) => t.name == v)),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return Skeletonizer(
        effect: ShimmerEffect(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
        ),
        child: ListView.separated(
          padding:
              EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => _orderCard(const OrderModel(
            id: 'ghostghost',
            customerName: 'Đang tải đơn',
            shippingAddress: '',
            totalAmount: 12000000,
            status: 'Pending',
            paymentMethod: 'COD',
            paymentStatus: 'Pending',
            orderDate: '',
            shippingFee: 0,
            staffId: '',
          )),
        ),
      );
    }
    return _tab == _OsTab.orders ? _ordersView() : _stockView();
  }

  Widget _ordersView() {
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: StaffTab.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = StaffTab.values[i];
              final count =
                  _orders.where((o) => t.accepts(o.status)).length;
              return _FilterChip(
                label: '${t.label} ($count)',
                selected: t == _orderFilter,
                onTap: () => setState(() => _orderFilter = t),
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.textAccent,
            backgroundColor: AppColors.bgSurface,
            child: _visibleOrders.isEmpty
                ? _empty('inbox', 'Không có đơn khớp bộ lọc')
                : ListView.separated(
                    key: ValueKey('orders-${_orderFilter.name}'),
                    padding: EdgeInsets.fromLTRB(
                        AppSpacing.gutter, 12, AppSpacing.gutter, 24),
                    itemCount: _visibleOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _orderCard(_visibleOrders[i])
                        .animate(delay: AppEffects.staggerStep * i.clamp(0, 6))
                        .fadeIn(
                            duration: AppEffects.durEnter,
                            curve: AppEffects.easeStandard)
                        .moveY(
                            begin: AppEffects.entranceRise,
                            end: 0,
                            curve: AppEffects.easeStandard),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _stockView() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: _lowStock.isEmpty
          ? _empty('package-check', 'Không có sản phẩm nào tồn thấp 🎉')
          : ListView.separated(
              key: const ValueKey('stock'),
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter, 14, AppSpacing.gutter, 24),
              itemCount: _lowStock.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _stockCard(_lowStock[i])
                  .animate(delay: AppEffects.staggerStep * i.clamp(0, 6))
                  .fadeIn(
                      duration: AppEffects.durEnter,
                      curve: AppEffects.easeStandard)
                  .moveY(
                      begin: AppEffects.entranceRise,
                      end: 0,
                      curve: AppEffects.easeStandard),
            ),
    );
  }

  Widget _orderCard(OrderModel o) {
    final isVnpay = o.paymentMethod == 'VNPay';
    final when = formatRelativeFromIso(o.orderDate);
    final shortId = o.id.length >= 8 ? o.id.substring(0, 8) : o.id;
    return TvCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#$shortId',
                  style: AppText.mono(size: 12, color: AppColors.textTertiary)),
              const SizedBox(width: 8),
              OrderStatusBadge(o.status),
              const Spacer(),
              Text(formatVnd(o.totalAmount),
                  style: AppText.price().copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  o.customerName.isEmpty ? 'Khách' : o.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong().copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              TvBadge(isVnpay ? 'VNPay' : 'COD',
                  variant:
                      isVnpay ? TvBadgeVariant.glass : TvBadgeVariant.neutral),
              if (when.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(when, style: AppText.xs(AppColors.textTertiary)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockCard(Product p) {
    final pending = _pendingStock[p.id] ?? p.stockQuantity;
    final dirty = pending != p.stockQuantity;
    final saving = _saving.contains(p.id);
    return TvCard(
      padding: 12,
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ColoredBox(
                    color: AppColors.ink900,
                    child: ProductImage(url: p.imageUrl, dimmed: p.isSoldOut),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong().copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ProductStockBadge(p.stockQuantity),
                        const SizedBox(width: 8),
                        Text(formatVnd(p.price),
                            style: AppText.price().copyWith(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Tồn mới', style: AppText.xs(AppColors.textSecondary)),
              const Spacer(),
              TvQuantityStepper(
                value: pending,
                min: 0,
                max: 9999,
                onChanged: saving
                    ? null
                    : (v) => setState(() => _pendingStock[p.id] = v),
              ),
            ],
          ),
          if (dirty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TvButton(
                    label: 'Huỷ',
                    variant: TvButtonVariant.ghost,
                    size: TvButtonSize.sm,
                    fullWidth: true,
                    onPressed: saving
                        ? null
                        : () => setState(() => _pendingStock.remove(p.id)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TvButton(
                    label: 'Lưu tồn',
                    variant: TvButtonVariant.accent,
                    size: TvButtonSize.sm,
                    fullWidth: true,
                    loading: saving,
                    onPressed: saving ? null : () => _saveStock(p),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(String icon, String message) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(child: TvIcon(icon, size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
            child:
                Text(message, style: AppText.body(AppColors.textSecondary))),
      ],
    );
  }
}

/// Chip lọc trạng thái đơn (giữ cùng style với `_CategoryChip` màn Staff).
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? AppEffects.glowAccentSm : null,
        ),
        child: Text(
          label,
          style: AppText.label(
            selected ? AppColors.textAccent : AppColors.textSecondary,
          ).copyWith(fontSize: 12.5, letterSpacing: 0.25),
        ),
      ),
    );
  }
}
