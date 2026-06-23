import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/widgets.dart';

/// Profile tab — placeholder ("đang được phát triển"), mirroring the source app
/// where the Profile tab is not yet built out. A tab page (no Scaffold).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TvAppBar(mode: TvAppBarMode.page, title: 'Hồ sơ'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    child: const TvIcon('user',
                        size: 34, color: AppColors.textAccent),
                  ),
                  const SizedBox(height: 16),
                  Text('Hồ sơ của bạn', style: AppText.h2()),
                  const SizedBox(height: 6),
                  Text(
                    'Tính năng hồ sơ đang được phát triển.',
                    textAlign: TextAlign.center,
                    style: AppText.body(AppColors.textSecondary)
                        .copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
