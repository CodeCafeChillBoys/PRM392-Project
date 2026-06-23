import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';

enum ChatFrom { agent, user }

/// Chat message bubble for the support surface. Outbound (user) bubbles use the
/// cyan→violet gradient; inbound (agent) bubbles use a dark surface.
/// Mirrors `components/feedback/ChatBubble.jsx`. (Design-system completeness —
/// the support chat screen is out of the current FE scope.)
class TvChatBubble extends StatelessWidget {
  const TvChatBubble({
    super.key,
    this.from = ChatFrom.agent,
    required this.message,
    this.time,
  });

  final ChatFrom from;
  final String message;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final outbound = from == ChatFrom.user;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return Column(
      crossAxisAlignment:
          outbound ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: outbound ? AppColors.gradientCta : null,
              color: outbound ? null : AppColors.bgElevated,
              border: outbound
                  ? null
                  : Border.all(color: AppColors.borderSubtle),
              boxShadow: outbound ? AppEffects.glowCta : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(outbound ? 16 : 4),
                bottomRight: Radius.circular(outbound ? 4 : 16),
              ),
            ),
            child: Text(
              message,
              style: AppText.body(
                outbound ? AppColors.textOnAccent : AppColors.textPrimary,
              ).copyWith(height: 1.45),
            ),
          ),
        ),
        if (time != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(time!, style: AppText.xs(AppColors.textTertiary).copyWith(fontSize: 10)),
          ),
        ],
      ],
    );
  }
}
