import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/widgets.dart';

/// Register — "Tạo tài khoản TECH_VOID": họ tên, email, SĐT, mật khẩu ×2.
/// Mirrors `RegisterScreen.jsx`.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _auth.register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      TvToast.show(context, 'Đăng ký thành công! Vui lòng đăng nhập.');
      Navigator.pop(context);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Đăng ký thất bại. Thử lại nhé.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tạo tài khoản TECH_VOID', style: AppText.h1()),
                  const SizedBox(height: 6),
                  Text(
                    'Gia nhập cộng đồng công nghệ ngay hôm nay.',
                    style: AppText.body(
                      AppColors.textSecondary,
                    ).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _Field(
                    label: 'Họ và tên',
                    controller: _name,
                    iconName: 'user',
                    hint: 'Nguyễn Văn A',
                  ),
                  _Field(
                    label: 'Email',
                    controller: _email,
                    iconName: 'mail',
                    hint: 'email@techstore.vn',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _Field(
                    label: 'Số điện thoại',
                    controller: _phone,
                    iconName: 'phone',
                    hint: '090 123 4567',
                    keyboardType: TextInputType.phone,
                  ),
                  _Field(
                    label: 'Mật khẩu',
                    controller: _password,
                    iconName: 'lock',
                    hint: '••••••••',
                    obscure: true,
                  ),
                  _Field(
                    label: 'Nhập lại mật khẩu',
                    controller: _confirm,
                    iconName: 'lock',
                    hint: '••••••••',
                    obscure: true,
                  ),
                  const SizedBox(height: 24),
                  TvButton(
                    label: 'Đăng ký',
                    size: TvButtonSize.lg,
                    fullWidth: true,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: AppText.sm().copyWith(fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Đăng nhập',
                              style: AppText.sm(AppColors.textAccent).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.iconName,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String iconName;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label.toUpperCase(), style: AppText.label()),
          ),
          TvInput(
            controller: controller,
            leading: TvIcon(iconName),
            hintText: hint,
            obscureText: obscure,
            keyboardType: keyboardType,
          ),
        ],
      ),
    );
  }
}
