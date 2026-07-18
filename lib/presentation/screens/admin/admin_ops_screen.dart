import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/device_info.dart';
import '../../../data/models/login_session_info.dart';
import '../../../data/services/admin_service.dart';
import '../../widgets/widgets.dart';
import 'admin_common.dart';

/// Hai khu giám sát vận hành.
enum _OpsTab { sessions, devices }

/// Khu Admin — Vận hành: giám sát phiên đăng nhập gần đây và thiết bị đã ghi
/// nhận. Dữ liệu chỉ-đọc, KHÔNG lộ OtpCode/token/FcmToken (BE đã lọc ở DTO).
/// Tab-page: tự có app bar, shell lo Scaffold + bottom nav.
class AdminOpsScreen extends StatefulWidget {
  const AdminOpsScreen({super.key});

  @override
  State<AdminOpsScreen> createState() => _AdminOpsScreenState();
}

class _AdminOpsScreenState extends State<AdminOpsScreen> {
  final _service = AdminService();

  List<LoginSessionInfo> _sessions = [];
  List<DeviceInfo> _devices = [];
  bool _loading = true;
  _OpsTab _tab = _OpsTab.sessions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchSessions(),
        _service.fetchDevices(),
      ]);
      if (mounted) {
        setState(() {
          _sessions = results[0] as List<LoginSessionInfo>;
          _devices = results[1] as List<DeviceInfo>;
        });
      }
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được dữ liệu vận hành.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.page,
          title: 'Vận hành',
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
              TvTab(_OpsTab.sessions.name, 'Phiên (${_sessions.length})'),
              TvTab(_OpsTab.devices.name, 'Thiết bị (${_devices.length})'),
            ],
            onChanged: (v) => setState(
                () => _tab = _OpsTab.values.firstWhere((t) => t.name == v)),
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
          itemCount: 7,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => _sessionCard(const LoginSessionInfo(
            id: 'ghost',
            userId: 'ghost',
            customerName: 'Đang tải phiên',
            customerEmail: 'loading@techvoid.vn',
            status: 'Approved',
            deviceName: 'Android · Pixel',
            createdAt: '',
          )),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: _tab == _OpsTab.sessions ? _sessionsList() : _devicesList(),
    );
  }

  Widget _sessionsList() {
    if (_sessions.isEmpty) return _empty('Chưa có phiên đăng nhập nào');
    return ListView.separated(
      key: const ValueKey('sessions'),
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 24),
      itemCount: _sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _sessionCard(_sessions[i])
          .animate(delay: AppEffects.staggerStep * i.clamp(0, 6))
          .fadeIn(duration: AppEffects.durEnter, curve: AppEffects.easeStandard)
          .moveY(
              begin: AppEffects.entranceRise,
              end: 0,
              curve: AppEffects.easeStandard),
    );
  }

  Widget _devicesList() {
    if (_devices.isEmpty) return _empty('Chưa ghi nhận thiết bị nào');
    return ListView.separated(
      key: const ValueKey('devices'),
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 24),
      itemCount: _devices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _deviceCard(_devices[i])
          .animate(delay: AppEffects.staggerStep * i.clamp(0, 6))
          .fadeIn(duration: AppEffects.durEnter, curve: AppEffects.easeStandard)
          .moveY(
              begin: AppEffects.entranceRise,
              end: 0,
              curve: AppEffects.easeStandard),
    );
  }

  Widget _sessionCard(LoginSessionInfo s) {
    final name = s.customerName.isEmpty ? 'Khách' : s.customerName;
    final when = formatRelativeFromIso(s.createdAt);
    final device = [s.deviceName, s.deviceType]
        .where((e) => e.isNotEmpty)
        .join(' · ');
    return TvCard(
      padding: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong().copyWith(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              _SessionStatusPill(s),
            ],
          ),
          if (s.customerEmail.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(s.customerEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.xs(AppColors.textTertiary)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TvIcon('monitor-smartphone',
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(device.isEmpty ? 'Thiết bị không rõ' : device,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.xs(AppColors.textSecondary)),
              ),
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

  Widget _deviceCard(DeviceInfo d) {
    final name = d.deviceName.isEmpty ? 'Thiết bị không tên' : d.deviceName;
    final updated = formatRelativeFromIso(d.updatedAt);
    return TvCard(
      padding: 12,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgOverlay,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: TvIcon('smartphone', size: 18, color: AppColors.textAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong().copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (d.deviceType.isNotEmpty) d.deviceType,
                    if (updated.isNotEmpty) 'Cập nhật $updated',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.xs(AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String message) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
            child: TvIcon('activity', size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
          child:
              Text(message, style: AppText.body(AppColors.textSecondary)),
        ),
      ],
    );
  }
}

/// Pill trạng thái phiên: Approved=success · Pending=warning · Expired/khác=
/// neutral. Phiên còn "Approved" nhưng đã quá hạn hiển thị như Expired.
class _SessionStatusPill extends StatelessWidget {
  const _SessionStatusPill(this.session);
  final LoginSessionInfo session;

  @override
  Widget build(BuildContext context) {
    final expired = session.isExpired;
    final status = expired ? 'Expired' : session.status;
    final (label, variant) = switch (status) {
      'Approved' => ('Hoạt động', TvBadgeVariant.success),
      'Pending' => ('Chờ xác thực', TvBadgeVariant.warning),
      'Expired' => ('Hết hạn', TvBadgeVariant.neutral),
      _ => (status.isEmpty ? 'Không rõ' : status, TvBadgeVariant.neutral),
    };
    return TvBadge(label, variant: variant);
  }
}
