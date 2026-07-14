import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/product.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';
import '../chat/chat_screen.dart';

/// Product detail — VOID LUXE editorial: hero parallax trên nền glow gold,
/// eyebrow bronze, tên sản phẩm cỡ display, nội dung vào màn theo cascade,
/// tab Đánh giá có empty state thật, CTA morph ✓ khi thêm giỏ.
/// (`GET /api/Products/{id}`). Mirrors `ProductDetailScreen.jsx`.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  String _tab = 'desc';
  bool _added = false;
  final _scroll = ScrollController();

  Product get _p => widget.product;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_added) return;
    HapticFeedback.mediumImpact();
    setState(() => _added = true); // CTA morph sang trạng thái ✓
    context.read<CartController>().add(_p, quantity: _qty);
    // Cho người dùng thấy khoảnh khắc ✓ rồi mới rời màn.
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    context.read<AppNav>().goToCart();
    TvToast.show(context, 'Đã thêm ${_p.name} vào giỏ');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().count;
    final appNav = context.read<AppNav>();
    final soldOut = _p.isSoldOut;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.brand,
            leading: TvIconButton(
              icon: TvIcon('arrow-left',
                  size: 22, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Quay lại',
            ),
            brand: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: TvLogo(size: TvLogoSize.sm),
            ),
            actions: [
              TvIconButton(
                icon: const TvIcon('shopping-cart'),
                badge: cartCount > 0 ? cartCount : null,
                tooltip: 'Giỏ hàng',
                onPressed: () {
                  appNav.goToCart();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          Expanded(child: _buildBody(soldOut)),
          _buildStickyCta(soldOut),
        ],
      ),
    );
  }

  Widget _buildBody(bool soldOut) {
    // Nội dung editorial vào màn theo cascade (eyebrow → tên → giá → specs).
    final content = <Widget>[
      const SizedBox(height: 22),
      Text(
        '${_p.brand} · ${_p.categoryName}'.toUpperCase(),
        style: AppText.label(AppColors.gold700).copyWith(fontSize: 12),
      ),
      const SizedBox(height: 8),
      Text(
        _p.name,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppText.display().copyWith(fontSize: 30),
      ),
      const SizedBox(height: 12),
      TvPrice(value: _p.price, size: TvPriceSize.lg),
      const SizedBox(height: 20),
      Divider(color: AppColors.borderSubtle, height: 1),
      const SizedBox(height: 16),
      _buildStockRow(soldOut),
      const SizedBox(height: 24),
      TvTabs(
        value: _tab,
        onChanged: (v) => setState(() => _tab = v),
        tabs: const [
          TvTab('desc', 'Mô tả'),
          TvTab('reviews', 'Đánh giá'),
        ],
      ),
      const SizedBox(height: 16),
      if (_tab == 'desc')
        Text(
          _p.description,
          style: AppText.body(AppColors.textSecondary)
              .copyWith(fontSize: 14.5, height: 1.65),
        )
      else
        _buildReviewsEmpty(),
      const SizedBox(height: 24),
    ];

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(child: _buildHero(soldOut)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content
                  .animate(interval: AppEffects.staggerStep)
                  .fadeIn(
                    duration: AppEffects.durEnter,
                    curve: AppEffects.easeStandard,
                  )
                  .moveY(
                    begin: AppEffects.entranceRise,
                    end: 0,
                    duration: AppEffects.durEnter,
                    curve: AppEffects.easeStandard,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hero ảnh full-bleed trên glow gold — PARALLAX: ảnh trôi chậm 0.45× tốc độ
  /// cuộn (scroll-linked), tạo chiều sâu kiểu trang sản phẩm Apple.
  Widget _buildHero(bool soldOut) {
    final lowStock = _p.isLowStock;
    final hero = Container(
      decoration: BoxDecoration(
        color: AppColors.ink900,
        gradient: AppColors.heroGlow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ProductImage(url: _p.heroImageUrl, fit: BoxFit.contain),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: soldOut
                ? const TvBadge('Hết hàng', variant: TvBadgeVariant.neutral)
                : lowStock
                    // Variant warning mới — glass giờ chỉ dành badge AI cyan.
                    ? TvBadge('Sắp hết · còn ${_p.stockQuantity}',
                        variant: TvBadgeVariant.warning)
                    : const TvBadge('Còn hàng',
                        variant: TvBadgeVariant.success),
          ),
        ],
      ),
    );

    return ClipRect(
      child: AnimatedBuilder(
        animation: _scroll,
        builder: (context, child) {
          final offset = _scroll.hasClients ? _scroll.offset : 0.0;
          return Transform.translate(
            offset: Offset(0, offset * 0.45),
            child: child,
          );
        },
        child: hero,
      ),
    );
  }

  /// Empty state thật cho tab Đánh giá (thay string cứng "hãy là người đầu
  /// tiên" trơ trọi) — trung thực và có chủ đích.
  Widget _buildReviewsEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(AppIcons.get('star'),
                size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('Chưa có đánh giá', style: AppText.h2().copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Sản phẩm này đang chờ cảm nhận đầu tiên từ bạn.',
              textAlign: TextAlign.center,
              style: AppText.sm(AppColors.textTertiary),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: AppEffects.durEnter);
  }

  Widget _buildStockRow(bool soldOut) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TvIcon(
                soldOut ? 'x-circle' : 'check-circle',
                size: 16,
                color: soldOut ? AppColors.danger500 : AppColors.success500,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  soldOut ? 'Tạm hết hàng' : 'Còn ${_p.stockQuantity} sản phẩm',
                  style: AppText.body(
                    soldOut ? AppColors.danger500 : AppColors.success500,
                  ).copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (!soldOut)
          TvQuantityStepper(
            value: _qty,
            min: 1,
            max: _p.stockQuantity,
            onChanged: (v) => setState(() => _qty = v),
          ),
      ],
    );
  }

  Widget _buildStickyCta(bool soldOut) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: AppEffects.shadowMd,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 12, AppSpacing.gutter, 12),
          child: Row(
            children: [
              TvIconButton(
                icon: const TvIcon('message-circle', size: 20),
                variant: TvIconButtonVariant.elevated,
                size: TvIconButtonSize.lg,
                tooltip: 'Hỏi trợ lý AI về sản phẩm này',
                // Mở trợ lý AI (Gemini) với câu hỏi mồi về đúng sản phẩm đang xem.
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      seedQuestion: 'Tư vấn giúp mình về ${widget.product.name} '
                          '(${widget.product.brand}) — sản phẩm này phù hợp với ai?',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // CTA morph: Thêm vào giỏ -> ✓ Đã thêm (AnimatedSwitcher).
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: AppEffects.easeEmphasized,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: TvButton(
                    key: ValueKey(_added),
                    label: soldOut
                        ? 'Hết hàng'
                        : (_added ? 'Đã thêm vào giỏ' : 'Thêm vào giỏ'),
                    size: TvButtonSize.lg,
                    fullWidth: true,
                    variant: _added
                        ? TvButtonVariant.accent
                        : TvButtonVariant.gradient,
                    leadingIcon: soldOut
                        ? null
                        : TvIcon(_added ? 'check' : 'shopping-cart', size: 18),
                    onPressed: soldOut || _added ? null : _addToCart,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
