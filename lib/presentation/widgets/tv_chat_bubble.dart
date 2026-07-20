import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
      crossAxisAlignment: outbound
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            // VOID LUXE: user bubble = goldSoft wash + hairline gold (tiết chế
            // thay gradient full + glow thời neon); agent = surface + hairline.
            decoration: BoxDecoration(
              color: outbound ? AppColors.goldSoft : AppColors.bgElevated,
              border: Border.all(
                color: outbound
                    ? AppColors.goldSoftLine
                    : AppColors.borderSubtle,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(outbound ? 16 : 4),
                bottomRight: Radius.circular(outbound ? 4 : 16),
              ),
            ),
            // USER: Text thường. AGENT: markdown nhẹ (**đậm**, "- "/"* " → "•").
            child: outbound
                ? Text(
                    message,
                    style: AppText.body(
                      AppColors.textPrimary,
                    ).copyWith(height: 1.45),
                  )
                : _AgentMarkdown(
                    message,
                    AppText.body(AppColors.textPrimary).copyWith(height: 1.45),
                  ),
          ),
        ),
        if (time != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              time!,
              style: AppText.xs(AppColors.textTertiary).copyWith(fontSize: 10),
            ),
          ),
        ],
      ],
    );
  }
}

/// Markdown NHẸ cho bong bóng agent (KHÔNG dùng package):
///  * `**đậm**` → in đậm.
///  * dòng mở đầu `- ` hoặc `* ` → gạch đầu dòng "•".
///  * dòng trống → khoảng cách đoạn; còn lại giữ nguyên.
///
/// PRIVATE — không export vào barrel; bong bóng user vẫn dùng [Text] thường.
class _AgentMarkdown extends StatelessWidget {
  const _AgentMarkdown(this.message, this.base);

  final String message;
  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    final lines = message.split('\n');
    final children = <Widget>[];
    for (final line in lines) {
      if (line.trim().isEmpty) {
        // Dòng trống = nhịp xuống dòng của bot (giữ khoảng cách đoạn).
        children.add(const SizedBox(height: 6));
        continue;
      }
      final trimmed = line.trimLeft();
      final isBullet = trimmed.startsWith('- ') || trimmed.startsWith('* ');
      final text = isBullet ? '•  ${trimmed.substring(2)}' : line;
      children.add(
        Text.rich(TextSpan(children: _parseBold(text)), style: base),
      );
    }
    if (children.length == 1) return children.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Tách `**đậm**` thành các [TextSpan]; phần ngoài kế thừa [base], phần trong
  /// chỉ override sang đậm. `**` lẻ (không đóng) được giữ nguyên như chữ thường.
  List<InlineSpan> _parseBold(String text) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var index = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > index) {
        spans.add(TextSpan(text: text.substring(index, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      index = m.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    if (spans.isEmpty) spans.add(TextSpan(text: text));
    return spans;
  }
}
