import 'package:flutter/material.dart';
import 'package:tech_void/data/helpers/auth_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/local_notification_service.dart';
import '../../routing/app_routes.dart';
import '../../widgets/widgets.dart';
import '../staff/staff_orders_screen.dart';
import 'method_screen.dart';
import 'register_screen.dart';

/// Login — email + password (with eye toggle), gradient CTA with a loading
/// spinner, and a register link. Mirrors `LoginScreen.jsx`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService.requestPermission();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || _googleLoading) return;
    // Lối tắt TEST tài khoản Staff (bỏ qua OTP): staff@gmail.com / 123 → vào thẳng trang Staff.
    if (_email.text.trim() == 'staff@gmail.com' && _password.text == '123') {
      apiClient.userRole = 'Staff';
      apiClient.userName = 'Nhân viên';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StaffOrdersScreen()),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final device = await AuthHelper.getDeviceContext();
      final verifyToken = await _auth.login(
        email: _email.text,
        password: _password.text,
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        deviceType: device.deviceType,
        fcmToken: device.fcmToken,
      );
      if (!mounted) return;
      if (verifyToken == null || verifyToken.isEmpty) {
        TvToast.show(
          context,
          'Đăng nhập thất bại: Không nhận được token xác thực.',
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MethodScreen(email: _email.text, verifyToken: verifyToken),
        ),
      );
    } catch (e) {
      if (mounted) {
        TvToast.show(context, 'Đăng nhập thất bại');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSubmit() async {
    if (_googleLoading || _loading) return;

    setState(() => _googleLoading = true);

    try {
      final device = await AuthHelper.getDeviceContext();

      await _auth.googleLogin(
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        deviceType: device.deviceType,
        fcmToken: device.fcmToken,
      );

      if (!mounted) return;

      AppRoutes.enterApp(context);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceAll('Exception:', '').trim();

      TvToast.show(
        context,
        message.isNotEmpty ? message : 'Đăng nhập Google thất bại.',
      );
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.bgBase,
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.1,
            colors: [Color(0x1A00F0FF), Colors.transparent],
            stops: [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        Transform.scale(
                          scale: 1.4,
                          child: const TvLogo(size: TvLogoSize.lg),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'Cửa hàng công nghệ tương lai.\nĐăng nhập để khám phá ưu đãi độc quyền.',
                          textAlign: TextAlign.center,
                          style: AppText.body(
                            AppColors.textSecondary,
                          ).copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 40),
                        const _FieldLabel('Email'),
                        TvInput(
                          controller: _email,
                          leading: const TvIcon('mail'),
                          hintText: 'email@techstore.vn',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        const _FieldLabel('Mật khẩu'),
                        TvInput(
                          controller: _password,
                          leading: const TvIcon('lock'),
                          hintText: '••••••••',
                          obscureText: !_showPassword,
                          trailing: GestureDetector(
                            onTap: () =>
                                setState(() => _showPassword = !_showPassword),
                            child: TvIcon(
                              _showPassword ? 'eye-off' : 'eye',
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => TvToast.show(
                              context,
                              'Tính năng đặt lại mật khẩu đang được phát triển',
                            ),
                            child: Text(
                              'Quên mật khẩu?',
                              style: AppText.sm(AppColors.textAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TvButton(
                          label: 'Đăng nhập',
                          size: TvButtonSize.lg,
                          fullWidth: true,
                          loading: _loading,
                          trailingIcon: const TvIcon('arrow-right', size: 18),
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: AppColors.borderSubtle),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'HOẶC',
                                style: AppText.label().copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: AppColors.borderSubtle),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TvButton(
                          label: 'Đăng nhập bằng Google',
                          variant: TvButtonVariant.ghost,
                          size: TvButtonSize.lg,
                          fullWidth: true,
                          loading: _googleLoading,
                          leadingIcon: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'G',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ),
                          onPressed: _googleSubmit,
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: _RegisterPrompt(
                            onRegister: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// UPPERCASE display field label used across the auth forms.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(), style: AppText.label()),
      ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chưa có tài khoản? ',
            style: AppText.sm().copyWith(fontSize: 13),
          ),
          GestureDetector(
            onTap: onRegister,
            child: Text(
              'Đăng ký ngay',
              style: AppText.sm(
                AppColors.textAccent,
              ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
