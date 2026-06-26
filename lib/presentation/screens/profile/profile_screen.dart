import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import 'my_orders_screen.dart';

/// Tab Hồ sơ: thông tin tài khoản + lối vào "Đơn hàng của tôi" + Đăng xuất.
/// Là tab page (không Scaffold riêng — RootShell đã bọc).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showTvConfirm(
      context,
      title: 'Đăng xuất?',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục mua sắm.',
      confirmLabel: 'Đăng xuất',
    );
    if (ok != true) return;
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = apiClient.userName ?? 'Bạn';
    final email = apiClient.userEmail;
    return Column(
      children: [
        const TvAppBar(mode: TvAppBarMode.page, title: 'Hồ sơ'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _header(name, email),
              const SizedBox(height: 24),
              _menuTile(
                icon: 'package',
                label: 'Đơn hàng của tôi',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _menuTile(
                icon: 'log-out',
                label: 'Đăng xuất',
                danger: true,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(String name, String? email) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(color: AppColors.accentSoftLine),
            boxShadow: AppEffects.glowCyanSm,
          ),
          child: const TvIcon('user', size: 34, color: AppColors.textAccent),
        ),
        const SizedBox(height: 14),
        Text(name, style: AppText.h2()),
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(email,
              style:
                  AppText.body(AppColors.textSecondary).copyWith(fontSize: 13)),
        ],
      ],
    );
  }

  Widget _menuTile({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger500 : AppColors.textAccent;
    return PressableScale(
      onTap: onTap,
      child: TvCard(
        padding: 16,
        child: Row(
          children: [
            TvIcon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.body().copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: danger ? AppColors.danger500 : AppColors.textPrimary,
                ),
              ),
            ),
            if (!danger)
              const TvIcon('chevron-right',
                  size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
