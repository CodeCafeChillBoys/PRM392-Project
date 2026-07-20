import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/auth_service.dart';
import '../../routing/app_routes.dart';
import '../../widgets/widgets.dart';

/// 6-box OTP input + 02:00 countdown + resend (BE flow screen 4).
/// Mirrors `OtpScreen.jsx`.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email, required this.verifyToken});

  final String email;
  final String verifyToken;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _initialSeconds = 120;

  final _auth = AuthService();
  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  Timer? _timer;
  int _seconds = _initialSeconds;
  bool _verifying = false;

  bool get _filled => _controllers.every((c) => c.text.isNotEmpty);
  String get _code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _initialSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verify() async {
    if (!_filled || _verifying) return;
    setState(() => _verifying = true);
    try {
      await _auth.verifyOtp(verifyToken: widget.verifyToken, code: _code);
      if (!mounted) return;

      AppRoutes.enterApp(context);
    } catch (_) {
      if (mounted) TvToast.show(context, 'Mã OTP không đúng. Thử lại nhé.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text('Nhập mã OTP', style: AppText.h1()).animate().fadeIn(
                    duration: AppEffects.durEnter,
                    curve: AppEffects.easeStandard,
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                        TextSpan(
                          style: AppText.body(
                            AppColors.textSecondary,
                          ).copyWith(fontSize: 14, height: 1.5),
                          children: [
                            const TextSpan(
                              text: 'Mã xác thực 6 số đã được gửi tới\n',
                            ),
                            TextSpan(
                              text: widget.email,
                              style: AppText.mono(
                                size: 13,
                                color: AppColors.textAccent,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: AppEffects.staggerStep)
                      .fadeIn(duration: AppEffects.durEnter)
                      .moveY(
                        begin: AppEffects.entranceRise,
                        end: 0,
                        curve: AppEffects.easeStandard,
                      ),
                  const SizedBox(height: 28),
                  // 6 ô OTP nảy vào lần lượt — nhịp gõ mã.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _otpLength; i++)
                        _otpBox(i)
                            .animate(delay: AppEffects.staggerStep * (2 + i))
                            .fadeIn(duration: AppEffects.durBase)
                            .scaleXY(
                              begin: 0.8,
                              end: 1,
                              duration: AppEffects.durEnter,
                              curve: AppEffects.easeEmphasized,
                            ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(child: _resend())
                      .animate(delay: AppEffects.staggerStep * 8)
                      .fadeIn(duration: AppEffects.durEnter),
                  // Spacer PHẢI là con trực tiếp của Column (không bọc animate).
                  const Spacer(),
                  TvButton(
                    label: 'Xác nhận',
                    size: TvButtonSize.lg,
                    fullWidth: true,
                    loading: _verifying,
                    trailingIcon: const TvIcon('check', size: 18),
                    onPressed: _filled ? _verify : null,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int index) {
    final hasValue = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 58,
      child: Focus(
        onKeyEvent: (_, event) => _onKey(index, event),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasValue ? AppColors.accent : AppColors.borderDefault,
              width: hasValue ? 1.5 : 1,
            ),
            boxShadow: hasValue ? AppEffects.glowAccentSm : null,
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            cursorColor: AppColors.accent,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppText.mono(size: 24, weight: FontWeight.w700),
            decoration: const InputDecoration(
              counterText: '',
              isCollapsed: true,
              border: InputBorder.none,
            ),
            onChanged: (value) => _onChanged(index, value),
          ),
        ),
      ),
    );
  }

  Widget _resend() {
    if (_seconds > 0) {
      return Text.rich(
        TextSpan(
          style: AppText.body(AppColors.textSecondary).copyWith(fontSize: 14),
          children: [
            const TextSpan(text: 'Gửi lại mã sau '),
            TextSpan(
              text: formatCountdown(_seconds),
              style: AppText.mono(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.textAccent,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        _startTimer();
        _auth.requestVerification(VerifyMethod.otp, widget.verifyToken);
      },
      child: Text(
        'Gửi lại mã OTP',
        style: AppText.body(
          AppColors.textAccent,
        ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
