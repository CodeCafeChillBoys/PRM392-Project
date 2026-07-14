import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/widgets.dart';
import 'email_wait_screen.dart';
import 'otp_screen.dart';

/// Choose verification method — Email Link vs OTP (BE flow screen 2).
/// Mirrors `MethodScreen.jsx`.
class MethodScreen extends StatelessWidget {
  const MethodScreen({
    super.key,
    required this.email,
    required this.verifyToken,
  });

  final String email;
  final String verifyToken;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    void choose(VerifyMethod method, Widget next) {
      // Fire the request; navigate straight to the waiting/OTP screen.
      auth.requestVerification(method, verifyToken);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text('Xác thực đăng nhập', style: AppText.h1()),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn một phương thức để hoàn tất bảo mật cho tài khoản của bạn.',
                    style: AppText.body(
                      AppColors.textSecondary,
                    ).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  _MethodCard(
                    primary: true,
                    iconName: 'mail-check',
                    title: 'Xác thực qua Email Link',
                    description:
                        'Gửi một đường link an toàn tới email — bấm để đăng nhập tức thì.',
                    onTap: () => choose(
                      VerifyMethod.emailLink,
                      EmailWaitScreen(email: email, verifyToken: verifyToken),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MethodCard(
                    primary: false,
                    iconName: 'shield-check',
                    title: 'Xác thực qua mã OTP',
                    description: 'Nhập mã 6 số được gửi tới email của bạn.',
                    onTap: () => choose(
                      VerifyMethod.otp,
                      OtpScreen(email: email, verifyToken: verifyToken),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.primary,
    required this.iconName,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool primary;
  final String iconName;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          gradient: primary ? AppColors.gradientCtaSoft : null,
          color: primary ? null : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary ? AppColors.accent : AppColors.borderSubtle,
            width: primary ? 1.5 : 1,
          ),
          boxShadow: primary ? AppEffects.glowAccentSm : AppEffects.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? AppColors.accent : AppColors.bgOverlay,
                borderRadius: BorderRadius.circular(12),
                boxShadow: primary ? AppEffects.glowAccentSm : null,
              ),
              child: TvIcon(
                iconName,
                size: 26,
                color: primary ? AppColors.textOnAccent : AppColors.textAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppText.h2().copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppText.sm().copyWith(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const TvIcon(
              'chevron-right',
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
