import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/product.dart';
import 'product_image.dart';
import 'tv_badge.dart';
import 'tv_icon_button.dart';
import 'tv_price.dart';

/// Product grid card — image, sold-out badge, brand, title, price, and a cyan
/// (+) add-to-cart tile overlapping the price row.
/// Mirrors `components/data/ProductCard.jsx`.
class ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final soldOut = product.isSoldOut;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppEffects.shadowSm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: Colors.black,
                      child: ProductImage(url: product.imageUrl, dimmed: soldOut),
                    ),
                    if (soldOut)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: TvBadge('Hết hàng', variant: TvBadgeVariant.neutral),
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
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body()
                              .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
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
                          variant: soldOut
                              ? TvIconButtonVariant.elevated
                              : TvIconButtonVariant.accent,
                          enabled: !soldOut,
                          onPressed: soldOut ? null : onAdd,
                          tooltip: 'Thêm vào giỏ',
                          icon: const Icon(Icons.add, size: 22),
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
