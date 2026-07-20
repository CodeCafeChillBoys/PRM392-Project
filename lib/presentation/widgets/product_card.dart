import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/product.dart';
import '../../data/services/wishlist_service.dart';
import 'fly_to_cart.dart';
import 'pressable.dart';
import 'product_image.dart';
import 'tv_badge.dart';
import 'tv_rating.dart';
import 'tv_icon_button.dart';
import 'tv_price.dart';

/// Product grid card — VOID LUXE editorial: ảnh trên tile ink900, eyebrow
/// brand tracking rộng, tên bodyStrong (không hét), giá gold, hairline subtle.
/// Nút (+) ghost tinh tế thay tile accent chói thời neon. Cả card có
/// press-scale + haptic.
/// Mirrors `components/data/ProductCard.jsx`.
class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, this.onTap, this.onAdd});

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  /// Điểm XUẤT PHÁT của hiệu ứng bay vào giỏ (ô ảnh của chính card này).
  final _imageKey = GlobalKey();

  void _handleAdd() {
    FlyToCart.launch(
      context: context,
      sourceKey: _imageKey,
      imageUrl: widget.product.imageUrl,
    );
    widget.onAdd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final onTap = widget.onTap;
    final onAdd = widget.onAdd;
    final soldOut = product.isSoldOut;
    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      pressedOpacity: 0.92,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppEffects.shadowSm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                key: _imageKey, // nguồn của hiệu ứng bay vào giỏ
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: AppColors.ink900,
                      child: ProductImage(
                        url: product.imageUrl,
                        dimmed: soldOut,
                      ),
                    ),
                    if (soldOut)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: TvBadge(
                          'Hết hàng',
                          variant: TvBadgeVariant.neutral,
                        ),
                      ),
                    // Tim yêu thích (local) — góc phải trên ảnh.
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _WishHeart(productId: product.id),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.brand.toUpperCase(),
                      style: AppText.label(
                        AppColors.textTertiary,
                      ).copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong().copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    // Sao trung bình + số đánh giá (ẩn nếu chưa có đánh giá).
                    if (product.hasReviews)
                      Row(
                        children: [
                          TvRating(
                            value: product.averageRating,
                            showScale: false,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviewCount})',
                            style: AppText.xs(AppColors.textTertiary),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Chưa có đánh giá',
                        style: AppText.xs(AppColors.textTertiary),
                      ),
                    const SizedBox(height: 8),
                    // Giá + nút (+) cùng hàng, căn giữa theo chiều dọc — thay
                    // Stack/Positioned cũ (nút bị lệch, nhô cao hơn dòng giá).
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: TvPrice(value: product.price),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Opacity(
                          opacity: soldOut ? 0.5 : 1,
                          child: TvIconButton(
                            variant: TvIconButtonVariant.elevated,
                            size: TvIconButtonSize.sm,
                            enabled: !soldOut,
                            // Bay vào giỏ rồi mới thêm thật (không chặn).
                            onPressed: soldOut || onAdd == null
                                ? null
                                : _handleAdd,
                            tooltip: 'Thêm vào giỏ',
                            icon: Icon(
                              Icons.add,
                              size: 18,
                              color: AppColors.textAccent,
                            ),
                          ),
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

/// Nút tim yêu thích trên card — nghe [WishlistService] nên đổi trạng thái tức
/// thì ở mọi nơi (card, badge header, màn Wishlist) khi bật/tắt.
class _WishHeart extends StatelessWidget {
  const _WishHeart({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final wl = WishlistService.instance;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: wl.notifier,
      builder: (context, ids, _) {
        final wished = ids.contains(productId);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            wl.toggle(productId);
          },
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bgSurface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Icon(
              wished ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: wished ? AppColors.danger500 : AppColors.textTertiary,
            ),
          ),
        );
      },
    );
  }
}
