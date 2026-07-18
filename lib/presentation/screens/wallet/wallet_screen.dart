import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/models/wallet_transaction.dart';
import '../../widgets/widgets.dart';

/// "Ví TechStore" — số dư + lịch sử giao dịch (nạp qua VNPay, thanh toán đơn,
/// hoàn tiền). Pushed page (tự Scaffold, không phải tab). Vào từ tab Hồ sơ
/// hoặc từ Checkout khi số dư không đủ.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  final _service = WalletService();

  double? _balance;
  DateTime? _updatedAt;
  List<WalletTransaction> _transactions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Khách rời app để thanh toán VNPay rồi quay lại — tự làm mới số dư/lịch sử.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final walletFuture = _service.fetchWallet();
      final txFuture = _service.fetchTransactions();
      final wallet = await walletFuture;
      final txs = await txFuture;
      if (!mounted) return;
      setState(() {
        _balance = wallet.balance;
        _updatedAt = wallet.updatedAt;
        _transactions = txs;
      });
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không tải được ví.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTopUp() async {
    // Sheet trả về paymentUrl khi tạo giao dịch nạp thành công (null nếu
    // khách đóng sheet mà chưa bấm nạp) — mở URL bằng context ổn định của
    // màn Ví, không dùng context của sheet (đã pop, có thể sắp unmount).
    final paymentUrl = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _TopUpSheet(),
    );
    if (!mounted) return;
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
      } catch (_) {/* giao dịch đã tạo phía BE; lỗi mở URL hiếm khi xảy ra */}
      if (mounted) TvToast.show(context, 'Đang mở VNPay để nạp tiền...');
    }
    // Làm mới cho chắc — kết quả nạp thật chỉ về sau khi quay lại từ VNPay
    // (didChangeAppLifecycleState resumed cũng tự refresh, đây là double-check).
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Ví TechStore',
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
      onRefresh: () => _load(),
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 14, AppSpacing.gutter, 24),
        children: [
          _balanceHero(),
          const SizedBox(height: 18),
          TvButton(
            label: 'Nạp tiền',
            fullWidth: true,
            leadingIcon: const TvIcon('plus', size: 18),
            onPressed: _openTopUp,
          ),
          const SizedBox(height: 28),
          const TvSectionHeader(
            icon: TvIcon('clock'),
            title: 'Lịch sử giao dịch',
          ),
          const SizedBox(height: 12),
          if (_transactions.isEmpty) _emptyHistory() else _historyList(),
        ],
      ),
    );
  }

  Widget _balanceHero() {
    final updated = _updatedAt;
    return TvCard(
      padding: 20,
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Số dư khả dụng'.toUpperCase(), style: AppText.label()),
          const SizedBox(height: 10),
          Text(formatVnd(_balance ?? 0), style: AppText.priceXL()),
          if (updated != null) ...[
            const SizedBox(height: 8),
            Text('Cập nhật ${formatRelativeTime(updated)}',
                style: AppText.xs(AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }

  Widget _emptyHistory() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            TvIcon('inbox', size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Chưa có giao dịch nào',
                style: AppText.body(AppColors.textSecondary)),
          ],
        ),
      );

  Widget _historyList() {
    return Column(
      children: [
        for (var i = 0; i < _transactions.length; i++) ...[
          _transactionTile(_transactions[i]),
          if (i != _transactions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _transactionTile(WalletTransaction tx) {
    final credit = tx.isCredit;
    final color = credit ? AppColors.success500 : AppColors.danger500;
    final time = formatRelativeFromIso(tx.createdAt);
    final desc = tx.description?.trim();
    final subtitle = (desc != null && desc.isNotEmpty) ? desc : tx.typeLabel;
    return TvCard(
      padding: 14,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: credit ? AppColors.successSoft : AppColors.dangerSoft,
            ),
            child: TvIcon(_iconFor(tx.type), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong()),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(time, style: AppText.xs(AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${credit ? '+' : '-'}${formatVnd(tx.amount.abs())}',
                style: AppText.body(color)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              if (tx.status != 'Completed') ...[
                const SizedBox(height: 4),
                TvBadge(
                  tx.statusLabel,
                  variant: tx.status == 'Failed'
                      ? TvBadgeVariant.danger
                      : TvBadgeVariant.warning,
                  size: TvBadgeSize.sm,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Icon theo loại giao dịch — tái dùng bộ Lucide đã có trong AppIcons
  /// (không thêm key mới: nạp='plus', hoàn tiền='package-check',
  /// thanh toán='shopping-bag', rút tiền='banknote').
  String _iconFor(String type) => switch (type) {
        'TopUp' => 'plus',
        'Refund' => 'package-check',
        'Payment' => 'shopping-bag',
        'Withdrawal' => 'banknote',
        _ => 'wallet',
      };
}

/// Sheet nạp tiền — chip nhanh + ô nhập tuỳ chọn → tạo giao dịch nạp rồi mở
/// cổng VNPay ở trình duyệt ngoài (`url_launcher`, giống PaymentWaitingScreen).
class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const _quickAmounts = [50000, 100000, 200000, 500000];

  final _service = WalletService();
  final _amountCtrl = TextEditingController();
  int? _selected;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _pick(int amount) {
    setState(() {
      _selected = amount;
      _amountCtrl.text = _groupThousands(amount); // hiển thị có dấu chấm
    });
  }

  /// Số nguyên đồng > 0 — bỏ mọi dấu phân tách trước khi parse; null nếu trống.
  double? _parsedAmount() {
    final digits = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final n = int.tryParse(digits);
    if (n == null || n <= 0) return null;
    return n.toDouble();
  }

  Future<void> _submit() async {
    final amount = _parsedAmount();
    if (amount == null) {
      TvToast.show(context, 'Nhập số tiền hợp lệ (số nguyên lớn hơn 0).');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await _service.createTopUp(amount);
      if (!mounted) return;
      // Trả paymentUrl cho WalletScreen (context ổn định) mở VNPay + toast —
      // tránh dùng context của chính sheet ngay sau khi pop.
      Navigator.of(context).pop(result.paymentUrl);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        final msg =
            e is ApiException ? e.message : 'Nạp tiền thất bại. Thử lại nhé.';
        TvToast.show(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppEffects.shadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nạp tiền vào Ví', style: AppText.h3()),
              const SizedBox(height: 4),
              Text('Chọn nhanh hoặc nhập số tiền khác',
                  style: AppText.sm(AppColors.textSecondary)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in _quickAmounts)
                    _AmountChip(
                      label: formatVnd(a),
                      selected: _selected == a,
                      onTap: () => _pick(a),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Số tiền khác', style: AppText.sm(AppColors.textSecondary)),
              const SizedBox(height: 8),
              TvInput(
                controller: _amountCtrl,
                hintText: 'VD: 300.000',
                keyboardType: TextInputType.number,
                leading: const TvIcon('banknote'),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsFormatter(),
                ],
                onChanged: (_) => setState(() => _selected = null),
              ),
              if (_parsedAmount() != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_capitalizeFirst(readVietnameseNumber(_parsedAmount()!.round()))} đồng',
                  style: AppText.sm(AppColors.textAccent)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 20),
              TvButton(
                label: 'Nạp qua VNPay',
                fullWidth: true,
                size: TvButtonSize.lg,
                loading: _submitting,
                leadingIcon: const TvIcon('qr-code', size: 18),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip số tiền nhanh — style đồng bộ `_CategoryChip` (staff_products_screen.dart).
class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? AppEffects.glowAccentSm : null,
        ),
        child: Text(
          label,
          style: AppText.label(
            selected ? AppColors.textAccent : AppColors.textSecondary,
          ).copyWith(fontSize: 12.5, letterSpacing: 0.25),
        ),
      ),
    );
  }
}

/// Viết hoa chữ cái đầu (vd "ba mươi triệu" → "Ba mươi triệu").
String _capitalizeFirst(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Nhóm hàng nghìn bằng dấu chấm (1234567 → "1.234.567").
String _groupThousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Tự chèn dấu chấm phân tách nghìn khi gõ; con trỏ giữ ở cuối (nhập tiền
/// luôn gõ từ trái sang nên đủ dùng). Dùng SAU FilteringTextInputFormatter.digitsOnly.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final formatted = _groupThousands(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
