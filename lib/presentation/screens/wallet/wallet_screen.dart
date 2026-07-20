import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/wallet.dart';
import '../../../data/models/wallet_transaction.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/wallet_service.dart';
import '../../widgets/widgets.dart';

/// Màn Ví — số dư + lịch sử giao dịch + nạp (VNPay) + rút (về ngân hàng).
/// Vào từ tile "Ví của tôi" ở tab Hồ sơ. Gọi `WalletController` (cần token).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  static const int _pageSize = 20;

  final _service = walletService;
  final _scroll = ScrollController();

  Wallet? _wallet;
  final List<WalletTransaction> _txns = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _end = false;
  String? _error;

  /// Bật khi vừa mở cổng VNPay để nạp — app trở lại foreground thì tự làm mới
  /// ví (không có order để poll như checkout, nên dựa vào lifecycle + kéo mới).
  bool _awaitingTopUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingTopUp) {
      _awaitingTopUp = false;
      _load();
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchWallet(),
        _service.fetchTransactions(skip: 0, take: _pageSize),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Wallet;
        _txns
          ..clear()
          ..addAll(results[1] as List<WalletTransaction>);
        _end = _txns.length < _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _msg(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _end || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _service.fetchTransactions(
        skip: _txns.length,
        take: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _txns.addAll(more);
        if (more.length < _pageSize) _end = true;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // ── Nạp tiền ──────────────────────────────────────────────────────────
  Future<void> _onTopUp() async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AmountSheet(),
    );
    if (amount == null || !mounted) return;
    try {
      final url = await _service.topUp(amount);
      if (url.isEmpty) {
        if (mounted) TvToast.show(context, 'Không tạo được liên kết nạp ví.');
        return;
      }
      _awaitingTopUp = true;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        TvToast.show(
          context,
          'Hoàn tất thanh toán trên VNPay rồi quay lại — ví sẽ tự cập nhật.',
        );
      }
    } catch (e) {
      _awaitingTopUp = false;
      if (mounted) TvToast.show(context, _msg(e));
    }
  }

  // ── Rút tiền ──────────────────────────────────────────────────────────
  Future<void> _onWithdraw() async {
    final balance = _wallet?.balance ?? 0;
    final input = await showModalBottomSheet<_WithdrawInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(balance: balance),
    );
    if (input == null || !mounted) return;
    try {
      await _service.withdraw(
        amount: input.amount,
        bankName: input.bankName,
        bankAccountNumber: input.accountNumber,
        accountHolderName: input.holderName,
      );
      if (!mounted) return;
      TvToast.show(
        context,
        'Rút tiền thành công. Tiền đang về tài khoản của bạn.',
      );
      _load();
    } catch (e) {
      if (mounted) TvToast.show(context, _msg(e));
    }
  }

  String _msg(Object e) {
    final s = e is ApiException ? e.message : e.toString();
    return s.isEmpty ? 'Có lỗi xảy ra, thử lại nhé.' : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Ví của tôi',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.textAccent),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: _balanceCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                20,
                AppSpacing.gutter,
                4,
              ),
              child: TvSectionHeader(
                icon: TvIcon('receipt', size: 18, color: AppColors.textAccent),
                title: 'Lịch sử giao dịch',
              ),
            ),
          ),
          if (_error != null)
            SliverToBoxAdapter(child: _errorBox(_error!))
          else if (_txns.isEmpty)
            SliverToBoxAdapter(child: _emptyBox())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                6,
                AppSpacing.gutter,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverList.separated(
                itemCount: _txns.length + (_end ? 0 : 1),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i >= _txns.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return _txnRow(_txns[i]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    final w = _wallet;
    final updated = w?.updatedAt;
    return Container(
      margin: EdgeInsets.fromLTRB(AppSpacing.gutter, 16, AppSpacing.gutter, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCta,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppEffects.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TvIcon('wallet', size: 18, color: AppColors.textOnAccent),
              const SizedBox(width: 8),
              Text(
                'Số dư ví',
                style: AppText.label(
                  AppColors.textOnAccent,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatVnd(w?.balance ?? 0),
            style: AppText.display().copyWith(
              fontSize: 32,
              color: AppColors.textOnAccent,
            ),
          ),
          if (updated != null) ...[
            const SizedBox(height: 4),
            Text(
              'Cập nhật ${formatRelativeTime(updated)}',
              style: AppText.xs(AppColors.textOnAccent.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TvButton(
                  label: 'Nạp tiền',
                  variant: TvButtonVariant.accent,
                  size: TvButtonSize.md,
                  fullWidth: true,
                  leadingIcon: const TvIcon('plus-circle', size: 18),
                  onPressed: _onTopUp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TvButton(
                  label: 'Rút tiền',
                  variant: TvButtonVariant.secondary,
                  size: TvButtonSize.md,
                  fullWidth: true,
                  leadingIcon: const TvIcon('arrow-up-right', size: 18),
                  onPressed: _onWithdraw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _txnRow(WalletTransaction t) {
    final credit = t.isCredit;
    final sign = credit ? '+' : '−';
    final amountColor = credit ? AppColors.success500 : AppColors.textPrimary;
    return TvCard(
      padding: 12,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentSoft,
              border: Border.all(color: AppColors.accentSoftLine),
            ),
            child: TvIcon(t.iconKey, size: 18, color: AppColors.textAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.typeLabel,
                  style: AppText.body().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.description?.isNotEmpty == true
                      ? t.description!
                      : formatRelativeTime(t.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.xs(AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${formatVnd(t.amount)}',
                style: AppText.body(
                  amountColor,
                ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              _statusChip(t.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    if (s == 'completed') {
      return TvBadge('Thành công', variant: TvBadgeVariant.success);
    }
    if (s == 'failed' || s == 'cancelled') {
      return TvBadge('Thất bại', variant: TvBadgeVariant.danger);
    }
    return TvBadge('Đang xử lý', variant: TvBadgeVariant.warning);
  }

  Widget _emptyBox() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
    child: Column(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(color: AppColors.accentSoftLine),
          ),
          child: TvIcon('receipt', size: 30, color: AppColors.textAccent),
        ),
        const SizedBox(height: 14),
        Text(
          'Chưa có giao dịch nào',
          style: AppText.h2().copyWith(fontSize: 17),
        ),
        const SizedBox(height: 6),
        Text(
          'Nạp tiền hoặc thanh toán đơn bằng ví để bắt đầu.',
          textAlign: TextAlign.center,
          style: AppText.sm(AppColors.textTertiary),
        ),
      ],
    ),
  );

  Widget _errorBox(String msg) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
    child: Column(
      children: [
        TvIcon('alert-circle', size: 34, color: AppColors.danger500),
        const SizedBox(height: 12),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: AppText.body(AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 160,
          child: TvButton(
            label: 'Thử lại',
            variant: TvButtonVariant.secondary,
            onPressed: _load,
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// Sheet chọn số tiền nạp — preset nhanh + tự nhập. Trả về số tiền (double).
// ═══════════════════════════════════════════════════════════════════════
class _AmountSheet extends StatefulWidget {
  const _AmountSheet();

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  static const _presets = [100000.0, 200000.0, 500000.0, 1000000.0];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _parse() {
    final digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  void _submit(double amount) {
    if (amount < 10000) {
      TvToast.show(context, 'Số tiền nạp tối thiểu 10.000₫.');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Nạp tiền vào ví',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presets
              .map(
                (p) =>
                    _PresetChip(label: formatVnd(p), onTap: () => _submit(p)),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Hoặc nhập số tiền khác',
          style: AppText.xs(AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        TvInput(
          controller: _controller,
          hintText: 'Ví dụ 250.000',
          keyboardType: TextInputType.number,
          size: TvInputSize.lg,
          leading: TvIcon('wallet', size: 18, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),
        TvButton(
          label: 'Tiếp tục nạp qua VNPay',
          size: TvButtonSize.lg,
          fullWidth: true,
          leadingIcon: const TvIcon('arrow-right', size: 18),
          onPressed: () {
            final amount = _parse();
            if (amount == null) {
              TvToast.show(context, 'Nhập số tiền cần nạp nhé.');
              return;
            }
            _submit(amount);
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Sheet rút tiền — số tiền + thông tin ngân hàng. Trả về [_WithdrawInput].
// ═══════════════════════════════════════════════════════════════════════
class _WithdrawInput {
  const _WithdrawInput({
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.holderName,
  });
  final double amount;
  final String bankName;
  final String accountNumber;
  final String holderName;
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.balance});
  final double balance;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amount = TextEditingController();
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _holder = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _bank.dispose();
    _account.dispose();
    _holder.dispose();
    super.dispose();
  }

  void _submit() {
    final digits = _amount.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(digits) ?? 0;
    if (amount < 50000) {
      TvToast.show(context, 'Số tiền rút tối thiểu 50.000₫.');
      return;
    }
    if (amount > widget.balance) {
      TvToast.show(context, 'Số dư không đủ để rút.');
      return;
    }
    if (_bank.text.trim().isEmpty ||
        _account.text.trim().isEmpty ||
        _holder.text.trim().isEmpty) {
      TvToast.show(context, 'Điền đủ thông tin ngân hàng nhé.');
      return;
    }
    Navigator.of(context).pop(
      _WithdrawInput(
        amount: amount,
        bankName: _bank.text.trim(),
        accountNumber: _account.text.trim(),
        holderName: _holder.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Rút tiền về ngân hàng',
      children: [
        Text(
          'Số dư khả dụng: ${formatVnd(widget.balance)}',
          style: AppText.sm(AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        TvInput(
          controller: _amount,
          hintText: 'Số tiền rút (tối thiểu 50.000)',
          keyboardType: TextInputType.number,
          size: TvInputSize.lg,
          leading: TvIcon('banknote', size: 18, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 10),
        TvInput(
          controller: _bank,
          hintText: 'Tên ngân hàng (VD Vietcombank)',
          size: TvInputSize.lg,
          leading: TvIcon('landmark', size: 18, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 10),
        TvInput(
          controller: _account,
          hintText: 'Số tài khoản',
          keyboardType: TextInputType.number,
          size: TvInputSize.lg,
          leading: TvIcon(
            'credit-card',
            size: 18,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 10),
        TvInput(
          controller: _holder,
          hintText: 'Tên chủ tài khoản',
          size: TvInputSize.lg,
          leading: TvIcon('user', size: 18, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),
        TvButton(
          label: 'Xác nhận rút tiền',
          size: TvButtonSize.lg,
          fullWidth: true,
          leadingIcon: const TvIcon('arrow-up-right', size: 18),
          onPressed: _submit,
        ),
      ],
    );
  }
}

// ── Khung chung cho bottom-sheet (handle + tiêu đề + nội dung cuộn) ──────
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.h2().copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accentSoftLine),
        ),
        child: Text(
          label,
          style: AppText.body(
            AppColors.textAccent,
          ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
