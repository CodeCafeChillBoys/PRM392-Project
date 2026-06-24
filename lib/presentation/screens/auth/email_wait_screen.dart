import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_mail_launcher/open_mail_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/auth_service.dart';
import '../../routing/app_routes.dart';
import '../../widgets/widgets.dart';

/// "Kiểm tra email" waiting state (BE flow screen 3). Mirrors `EmailWaitScreen.jsx`.
class EmailWaitScreen extends StatefulWidget {
  const EmailWaitScreen({super.key, required this.email, required this.verifyToken});

  final String email;
  final String verifyToken;

  @override
  State<EmailWaitScreen> createState() => _EmailWaitScreenState();
}

class _EmailWaitScreenState extends State<EmailWaitScreen> {
  final _auth = AuthService();
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Auto-poll the session status every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkStatus(isAuto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus({bool isAuto = false}) async {
    if (_checking) return;
    _checking = true;
    try {
      final approved = await _auth.checkSessionStatus(widget.verifyToken);
      if (approved && mounted) {
        _timer?.cancel();
        AppRoutes.enterApp(context);
      } else if (!approved && !isAuto && mounted) {
        TvToast.show(context, 'Tài khoản chưa được xác nhận. Vui lòng bấm vào link trong email.');
      }
    } catch (e) {
      if (!isAuto && mounted) {
        TvToast.show(context, 'Có lỗi xảy ra: ${e.toString()}');
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(mode: TvAppBarMode.page, onBack: () => Navigator.pop(context)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentSoft,
                              border:
                                  Border.all(color: AppColors.accentSoftLine),
                              boxShadow: AppEffects.glowCyanMd,
                            ),
                            child: const TvIcon('mail-open',
                                size: 42, color: AppColors.textAccent),
                          ),
                          const SizedBox(height: 24),
                          Text('Kiểm tra email của bạn',
                              style: AppText.h1(), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Column(
                              children: [
                                Text(
                                  'Chúng tôi đã gửi link đăng nhập tới',
                                  textAlign: TextAlign.center,
                                  style: AppText.body(AppColors.textSecondary)
                                      .copyWith(fontSize: 14, height: 1.55),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.email,
                                  textAlign: TextAlign.center,
                                  style: AppText.mono(
                                      size: 13, color: AppColors.textAccent),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vui lòng bấm vào link đó để đăng nhập.',
                                  textAlign: TextAlign.center,
                                  style: AppText.body(AppColors.textSecondary)
                                      .copyWith(fontSize: 14, height: 1.55),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TvButton(
                    label: 'Mở ứng dụng Email',
                    size: TvButtonSize.lg,
                    fullWidth: true,
                    leadingIcon: const TvIcon('mail', size: 18),
                    onPressed: () async {
                      if (Platform.isAndroid) {
                        try {
                          const AndroidIntent intent = AndroidIntent(
                            action: 'android.intent.action.MAIN',
                            category: 'android.intent.category.APP_EMAIL',
                          );
                          await intent.launch();
                        } catch (e) {
                          if (context.mounted) {
                            TvToast.show(context, 'Lỗi khi mở ứng dụng Email: ${e.toString()}');
                          }
                        }
                      } else {
                        try {
                          final result = await OpenMailLauncher.openMailApp();
                          if (!context.mounted) return;

                          if (!result.didOpen && !result.canOpen) {
                            TvToast.show(context, 'Không tìm thấy ứng dụng Email nào trên thiết bị.');
                          } else if (!result.didOpen && result.canOpen) {
                            final selectedApp = await OpenMailLauncher.showMailAppPicker(
                              context: context,
                              mailApps: result.options,
                              title: 'Chọn ứng dụng Email',
                              cancelText: 'Hủy',
                            );
                            if (selectedApp != null && context.mounted) {
                              await OpenMailLauncher.openSpecificMailApp(mailApp: selectedApp);
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            TvToast.show(context, 'Lỗi khi mở ứng dụng Email: ${e.toString()}');
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TvButton(
                    label: 'Tôi đã xác nhận link',
                    variant: TvButtonVariant.ghost,
                    size: TvButtonSize.lg,
                    fullWidth: true,
                    leadingIcon: const TvIcon('check', size: 18),
                    onPressed: () => _checkStatus(isAuto: false),
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
}
