import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/saved_address.dart';
import '../../../data/services/address_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/local_profile_service.dart';
import '../../widgets/widgets.dart';
import 'address_book_screen.dart';

/// "Thông tin tài khoản" — gộp thông tin cá nhân (tên/email từ phiên đăng nhập,
/// số điện thoại lưu máy) và Sổ địa chỉ vào một nơi. Vào từ tile ở tab Hồ sơ.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = apiClient.userName ?? 'Bạn';
    final email = apiClient.userEmail ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Thông tin tài khoản',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                18,
                AppSpacing.gutter,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _avatarHeader(name, email),
                const SizedBox(height: 24),
                _sectionLabel('Thông tin cá nhân'),
                const SizedBox(height: 10),
                _personalCard(context, name, email),
                const SizedBox(height: 8),
                Text(
                  'Tên và email lấy từ tài khoản đăng nhập. Số điện thoại được lưu trên máy để điền nhanh khi đặt hàng.',
                  style: AppText.xs(AppColors.textTertiary),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Sổ địa chỉ'),
                const SizedBox(height: 10),
                _addressSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarHeader(String name, String email) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(color: AppColors.accentSoftLine),
          ),
          child: TvIcon('user', size: 32, color: AppColors.textAccent),
        ),
        const SizedBox(height: 12),
        Text(name, style: AppText.h2()),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            style: AppText.body(AppColors.textSecondary).copyWith(fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: AppText.label(AppColors.textPrimary).copyWith(fontSize: 12),
  );

  Widget _personalCard(BuildContext context, String name, String email) {
    return TvCard(
      padding: 4,
      child: Column(
        children: [
          _infoRow(icon: 'user', label: 'Họ và tên', value: name),
          _divider(),
          _infoRow(
            icon: 'mail',
            label: 'Email',
            value: email.isEmpty ? '—' : email,
          ),
          _divider(),
          // Số điện thoại — sửa được (lưu local).
          ValueListenableBuilder<String>(
            valueListenable: LocalProfileService.instance.phone,
            builder: (context, phone, _) => _infoRow(
              icon: 'phone',
              label: 'Số điện thoại',
              value: phone.isEmpty ? 'Chưa cập nhật' : phone,
              muted: phone.isEmpty,
              onEdit: () => _editPhone(context, phone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    color: AppColors.borderSubtle,
    indent: 12,
    endIndent: 12,
  );

  Widget _infoRow({
    required String icon,
    required String label,
    required String value,
    bool muted = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          TvIcon(icon, size: 18, color: AppColors.textAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.xs(AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppText.body(
                    muted ? AppColors.textTertiary : AppColors.textPrimary,
                  ).copyWith(fontSize: 14.5),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: TvIcon('edit', size: 17, color: AppColors.textAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addressSection(BuildContext context) {
    return ValueListenableBuilder<List<SavedAddress>>(
      valueListenable: AddressService.instance.notifier,
      builder: (context, addresses, _) {
        final def = AddressService.instance.defaultAddress;
        return TvCard(
          padding: 4,
          child: Column(
            children: [
              if (addresses.isEmpty)
                _addressTile(
                  context,
                  icon: 'plus',
                  title: 'Thêm địa chỉ giao hàng',
                  subtitle: 'Lưu địa chỉ để đặt hàng nhanh hơn',
                )
              else ...[
                if (def != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TvIcon(
                          'map-pin',
                          size: 18,
                          color: AppColors.textAccent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    def.label,
                                    style: AppText.body().copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Mặc định',
                                      style: AppText.xs(AppColors.textAccent),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                def.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sm(AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                _divider(),
                _addressTile(
                  context,
                  icon: 'map-pin',
                  title: 'Quản lý sổ địa chỉ',
                  subtitle: '${addresses.length} địa chỉ đã lưu',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _addressTile(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return PressableScale(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AddressBookScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            TvIcon(icon, size: 18, color: AppColors.textAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body().copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.xs(AppColors.textTertiary)),
                ],
              ),
            ),
            TvIcon('chevron-right', size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _editPhone(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Số điện thoại', style: AppText.h2().copyWith(fontSize: 18)),
            const SizedBox(height: 14),
            TvInput(
              controller: controller,
              hintText: 'Nhập số điện thoại',
              keyboardType: TextInputType.phone,
              size: TvInputSize.lg,
              leading: TvIcon('phone', size: 18, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            TvButton(
              label: 'Lưu',
              size: TvButtonSize.lg,
              fullWidth: true,
              onPressed: () async {
                await LocalProfileService.instance.setPhone(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  TvToast.show(context, 'Đã lưu số điện thoại.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
