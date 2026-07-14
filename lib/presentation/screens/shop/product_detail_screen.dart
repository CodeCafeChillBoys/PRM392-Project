import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/product.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';

/// Product detail — hero, brand/category, price, stock + quantity, description
/// tabs, sticky add-to-cart CTA (`GET /api/Products/{id}`).
/// Mirrors `ProductDetailScreen.jsx`.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  String _tab = 'desc';

  Product get _p => widget.product;

  void _addToCart() {
    final cart = context.read<CartController>();
    final appNav = context.read<AppNav>();
    cart.add(_p, quantity: _qty);
    appNav.goToCart();
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
              icon: const TvIcon('arrow-left', size: 22, color: AppColors.textAccent),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(soldOut),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                _buildThumbnails(),
                const SizedBox(height: 18),
                Text(
                  '${_p.brand} · ${_p.categoryName}'.toUpperCase(),
                  style: AppText.label(AppColors.textTertiary)
                      .copyWith(fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(_p.name, style: AppText.h1().copyWith(fontSize: 27)),
                const SizedBox(height: 8),
                TvPrice(value: _p.price, size: TvPriceSize.lg),
                const SizedBox(height: 18),
                _buildStockRow(soldOut),
                const SizedBox(height: 22),
                TvTabs(
                  value: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                  tabs: const [
                    TvTab('desc', 'Mô tả'),
                    TvTab('reviews', 'Đánh giá'),
                  ],
                ),
                const SizedBox(height: 14),
                if (_tab == 'desc')
                  Text(
                    _p.description,
                    style: AppText.body(AppColors.textSecondary)
                        .copyWith(fontSize: 14.5, height: 1.65),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                    child: Text(
                      'Chưa có đánh giá cho sản phẩm này. Hãy là người đầu tiên!',
                      style: AppText.body(AppColors.textSecondary)
                          .copyWith(fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool soldOut) {
    final lowStock = _p.isLowStock;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.8,
          colors: [Color(0x1F00F0FF), Colors.transparent],
          stops: [0, 0.7],
        ),
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
                    ? TvBadge('Sắp hết · còn ${_p.stockQuantity}',
                        variant: TvBadgeVariant.glass)
                    : const TvBadge('Còn hàng', variant: TvBadgeVariant.glass),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnails() {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: i == 0 ? AppColors.accent : AppColors.borderDefault,
                width: i == 0 ? 1.5 : 1,
              ),
              boxShadow: i == 0 ? AppEffects.glowAccentSm : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: ProductImage(url: _p.heroImageUrl),
          ),
        ],
      ],
    );
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.bgBase],
          stops: [0, 0.3],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              TvIconButton(
                icon: const TvIcon('message-circle', size: 20),
                variant: TvIconButtonVariant.elevated,
                size: TvIconButtonSize.lg,
                tooltip: 'Chat hỗ trợ',
                onPressed: () =>
                    TvToast.show(context, 'Chat hỗ trợ đang được phát triển'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TvButton(
                  label: soldOut ? 'Hết hàng' : 'Thêm vào giỏ',
                  size: TvButtonSize.lg,
                  fullWidth: true,
                  leadingIcon: soldOut ? null : const TvIcon('shopping-cart', size: 18),
                  onPressed: soldOut ? null : _addToCart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
