import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/product.dart';
import 'fly_to_cart.dart';
import 'pressable.dart';
import 'product_image.dart';
import 'tv_badge.dart';
import 'tv_icon_button.dart';
import 'tv_price.dart';

/// Product grid card — VOID LUXE editorial: ảnh trên tile ink900, eyebrow
/// brand tracking rộng, tên bodyStrong (không hét), giá gold, hairline subtle.
/// Nút (+) ghost tinh tế thay tile accent chói thời neon. Cả card có
/// press-scale + haptic.
/// Mirrors `components/data/ProductCard.jsx`.
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAdd,
  });

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
                      child:
                          ProductImage(url: product.imageUrl, dimmed: soldOut),
                    ),
                    if (soldOut)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child:
                            TvBadge('Hết hàng', variant: TvBadgeVariant.neutral),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.brand.toUpperCase(),
                          style: AppText.label(AppColors.textTertiary)
                              .copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong().copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 9),
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: TvPrice(value: product.price),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: soldOut ? 0.5 : 1,
                        child: TvIconButton(
                          variant: TvIconButtonVariant.elevated,
                          enabled: !soldOut,
                          // Bay vào giỏ rồi mới thêm thật (hiệu ứng không chặn).
                          onPressed:
                              soldOut || onAdd == null ? null : _handleAdd,
                          tooltip: 'Thêm vào giỏ',
                          icon: const Icon(Icons.add,
                              size: 20, color: AppColors.gold400),
                        ),
                      ),
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
