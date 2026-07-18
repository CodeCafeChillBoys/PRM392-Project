import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/user_summary.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/api_client.dart';
import '../../widgets/widgets.dart';
import 'admin_common.dart';

/// Bộ lọc người dùng theo role — áp client-side trên danh sách đã tải.
enum _RoleFilter {
  all('all', 'Tất cả'),
  customer('Customer', 'Khách'),
  staff('Staff', 'Staff'),
  admin('Admin', 'Admin');

  const _RoleFilter(this.value, this.label);
  final String value;
  final String label;

  bool accepts(UserSummary u) => this == all || u.role == value;
}

/// Khu Admin — Người dùng: xem/tìm/lọc theo role và đổi role (Customer/Staff/
/// Admin) qua đường an toàn `PUT /api/users/{id}/role`. Chặn admin tự hạ quyền
/// chính mình. Tab-page: tự có app bar, shell lo Scaffold + bottom nav.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _service = AdminService();
  final _searchCtrl = TextEditingController();

  List<UserSummary> _users = [];
  bool _loading = true;
  String _query = '';
  _RoleFilter _filter = _RoleFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.fetchUsers();
      if (mounted) setState(() => _users = list);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được danh sách người dùng.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserSummary> get _visible {
    final q = _query.trim().toLowerCase();
    return _users.where((u) {
      final matchRole = _filter.accepts(u);
      final matchQuery = q.isEmpty ||
          '${u.fullName} ${u.email} ${u.phoneNumber}'.toLowerCase().contains(q);
      return matchRole && matchQuery;
    }).toList();
  }

  int get _adminCount => _users.where((u) => u.isAdmin).length;

  Future<void> _openRoleSheet(UserSummary user) async {
    final isSelf = apiClient.userId != null && user.id == apiClient.userId;
    final newRole = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RoleSheet(user: user, isSelf: isSelf),
    );
    if (newRole == null || newRole == user.role || !mounted) return;

    final ok = await showTvConfirm(
      context,
      title: 'Đổi quyền người dùng',
      message:
          'Đặt "${user.fullName.isEmpty ? user.email : user.fullName}" thành '
          '${_roleLabel(newRole)}? Người dùng sẽ nhận quyền mới ở lần đăng nhập sau.',
      confirmLabel: 'Đổi quyền',
    );
    if (ok != true || !mounted) return;

    try {
      final updated = await _service.changeUserRole(user.id, newRole);
      if (!mounted) return;
      setState(() {
        final i = _users.indexWhere((u) => u.id == user.id);
        if (i != -1) _users[i] = updated;
      });
      TvToast.show(context, 'Đã đổi quyền thành ${_roleLabel(newRole)}.');
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không đổi được quyền. Thử lại sau.');
    }
  }

  static String _roleLabel(String role) => switch (role) {
        'Admin' => 'Quản trị',
        'Staff' => 'Nhân viên',
        _ => 'Khách hàng',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.page,
          title: 'Người dùng',
          actions: AdminActions.appBar(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TvTabs(
            distribute: true,
            value: _filter.value,
            tabs: [for (final r in _RoleFilter.values) TvTab(r.value, r.label)],
            onChanged: (v) => setState(() => _filter =
                _RoleFilter.values.firstWhere((r) => r.value == v)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TvInput(
            controller: _searchCtrl,
            leading: const TvIcon('search'),
            hintText: 'Tìm theo tên, email, SĐT...',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 10),
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
              EdgeInsets.fromLTRB(AppSpacing.gutter, 6, AppSpacing.gutter, 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => _userCard(const UserSummary(
            id: 'ghost',
            fullName: 'Người dùng đang tải',
            email: 'loading@techvoid.vn',
            phoneNumber: '0900000000',
            role: 'Customer',
          )),
        ),
      );
    }
    final items = _visible;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: items.isEmpty
          ? _empty()
          : ListView.separated(
              key: ValueKey('${_filter.value}|$_query'),
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter, 6, AppSpacing.gutter, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _userCard(items[i])
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

  Widget _userCard(UserSummary u) {
    final name = u.fullName.isEmpty ? 'Chưa đặt tên' : u.fullName;
    final joined = formatRelativeFromIso(u.createdAt);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openRoleSheet(u),
      child: TvCard(
        padding: 12,
        child: Row(
          children: [
            _avatar(u),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyStrong().copyWith(fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(u.role),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(u.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.xs(AppColors.textTertiary)),
                  if (u.phoneNumber.isNotEmpty || joined.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (u.phoneNumber.isNotEmpty) u.phoneNumber,
                        if (joined.isNotEmpty) 'Tham gia $joined',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.xs(AppColors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            TvIcon('chevron-right', size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _avatar(UserSummary u) {
    final source = u.fullName.isNotEmpty ? u.fullName : u.email;
    final initial = source.isNotEmpty ? source.substring(0, 1) : '?';
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentSoftLine),
      ),
      child: Text(
        initial.toUpperCase(),
        style: AppText.h3().copyWith(color: AppColors.textAccent, fontSize: 18),
      ),
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(child: TvIcon('users', size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
          child: Text('Không có người dùng khớp bộ lọc',
              style: AppText.body(AppColors.textSecondary)),
        ),
        if (_adminCount > 0) ...[
          const SizedBox(height: 6),
          Center(
            child: Text('$_adminCount quản trị viên trong hệ thống',
                style: AppText.xs(AppColors.textTertiary)),
          ),
        ],
      ],
    );
  }
}

/// Badge role dùng chung trong khu Admin: Admin=gradient · Staff=accent ·
/// Customer=neutral.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);
  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (role) {
      'Admin' => ('Admin', TvBadgeVariant.gradient),
      'Staff' => ('Staff', TvBadgeVariant.accent),
      _ => ('Khách', TvBadgeVariant.neutral),
    };
    return TvBadge(label, variant: variant);
  }
}

/// Bottom sheet đổi role — chọn qua [TvSegmentedControl]. Chặn admin tự hạ
/// quyền mình ([isSelf]): khoá 2 role thấp hơn, chỉ cho giữ Admin.
class _RoleSheet extends StatefulWidget {
  const _RoleSheet({required this.user, required this.isSelf});

  final UserSummary user;
  final bool isSelf;

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  late String _role = widget.user.role;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppEffects.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đổi quyền', style: AppText.h3()),
            const SizedBox(height: 4),
            Text(
              widget.user.fullName.isEmpty
                  ? widget.user.email
                  : widget.user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sm(AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TvSegmentedControl(
              value: _role,
              options: const [
                TvSegment('Customer', 'Khách'),
                TvSegment('Staff', 'Staff'),
                TvSegment('Admin', 'Admin'),
              ],
              onChanged: (v) {
                // Không cho admin tự hạ quyền chính mình xuống dưới Admin.
                if (widget.isSelf && v != 'Admin') {
                  TvToast.show(context,
                      'Không thể tự hạ quyền tài khoản của chính bạn.');
                  return;
                }
                setState(() => _role = v);
              },
            ),
            if (widget.isSelf) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  TvIcon('shield-alert',
                      size: 14, color: AppColors.warning500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Đây là tài khoản của bạn — không thể tự hạ quyền.',
                        style: AppText.xs(AppColors.warning500)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TvButton(
                    label: 'Đóng',
                    variant: TvButtonVariant.ghost,
                    size: TvButtonSize.md,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TvButton(
                    label: 'Chọn',
                    size: TvButtonSize.md,
                    fullWidth: true,
                    onPressed: _role == widget.user.role
                        ? null
                        : () => Navigator.of(context).pop(_role),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
