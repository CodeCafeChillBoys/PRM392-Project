import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/widgets.dart';
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
  final _email = TextEditingController(text: 'alex.nguyen@techstore.vn');
  final _password = TextEditingController(text: 'techstore123');
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _auth.login(email: _email.text, password: _password.text);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MethodScreen()),
      );
    } catch (e) {
      if (mounted) TvToast.show(context, 'Đăng nhập thất bại. Thử lại nhé.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
                          style: AppText.body(AppColors.textSecondary)
                              .copyWith(fontSize: 14),
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
                            onTap: () => TvToast.show(context,
                                'Tính năng đặt lại mật khẩu đang được phát triển'),
                            child: Text('Quên mật khẩu?',
                                style: AppText.sm(AppColors.textAccent)),
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
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: _RegisterPrompt(
                            onRegister: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
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
          Text('Chưa có tài khoản? ',
              style: AppText.sm().copyWith(fontSize: 13)),
          GestureDetector(
            onTap: onRegister,
            child: Text(
              'Đăng ký ngay',
              style: AppText.sm(AppColors.textAccent)
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
