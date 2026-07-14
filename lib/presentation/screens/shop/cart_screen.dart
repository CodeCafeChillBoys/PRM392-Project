import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cart_item.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';
import 'checkout_screen.dart';

/// Cart — VOID LUXE: line items vuốt-để-xoá (Dismissible), skeleton loading,
/// tổng tiền đếm-lên (count-up) priceXL gold KHÔNG glow, sticky checkout bar.
/// Voucher input trang trí (không handler) đã bỏ — luxury không nói dối.
/// Mirrors `CartScreen.jsx`.
///
/// A tab page: provides its own page app bar; the [RootShell] owns the Scaffold
/// + bottom nav.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Column(
      children: [
        const TvAppBar(mode: TvAppBarMode.page, title: 'Giỏ hàng'),
        Expanded(
          child: cart.isLoading && cart.isEmpty
              ? const _CartSkeleton()
              : cart.isEmpty
                  ? _EmptyCart()
                  : _CartBody(cart: cart),
        ),
      ],
    );
  }
}

/// Skeleton 3 dòng giỏ hàng — shimmer trung tính, thay spinner xoay.
class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight,
      ),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter, 14, AppSpacing.gutter, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => TvCard(
          padding: 12,
          child: Row(
            children: [
              const Bone.square(size: 88, borderRadius: BorderRadius.all(Radius.circular(12))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone.text(words: 1, style: AppText.label()),
                    const SizedBox(height: 8),
                    Bone.text(words: 3, style: AppText.h3()),
                    const SizedBox(height: 12),
                    Bone.text(words: 2, style: AppText.price()),
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

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgElevated,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: TvIcon('shopping-cart',
                  size: 34, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text('Giỏ hàng trống', style: AppText.h2()),
            const SizedBox(height: 4),
            Text(
              'Khám phá hàng nghìn sản phẩm công nghệ đỉnh cao.',
              textAlign: TextAlign.center,
              style:
                  AppText.body(AppColors.textSecondary).copyWith(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TvButton(
              label: 'Mua sắm ngay',
              leadingIcon: const TvIcon('compass', size: 18),
              onPressed: () => context.read<AppNav>().goExplore(),
            ),
          ]
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
    );
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.cart});
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotal;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter, 14, AppSpacing.gutter, 8),
            children: [
              for (final (i, item) in cart.items.indexed) ...[
                _CartLine(item: item)
                    .animate(
                      delay: Duration(
                          milliseconds: (i * 60).clamp(0, 360)),
                    )
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
                const SizedBox(height: 14),
              ],
              _SummaryCard(subtotal: subtotal),
            ],
          ),
        ),
        _CheckoutBar(subtotal: subtotal),
      ],
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
    // Vuốt sang trái để xoá — nền đỏ mềm + icon thùng rác lộ dần.
    return Dismissible(
      key: ValueKey('cart-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        cart.remove(item.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.dangerLine),
        ),
        child:
            const TvIcon('trash-2', size: 20, color: AppColors.danger500),
      ),
      child: TvCard(
        padding: 12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 88,
                height: 88,
                child: ColoredBox(
                  color: AppColors.ink900,
                  child: ProductImage(url: item.productImageUrl),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.brand.toUpperCase(),
                                style: AppText.label(AppColors.textTertiary)
                                    .copyWith(fontSize: 10)),
                            Text(
                              item.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.h3().copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      // Fallback cho ai không biết vuốt: chạm thùng rác.
                      PressableScale(
                        scale: 0.85,
                        haptic: PressHaptic.medium,
                        onTap: () => cart.remove(item.id),
                        child: Padding(
                          padding: EdgeInsets.all(2),
                          child: TvIcon('trash-2',
                              size: 18, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TvPrice(value: item.unitPrice, size: TvPriceSize.sm),
                      TvQuantityStepper(
                        value: item.quantity,
                        onChanged: (q) => cart.setQuantity(item.id, q),
                      ),
                    ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TvCard(
        padding: 14,
        child: Column(
          children: [
            _miniRow('Tổng tiền sản phẩm', formatVnd(subtotal)),
            const SizedBox(height: 6),
            _miniRow('Phí vận chuyển', 'Miễn phí',
                valueColor: AppColors.success500),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppText.body(AppColors.textSecondary).copyWith(fontSize: 13)),
        Text(value,
            style: AppText.body(valueColor ?? AppColors.textPrimary)
                .copyWith(fontSize: 13)),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: AppEffects.shadowLg,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(AppSpacing.gutter, 16, AppSpacing.gutter, 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Tạm tính',
                        style: AppText.h2().copyWith(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    // Count-up: tổng tiền lăn số tới giá trị mới — gold,
                    // KHÔNG glow (tiết chế là tín hiệu luxury).
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: subtotal),
                      duration: const Duration(milliseconds: 400),
                      curve: AppEffects.easeStandard,
                      builder: (_, animated, _) => Text(
                        formatVnd(animated),
                        style: AppText.priceXL().copyWith(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TvButton(
                label: 'Tiến hành thanh toán',
                size: TvButtonSize.lg,
                fullWidth: true,
                trailingIcon: const TvIcon('chevron-right', size: 18),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(total: subtotal),
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
