import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tech_void/data/helpers/auth_helper.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/local_notification_service.dart';
import '../../routing/app_routes.dart';
import '../../widgets/widgets.dart';
import 'method_screen.dart';
import 'register_screen.dart';

/// Login — premium tech e-commerce (VOID CYAN): logo TECH_VOID nhỏ + tiêu đề
/// "Chào mừng trở lại" + ảnh sản phẩm hero, form nằm trong card trắng bo góc
/// chồng nhẹ lên ảnh. Ít glow, tông cyan / trắng / đen-xanh.
///
/// CHỈ đổi giao diện — toàn bộ logic (email/password → [MethodScreen], Google
/// Sign-In → [AppRoutes.enterApp], quên mật khẩu, đăng ký) giữ nguyên.
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

  // ── Logic đăng nhập (GIỮ NGUYÊN) ─────────────────────────────────────────
  Future<void> _submit() async {
    if (_loading || _googleLoading) return;
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

  void _onForgot() =>
      TvToast.show(context, 'Tính năng đặt lại mật khẩu đang được phát triển');

  void _goRegister() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));

  // ── Giao diện ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    // Hero tính theo chiều cao MÀN (ổn định khi bàn phím mở); phần card tính
    // theo viewport (LayoutBuilder) để luôn phủ trắng tới đáy.
    final statusTop = MediaQuery.paddingOf(context).top;
    final screenH = MediaQuery.sizeOf(context).height;

    return Scaffold(
      // Trắng CÙNG MÀU card → vùng dưới card liền mạch, không còn đường phân
      // cách hay khoảng trống xám lớn.
      backgroundColor: AppColors.bgSurface,
      // resizeToAvoidBottomInset mặc định true + cuộn dưới đây → an bàn phím.
      body: LayoutBuilder(
        builder: (context, viewport) {
          // Hero ~230–250dp trên màn thường, tự co trên màn thấp; hero vẽ luôn
          // phía sau status bar nên cộng thêm statusTop.
          final heroHeight =
              statusTop + ((screenH - statusTop) * 0.28).clamp(188.0, 248.0);
          // Card trải từ (hero − 20) tới ít nhất đáy viewport.
          double cardMinHeight = viewport.maxHeight - heroHeight + 20;
          if (cardMinHeight < 0) cardMinHeight = 0;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Stack(
              children: [
                _LoginHero(height: heroHeight, topInset: statusTop),
                // Card chồng 20dp lên đáy hero — overlap bằng padding-top trong
                // Stack (không Transform) nên không dư khoảng cuộn thừa.
                Padding(
                  padding: EdgeInsets.only(top: heroHeight - 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: cardMinHeight),
                    // IntrinsicHeight chốt cho Column trong card một chiều cao
                    // HỮU HẠN = max(nội dung, minHeight) → Spacer bên trong
                    // hoạt động (đẩy "Đăng ký ngay" xuống đáy card). Màn nhỏ /
                    // bàn phím mở: chiều cao theo nội dung → cuộn, không overflow.
                    child: IntrinsicHeight(child: _buildCard()),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 380.ms, curve: AppEffects.easeStandard),
          );
        },
      ),
    );
  }

  /// Card trắng bo góc trên, chứa toàn bộ form đăng nhập.
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xxl),
        ),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppEffects.shadowLg,
      ),
      // Đáy card cộng safe-area (card giờ chạm đáy màn, không còn footer đệm).
      padding: EdgeInsets.fromLTRB(
        24,
        26,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Email'),
          TvInput(
            controller: _email,
            leading: const TvIcon('mail'),
            hintText: 'email@techstore.vn',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          // Nhãn + "Quên mật khẩu?" cùng hàng (kiểu mẫu B).
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mật khẩu'.toUpperCase(), style: AppText.label()),
                GestureDetector(
                  onTap: _onForgot,
                  child: Text(
                    'Quên mật khẩu?',
                    style: AppText.sm(AppColors.textAccent),
                  ),
                ),
              ],
            ),
          ),
          TvInput(
            controller: _password,
            leading: const TvIcon('lock'),
            hintText: '••••••••',
            obscureText: !_showPassword,
            trailing: GestureDetector(
              onTap: () => setState(() => _showPassword = !_showPassword),
              child: TvIcon(
                _showPassword ? 'eye-off' : 'eye',
                color: AppColors.textTertiary,
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
              Expanded(child: Divider(color: AppColors.borderSubtle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'HOẶC',
                  style: AppText.label().copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.borderSubtle)),
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
          const SizedBox(height: 22),
          // Spacer nuốt phần cao dư (card đã kéo tới đáy màn) → "Đăng ký ngay"
          // nằm sát đáy card, cách nav bar bằng padding đáy (24 + safe-area).
          // Màn nhỏ: Spacer = 0, gap 22 phía trên vẫn giữ, card cuộn bình thường.
          const Spacer(),
          _RegisterPrompt(onRegister: _goRegister),
        ],
      ),
    );
  }
}

/// Hero "quảng cáo" liền khối: nền trắng-xanh nhạt phủ TOÀN bề rộng (cả sau
/// status bar), ảnh sản phẩm neo mép phải và hơi tràn ra ngoài, phía trên ảnh
/// phủ một [LinearGradient] cùng màu nền — đặc ở trái, mờ dần thành trong suốt
/// về phải — để xoá đường biên dọc: ảnh TAN vào nền thay vì thành khối chữ
/// nhật đặt cạnh text. Lời chào nằm trái, vẽ trên gradient nên luôn dễ đọc.
class _LoginHero extends StatelessWidget {
  const _LoginHero({required this.height, required this.topInset});

  /// Tổng chiều cao hero (đã gồm vùng status bar phía sau).
  final double height;

  /// Chiều cao status bar — text và ảnh né xuống dưới vùng này.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final imageWidth = w * 0.64; // ảnh chiếm ~64% bề rộng hero
          final bleed = w * 0.04; // phần tràn ra ngoài mép phải

          return Stack(
            children: [
              // Nền hero phủ toàn bề rộng.
              Positioned.fill(child: ColoredBox(color: AppColors.bgBase)),
              // Ảnh neo phải, hơi tràn khỏi mép màn (bị cắt tại mép = bleed).
              Positioned(
                top: topInset + 4,
                bottom: 0,
                right: -bleed,
                width: imageWidth + bleed,
                child: Image.asset(
                  'assets/images/tech_login_hero.png',
                  fit: BoxFit.cover,
                  // Crop lệch phải-dưới: ưu tiên tai nghe + laptop + GPU
                  // (điện thoại ở rìa trái ảnh gốc nằm dưới lớp gradient đặc).
                  alignment: const Alignment(0.3, 0.5),
                  errorBuilder: (_, _, _) => _fallback(),
                ),
              ),
              // Gradient cùng màu nền: đặc bên trái → trong suốt bên phải —
              // xoá biên dọc của ảnh, hero liền một khối.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.bgBase,
                        AppColors.bgBase,
                        AppColors.bgBase.withValues(alpha: 0),
                      ],
                      stops: const [0.0, 0.46, 0.82],
                    ),
                  ),
                ),
              ),
              // Lời chào bên trái (trên lớp gradient).
              Positioned(
                left: 24,
                top: topInset + 10,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w * 0.56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TvLogo(size: TvLogoSize.sm),
                      const SizedBox(height: 18),
                      Text(
                        'Chào mừng trở lại',
                        style: AppText.display().copyWith(
                          fontSize: 26,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để tiếp tục mua sắm cùng TECH_VOID.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          AppColors.textSecondary,
                        ).copyWith(fontSize: 13.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Fallback khi thiếu file ảnh — nền gradient cyan + logo mờ (không vỡ layout).
  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentSoft, AppColors.bgSurface],
        ),
      ),
      child: const Center(
        child: Opacity(opacity: 0.5, child: TvLogo(size: TvLogoSize.md)),
      ),
    );
  }
}

/// Nhãn field IN HOA dùng chung trong các form auth.
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
