import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/chat_service.dart';
import '../../widgets/widgets.dart';

/// 1 dòng chat — user hoặc bot, kèm mốc thời gian gửi.
class _ChatEntry {
  _ChatEntry({required this.text, required this.fromUser, required this.at});
  final String text;
  final bool fromUser;
  final DateTime at;
}

/// Màn chat AI "Trợ lý TechStore" (`POST /api/Chat`, Gemini phía BE) — pushed
/// full-screen từ icon bot trên app bar `ProductListScreen`. BE không lưu
/// lịch sử hội thoại nên mỗi tin nhắn được gửi độc lập.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.seedQuestion});

  /// Câu hỏi mồi — mở chat từ nút "Chat hỗ trợ" ở trang sản phẩm sẽ hỏi sẵn
  /// về đúng sản phẩm đó (hỗ trợ theo ngữ cảnh, khách không phải gõ lại).
  final String? seedQuestion;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _service = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatEntry> _messages = [];
  bool _waiting = false;
  double _lastBottomInset = 0;

  static const _suggestions = [
    'Shop đang có những sản phẩm gì?',
    'Phí ship tính thế nào?',
    'iPhone còn hàng không?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messages.add(_ChatEntry(
      text: 'Xin chào! Mình là trợ lý AI của TechStore. Bạn cần tìm sản phẩm '
          'hay có câu hỏi gì cứ nhắn mình nhé 🤖',
      fromUser: false,
      at: DateTime.now(),
    ));
    // Mở từ trang sản phẩm → tự gửi câu hỏi mồi sau khi màn dựng xong.
    final seed = widget.seedQuestion?.trim();
    if (seed != null && seed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(seed));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final inset =
        WidgetsBinding.instance.platformDispatcher.implicitView?.viewInsets.bottom ?? 0;
    // Bàn phím vừa mở → viewport co lại, cuộn theo để tin mới nhất không bị che.
    if (inset > _lastBottomInset) _scrollToBottom();
    _lastBottomInset = inset;
  }

  bool get _showSuggestions => !_messages.any((m) => m.fromUser);

  Future<void> _send([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _waiting) return;
    setState(() {
      _messages.add(_ChatEntry(text: text, fromUser: true, at: DateTime.now()));
      if (presetText == null) _controller.clear();
      _waiting = true;
    });
    _scrollToBottom();
    try {
      final reply = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages
            .add(_ChatEntry(text: reply, fromUser: false, at: DateTime.now()));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatEntry(
          text: 'Xin lỗi, mình đang mất kết nối. Bạn thử gửi lại nhé.',
          fromUser: false,
          at: DateTime.now(),
        ));
        if (presetText == null && _controller.text.trim().isEmpty) {
          _controller.text = text;
        }
      });
    } finally {
      if (mounted) setState(() => _waiting = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Trợ lý TechStore',
            onBack: () => Navigator.of(context).pop(),
            // Badge AI cyan — một trong các "signal survivor" của VOID LUXE.
            leading: const Padding(
              padding: EdgeInsets.only(left: 6, right: 2),
              child: TvBadge('AI', variant: TvBadgeVariant.glass),
            ),
          ),
          Expanded(child: _buildList()),
          if (_showSuggestions) _buildSuggestions(),
          SafeArea(top: false, child: _buildInputBar()),
        ],
      ),
    );
  }

  Widget _buildList() {
    final itemCount = _messages.length + (_waiting ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (_waiting && i == itemCount - 1) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Align(alignment: Alignment.centerLeft, child: _TypingBubble()),
          );
        }
        final m = _messages[i];
        // Key ổn định theo index để entrance chỉ chạy 1 lần cho bubble MỚI
        // (không replay toàn bộ lịch sử mỗi lần setState).
        return KeyedSubtree(
          key: ValueKey('msg-$i'),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TvChatBubble(
              from: m.fromUser ? ChatFrom.user : ChatFrom.agent,
              message: m.text,
              time: _fmtTime(m.at),
            )
                .animate()
                .fadeIn(
                  duration: const Duration(milliseconds: 250),
                  curve: AppEffects.easeStandard,
                )
                .moveY(begin: 12, end: 0, curve: AppEffects.easeStandard)
                .scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1, 1),
                  curve: AppEffects.easeEmphasized,
                ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final s in _suggestions)
            _SuggestionChip(label: s, onTap: () => _send(s)),
        ]
            .animate(interval: AppEffects.staggerStep)
            .fadeIn(
              duration: AppEffects.durEnter,
              curve: AppEffects.easeStandard,
            )
            .moveY(
              begin: 12,
              end: 0,
              duration: AppEffects.durEnter,
              curve: AppEffects.easeStandard,
            ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TvInput(
              controller: _controller,
              hintText: 'Nhập câu hỏi...',
              textInputAction: TextInputAction.send,
              onEditingComplete: () {
                if (_waiting) {
                  TvToast.show(context, 'Chờ trợ lý trả lời xong đã nhé.');
                } else {
                  _send();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          TvIconButton(
            icon: const TvIcon('send'),
            variant: TvIconButtonVariant.accent,
            tooltip: 'Gửi',
            enabled: !_waiting,
            onPressed: () => _send(),
          ),
        ],
      ),
    );
  }
}

/// Chip gợi ý câu hỏi — tap gửi luôn, style mirror `_CategoryChip` (product list).
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.95,
      haptic: PressHaptic.selection,
      onTap: onTap,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Text(
          label,
          style: AppText.label(AppColors.textSecondary)
              .copyWith(fontSize: 12.5, letterSpacing: 0.25),
        ),
      ),
    );
  }
}

/// Bong bóng "đang gõ" phía bot — khung giống [TvChatBubble] agent, chứa
/// [_TypingDots] thay vì text.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

/// 3 chấm nhấp nháy lần lượt báo hiệu bot đang trả lời.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (var i = 0; i < 3; i++) _dot(i)],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    final t = (_controller.value - index * 0.2) % 1.0;
    final opacity = (0.3 + 1.4 * (0.5 - (t - 0.5).abs())).clamp(0.3, 1.0);
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.textAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
