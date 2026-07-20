import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';

/// Trang Staff — duyệt yêu cầu hoàn tiền. Lọc client-side các đơn có
/// `paymentStatus == RefundRequested` từ `fetchAllOrders()` (BE chưa có
/// endpoint danh sách riêng). Duyệt → cộng ví khách + cộng kho + đơn sang
/// `Refunded`; Từ chối → đơn về `Paid`. Tab-page: tự có app bar, không Scaffold.
class StaffRefundsScreen extends StatefulWidget {
  const StaffRefundsScreen({super.key});

  @override
  State<StaffRefundsScreen> createState() => _StaffRefundsScreenState();
}

class _StaffRefundsScreenState extends State<StaffRefundsScreen> {
  final _service = OrderService();
  final _auth = AuthService();

  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.fetchAllOrders();
      if (mounted) {
        setState(() => _orders =
            list.where((o) => o.paymentStatus == 'RefundRequested').toList());
      }
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được yêu cầu hoàn.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(OrderModel o) async {
    if (_busyId != null) return;
    final ok = await showTvConfirm(
      context,
      title: 'Duyệt hoàn tiền?',
      message: 'Sẽ hoàn ${formatVnd(o.totalAmount)} vào ví khách và cộng lại '
          'kho. Hành động này không thể hoàn tác.',
      confirmLabel: 'Duyệt',
    );
    if (ok != true) return;
    setState(() => _busyId = o.id);
    try {
      await _service.approveRefund(o.id);
      await _load();
      if (mounted) {
        TvToast.show(context, 'Đã duyệt hoàn đơn #${_shortId(o.id)}.');
      }
    } catch (e) {
      if (mounted) {
        TvToast.show(
            context, e is ApiException ? e.message : 'Duyệt hoàn thất bại.');
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(OrderModel o) async {
    if (_busyId != null) return;
    final ok = await showTvConfirm(
      context,
      title: 'Từ chối hoàn tiền?',
      message: 'Đơn #${_shortId(o.id)} sẽ trở lại trạng thái "Đã thanh toán" '
          'và không được hoàn về ví.',
      confirmLabel: 'Từ chối',
    );
    if (ok != true) return;
    setState(() => _busyId = o.id);
    try {
      await _service.rejectRefund(o.id);
      await _load();
      if (mounted) {
        TvToast.show(context, 'Đã từ chối yêu cầu hoàn #${_shortId(o.id)}.');
      }
    } catch (e) {
      if (mounted) {
        TvToast.show(
            context, e is ApiException ? e.message : 'Từ chối thất bại.');
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  @override
  Widget build(BuildContext context) {
    // Tab-page trong StaffShell: shell lo Scaffold + bottom nav.
    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.page,
          title: 'Yêu cầu hoàn',
          actions: [
            TvIconButton(
              icon: TvIcon('log-out', color: AppColors.textAccent),
              tooltip: 'Đăng xuất',
              onPressed: _logout,
            ),
          ],
        ),
        Expanded(child: _list()),
      ],
    );
  }

  /// Đơn "ma" cho skeleton.
  static final _ghost = OrderModel(
    id: 'ghost0000',
    customerName: 'Đang tải',
    shippingAddress: 'Đang tải',
    totalAmount: 12000000,
    status: 'Delivered',
    paymentMethod: 'COD',
    paymentStatus: 'RefundRequested',
    orderDate: DateTime.now().toIso8601String(),
    shippingFee: 15000,
    staffId: '',
    refundReason: 'Hàng lỗi/hư hỏng',
    refundRequestedAt: DateTime.now().toIso8601String(),
  );

  Widget _list() {
    if (_loading) {
      return Skeletonizer(
        effect: ShimmerEffect(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
        ),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter, 14, AppSpacing.gutter, 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => _refundCard(_ghost),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: _orders.isEmpty
          ? _empty()
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter, 14, AppSpacing.gutter, 24),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _refundCard(_orders[i])
                  .animate(delay: AppEffects.staggerStep * i.clamp(0, 6))
                  .fadeIn(
                      duration: AppEffects.durEnter,
                      curve: AppEffects.easeStandard)
                  .moveY(
                    begin: AppEffects.entranceRise,
                    end: 0,
                    duration: AppEffects.durEnter,
                    curve: AppEffects.easeStandard,
                  ),
            ),
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
            child: TvIcon('inbox', size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
          child: Text('Không có yêu cầu hoàn nào',
              style: AppText.body(AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _refundCard(OrderModel o) {
    final busy = _busyId == o.id;
    final time = formatRelativeFromIso(o.refundRequestedAt ?? '');
    return TvCard(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${_shortId(o.id)}',
                  style: AppText.mono(size: 12, color: AppColors.textTertiary)),
              Text('Hoàn ${formatVnd(o.totalAmount)}',
                  style: AppText.price().copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(o.customerName.isEmpty ? 'Khách' : o.customerName,
              style: AppText.h3().copyWith(fontSize: 15)),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Yêu cầu $time', style: AppText.xs(AppColors.textTertiary)),
          ],
          if (o.refundReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lý do', style: AppText.label(AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(o.refundReason,
                style: AppText.body(AppColors.textSecondary)
                    .copyWith(fontSize: 13)),
          ],
          if (o.refundImageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: ColoredBox(
                  color: AppColors.ink900,
                  child: ProductImage(url: o.refundImageUrl),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TvButton(
                  label: 'Duyệt hoàn',
                  size: TvButtonSize.md,
                  fullWidth: true,
                  loading: busy,
                  leadingIcon: const TvIcon('refund', size: 16),
                  onPressed: () => _approve(o),
                ),
              ),
              const SizedBox(width: 10),
              TvButton(
                label: 'Từ chối',
                variant: TvButtonVariant.ghost,
                size: TvButtonSize.md,
                onPressed: busy ? null : () => _reject(o),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
