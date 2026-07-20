import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';
import 'tv_icon.dart';

/// Khoảng ngày đã chọn cho các bộ lọc thống kê (Admin / Staff).
///
/// [from] BAO GỒM (local 00:00), [to] LOẠI TRỪ (local 00:00 của ngày sau ngày
/// cuối) → [contains] gộp trọn ngày cuối, không sót đơn đặt lúc 23h. Admin đổi
/// sang UTC khi gọi BE; Staff so trực tiếp với `orderDate` đã `toLocal()`.
class TvDateRange {
  const TvDateRange({
    required this.key,
    required this.label,
    required this.from,
    required this.to,
  });

  /// 'today' | '7d' | '30d' | 'custom' — dùng để tô sáng chip đang chọn.
  final String key;

  /// Nhãn ngắn cho tiêu đề ("Hôm nay", "7 ngày", "01/07 – 15/07").
  final String label;

  /// Đầu khoảng — bao gồm, local 00:00.
  final DateTime from;

  /// Cuối khoảng — loại trừ, local 00:00 của ngày SAU ngày cuối.
  final DateTime to;

  /// [d] (đã `toLocal()`) có nằm trong khoảng không.
  bool contains(DateTime? d) =>
      d != null && !d.isBefore(from) && d.isBefore(to);

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  /// Chỉ hôm nay (00:00 → hết ngày).
  factory TvDateRange.today([DateTime? now]) {
    final s = _day(now ?? DateTime.now());
    return TvDateRange(
      key: 'today',
      label: 'Hôm nay',
      from: s,
      to: s.add(const Duration(days: 1)),
    );
  }

  /// [days] ngày gần nhất TÍNH CẢ hôm nay (7 ngày = hôm nay + 6 ngày trước).
  factory TvDateRange.lastDays(int days, [DateTime? now]) {
    final today = _day(now ?? DateTime.now());
    return TvDateRange(
      key: '${days}d',
      label: '$days ngày',
      from: today.subtract(Duration(days: days - 1)),
      to: today.add(const Duration(days: 1)),
    );
  }

  /// Khoảng tuỳ chọn từ lịch — tự sắp xếp nếu chọn ngược, gộp trọn ngày cuối.
  factory TvDateRange.custom(DateTime start, DateTime end) {
    var lo = _day(start);
    var hi = _day(end);
    if (lo.isAfter(hi)) {
      final tmp = lo;
      lo = hi;
      hi = tmp;
    }
    final label = lo == hi ? _dm(lo) : '${_dm(lo)} – ${_dm(hi)}';
    return TvDateRange(
      key: 'custom',
      label: label,
      from: lo,
      to: hi.add(const Duration(days: 1)),
    );
  }

  /// Khoảng để mồi cho [showDateRangePicker] (end là ngày cuối bao gồm).
  DateTimeRange get asPickerRange =>
      DateTimeRange(start: from, end: to.subtract(const Duration(days: 1)));

  /// Khoá ổn định cho `ValueKey` (TvDateRange không override `==`).
  String get stateKey => '$key:${from.millisecondsSinceEpoch}';
}

/// Bộ lọc ngày dạng HYBRID dùng chung Admin & Staff: các chip nhanh
/// (Hôm nay / 7 ngày / 30 ngày) + nút lịch mở [showDateRangePicker] để tự chọn
/// khoảng từ–đến. Chip cuộn ngang để không tràn khi nhãn khoảng dài.
class TvDateFilter extends StatelessWidget {
  const TvDateFilter({super.key, required this.value, required this.onChanged});

  final TvDateRange value;
  final ValueChanged<TvDateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final presets = <TvDateRange>[
      TvDateRange.today(),
      TvDateRange.lastDays(7),
      TvDateRange.lastDays(30),
    ];
    final isCustom = value.key == 'custom';

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final p in presets) ...[
              _chip(
                label: p.label,
                selected: value.key == p.key,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(p);
                },
              ),
              const SizedBox(width: 8),
            ],
            _chip(
              label: isCustom ? value.label : 'Tùy chọn',
              selected: isCustom,
              leading: 'calendar',
              onTap: () => _pickRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? leading,
  }) {
    final fg = selected ? AppColors.textAccent : AppColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppEffects.durBase,
        curve: AppEffects.easeStandard,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgOverlay,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accentSoftLine : AppColors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              TvIcon(leading, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.sm(fg).copyWith(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: value.key == 'custom' ? value.asPickerRange : null,
      helpText: 'CHỌN KHOẢNG NGÀY',
      cancelText: 'Huỷ',
      saveText: 'Xong',
      builder: (ctx, child) {
        // Nhuộm picker theo theme VOID LUXE/PAPER (accent champagne).
        final dark = !AppColors.isLight;
        final scheme = ColorScheme(
          brightness: dark ? Brightness.dark : Brightness.light,
          primary: AppColors.accent,
          onPrimary: AppColors.textOnAccent,
          secondary: AppColors.accent,
          onSecondary: AppColors.textOnAccent,
          error: AppColors.danger500,
          onError: Colors.white,
          surface: AppColors.bgSurface,
          onSurface: AppColors.textPrimary,
        );
        return Theme(
          data: Theme.of(ctx).copyWith(colorScheme: scheme),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(TvDateRange.custom(picked.start, picked.end));
  }
}
