import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../widgets/widgets.dart';

/// Các tầng merchandising của Home (K-Commerce Premium):
/// hero banner carousel · category tiles · flash-sale strip.
///
/// Banner là TYPOGRAPHIC (gradient + chữ lớn vẽ bằng Flutter) — không dùng ảnh
/// stock nên không bao giờ dính mùi AI-slop, và tự hợp cả 2 theme.

// ─────────────────────────── Banner carousel ────────────────────────────────

class _BannerDef {
  const _BannerDef({
    required this.eyebrow,
    required this.title,
    required this.sub,
    required this.icon,
    this.isSignal = false, // banner AI — được phép dùng cyan signal
  });

  final String eyebrow;
  final String title;
  final String sub;
  final String icon;
  final bool isSignal;
}

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, this.onOpenAi});

  /// Banner "Trợ lý AI" bấm vào sẽ gọi callback này (mở ChatScreen).
  final VoidCallback? onOpenAi;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  static const _banners = [
    _BannerDef(
      eyebrow: 'VOID DROP · THÁNG NÀY',
      title: 'Linh kiện hiệu năng cao,\ngiá độc quyền thành viên',
      sub: 'Ưu đãi giới hạn cho PC Build & phụ kiện',
      icon: 'percent',
    ),
    _BannerDef(
      eyebrow: 'TRỢ LÝ AI',
      title: 'Hỏi gì cũng được.\nAI tư vấn cấu hình 24/7',
      sub: 'Chạm để trò chuyện với trợ lý TechStore',
      icon: 'bot',
      isSignal: true,
    ),
    _BannerDef(
      eyebrow: 'GIAO HÀNG',
      title: 'Theo dõi shipper\nrealtime trên bản đồ',
      sub: 'Nội thành nhận hàng trong ngày',
      icon: 'truck',
    ),
  ];

  final _controller = PageController();
  Timer? _autoTimer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: AppEffects.easeStandard,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final b = _banners[i];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: _Banner(
                  def: b,
                  onTap: b.isSignal ? widget.onOpenAi : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++) ...[
              AnimatedContainer(
                duration: AppEffects.durBase,
                curve: AppEffects.easeStandard,
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i == _page
                      ? AppColors.accent
                      : AppColors.borderStrong,
                ),
              ),
              if (i != _banners.length - 1) const SizedBox(width: 5),
            ],
          ],
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.def, this.onTap});

  final _BannerDef def;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final light = AppColors.isLight;
    // Nền gradient theo theme; banner AI được phép dùng tint cyan (signal).
    final LinearGradient bg = def.isSignal
        ? (light
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFE2F1F3), Color(0xFFFFFFFF)])
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF07181B), Color(0xFF0A0A0C)]))
        : (light
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFF1E8D8), Color(0xFFFFFFFF)])
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1D1710), Color(0xFF0A0A0C)]));
    final Color accent = def.isSignal ? AppColors.signal : AppColors.textAccent;

    return PressableScale(
      onTap: onTap ?? () {},
      haptic: onTap == null ? PressHaptic.none : PressHaptic.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppEffects.shadowSm,
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(def.eyebrow,
                      style: AppText.label(accent).copyWith(fontSize: 10)),
                  const SizedBox(height: 8),
                  Text(
                    def.title,
                    style: AppText.h2().copyWith(fontSize: 18, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(def.sub,
                      style: AppText.xs(AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // "Ảnh" typographic: icon lớn mờ — điểm nhấn thị giác không stock-photo.
            Opacity(
              opacity: 0.85,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: def.isSignal
                      ? AppColors.glassCyan
                      : AppColors.accentSoft,
                  border: Border.all(
                    color: def.isSignal
                        ? AppColors.signal.withValues(alpha: 0.35)
                        : AppColors.accentSoftLine,
                  ),
                ),
                child: TvIcon(def.icon, size: 28, color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Category tiles ─────────────────────────────────

class CategoryTilesRow extends StatelessWidget {
  const CategoryTilesRow({
    super.key,
    required this.categories,
    required this.onSelect,
  });

  /// Danh sách category (KHÔNG gồm 'Tất cả').
  final List<String> categories;
  final ValueChanged<String> onSelect;

  /// Đoán icon theo từ khoá tên danh mục — fallback 'package'.
  static String _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('pc') || c.contains('linh kiện') || c.contains('build')) {
      return 'cpu';
    }
    if (c.contains('laptop')) return 'laptop';
    if (c.contains('điện thoại') || c.contains('phone')) return 'smartphone';
    if (c.contains('màn') || c.contains('monitor')) return 'monitor';
    if (c.contains('tai nghe') || c.contains('audio') || c.contains('head')) {
      return 'headphones';
    }
    if (c.contains('chuột') || c.contains('mouse')) return 'mouse';
    if (c.contains('phím') || c.contains('keyboard')) return 'keyboard';
    if (c.contains('game') || c.contains('gaming')) return 'gamepad';
    if (c.contains('access') || c.contains('phụ kiện')) return 'headphones';
    return 'package';
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = categories[i];
          return PressableScale(
            onTap: () => onSelect(c),
            haptic: PressHaptic.selection,
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: AppEffects.shadowSm,
                    ),
                    child: TvIcon(_iconFor(c),
                        size: 22, color: AppColors.textAccent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c,
                    style: AppText.xs(AppColors.textSecondary)
                        .copyWith(fontSize: 10.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────── Trust strip ────────────────────────────────────

/// Dải cam kết — 3 lý do nên mua ở đây. Tĩnh, gọn, tăng độ tin cậy (chuẩn
/// e-commerce): hairline chia ô, icon + chữ nhỏ, không chiếm chỗ.
class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  static const _items = [
    ('shield-check', 'Chính hãng', '100% authentic'),
    ('package-check', 'Bảo hành 24T', 'Đổi mới 1-1'),
    ('truck', 'Freeship', 'Nội thành HCM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  TvIcon(_items[i].$1, size: 18, color: AppColors.textAccent),
                  const SizedBox(height: 7),
                  Text(_items[i].$2,
                      style: AppText.xs(AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(_items[i].$3,
                      style: AppText.xs(AppColors.textTertiary)
                          .copyWith(fontSize: 9.5)),
                ],
              ),
            ),
            if (i != _items.length - 1)
              Container(width: 1, height: 34, color: AppColors.borderSubtle),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── VOID PICKS (editorial) ─────────────────────────

/// Khoảnh khắc tạp chí của Home: 1 sản phẩm được "biên tập" — ảnh lớn tràn
/// viền, eyebrow, tên cỡ display, một câu dẫn. Đây là chỗ thở giữa các dải
/// dày đặc, và là thứ khiến Home không giống template.
class VoidPicksSection extends StatelessWidget {
  const VoidPicksSection({super.key, required this.product, required this.onOpen});

  final Product product;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: PressableScale(
        onTap: onOpen,
        scale: 0.99,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppEffects.shadowSm,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh lớn tràn viền — nhân vật chính.
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: AppColors.ink900,
                      child: ProductImage(url: product.imageUrl),
                    ),
                    // Nhãn góc — dấu "biên tập viên chọn".
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgBase.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: AppColors.accentSoftLine),
                        ),
                        child: Text('VOID PICKS',
                            style: AppText.label(AppColors.textAccent)
                                .copyWith(fontSize: 9.5)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.brand.toUpperCase()} · ${product.categoryName.toUpperCase()}',
                      style: AppText.label(AppColors.textTertiary)
                          .copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: AppText.h1().copyWith(fontSize: 22, height: 1.15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lựa chọn của đội ngũ TECH_VOID tuần này — hiệu năng và '
                      'thiết kế đáng để nâng cấp.',
                      style: AppText.sm(AppColors.textSecondary)
                          .copyWith(height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: TvPrice(value: product.price)),
                        Row(
                          children: [
                            Text('Xem chi tiết',
                                style: AppText.label(AppColors.textAccent)
                                    .copyWith(fontSize: 11)),
                            const SizedBox(width: 4),
                            TvIcon('arrow-right',
                                size: 15, color: AppColors.textAccent),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Vừa xem ────────────────────────────────────────

/// Dải "Vừa xem" — chỉ hiện khi khách đã xem ít nhất 1 sản phẩm. Thẻ nhỏ gọn
/// hơn flash sale (chỉ ảnh + tên) vì đây là lối tắt quay lại, không phải chào hàng.
class RecentlyViewedStrip extends StatelessWidget {
  const RecentlyViewedStrip({
    super.key,
    required this.products,
    required this.onOpen,
  });

  final List<Product> products;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            children: [
              TvIcon('clock', size: 15, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Text('VỪA XEM',
                  style: AppText.label(AppColors.textPrimary)
                      .copyWith(fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = products[i];
              return PressableScale(
                onTap: () => onOpen(p),
                child: SizedBox(
                  width: 86,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppColors.ink900,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ProductImage(
                            url: p.imageUrl, dimmed: p.isSoldOut),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.name,
                        style: AppText.xs(AppColors.textSecondary)
                            .copyWith(fontSize: 10.5, height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Flash sale strip ───────────────────────────────

class FlashSaleStrip extends StatefulWidget {
  const FlashSaleStrip({
    super.key,
    required this.products,
    required this.onOpen,
  });

  final List<Product> products;
  final ValueChanged<Product> onOpen;

  @override
  State<FlashSaleStrip> createState() => _FlashSaleStripState();
}

class _FlashSaleStripState extends State<FlashSaleStrip> {
  Timer? _tick;
  Duration _left = Duration.zero;

  // Mức giảm mock, cố định theo vị trí (không Random — deterministic, giá gạch
  // là giá "trước sale" suy ra từ giá thật; giá BÁN vẫn là giá thật từ BE).
  static const _discounts = [15, 25, 10, 30, 20, 12];

  @override
  void initState() {
    super.initState();
    _computeLeft();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _computeLeft());
  }

  void _computeLeft() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (mounted) setState(() => _left = midnight.difference(now));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.products.take(6).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            children: [
              TvIcon('zap', size: 16, color: AppColors.sale500),
              const SizedBox(width: 8),
              Text('FLASH SALE',
                  style: AppText.label(AppColors.textPrimary)
                      .copyWith(fontSize: 13)),
              const SizedBox(width: 10),
              // Đồng hồ đếm ngược tới 0h — pill đỏ dịu.
              // Dưới 10 phút cuối: nhấp nháy nhẹ để tạo cảm giác gấp gáp.
              Builder(builder: (context) {
                final urgent = _left.inMinutes < 10;
                final pill = Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _fmt(_left),
                    style: AppText.mono(size: 11, color: AppColors.sale500)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                );
                if (!urgent) return pill;
                return pill
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(
                      duration: const Duration(milliseconds: 620),
                      begin: 0.45,
                      curve: Curves.easeInOut,
                    );
              }),
              const Spacer(),
              Text('Kết thúc hôm nay',
                  style: AppText.xs(AppColors.textTertiary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = items[i];
              final d = _discounts[i % _discounts.length];
              return _FlashCard(
                product: p,
                discount: d,
                onTap: () => widget.onOpen(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({
    required this.product,
    required this.discount,
    required this.onTap,
  });

  final Product product;
  final int discount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Giá bán = giá thật; giá gạch = giá "trước sale" suy ngược, làm tròn nghìn.
    final original =
        ((product.price / (1 - discount / 100)) / 1000).round() * 1000;

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 138,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppEffects.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 108,
                  width: double.infinity,
                  child: ColoredBox(
                    color: AppColors.ink900,
                    child: ProductImage(
                        url: product.imageUrl, dimmed: product.isSoldOut),
                  ),
                ),
                // Badge -% — đỏ sale, chữ trắng (đúng liều chất "chợ").
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sale500,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '-$discount%',
                      style: AppText.mono(size: 10, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppText.sm(AppColors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600, height: 1.25),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Giá VND dài — xếp 2 dòng để không tràn thẻ 138px:
                  // giá bán (gold) trên, giá gạch nhỏ dưới.
                  Text(
                    formatVnd(product.price),
                    style: AppText.price().copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatVnd(original),
                    style: AppText.xs(AppColors.textTertiary).copyWith(
                      fontSize: 10.5,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
