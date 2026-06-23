import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/cart_item.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';
import 'checkout_screen.dart';

/// Cart — line items (unit price + qty stepper + remove), voucher + summary,
/// sticky subtotal + checkout CTA. Mirrors `CartScreen.jsx`.
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
          child: cart.isEmpty ? _EmptyCart() : _CartBody(cart: cart),
        ),
      ],
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
              child: const TvIcon('shopping-cart',
                  size: 34, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text('Giỏ hàng trống', style: AppText.h2()),
            const SizedBox(height: 4),
            Text(
              'Khám phá hàng nghìn sản phẩm công nghệ đỉnh cao.',
              textAlign: TextAlign.center,
              style: AppText.body(AppColors.textSecondary).copyWith(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TvButton(
              label: 'Mua sắm ngay',
              leadingIcon: const TvIcon('compass', size: 18),
              onPressed: () => context.read<AppNav>().goExplore(),
            ),
          ],
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            children: [
              for (final item in cart.items) ...[
                _CartLine(item: item),
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
    return TvCard(
      padding: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: ColoredBox(
                color: Colors.black,
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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => cart.remove(item.id),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: TvIcon('trash-2',
                            size: 18, color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
            TvInput(
              dashed: true,
              leading: const TvIcon('ticket-percent'),
              hintText: 'Nhập mã giảm giá',
              trailing: Text('ÁP DỤNG',
                  style: AppText.label(AppColors.textAccent)
                      .copyWith(fontSize: 11, letterSpacing: 0.88)),
            ),
            const SizedBox(height: 14),
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
            style: AppText.body(AppColors.textSecondary).copyWith(fontSize: 13)),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.bgBase],
          stops: [0, 0.22],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                        style: AppText.h2()
                            .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      formatVnd(subtotal),
                      style: AppText.price().copyWith(
                          fontSize: 24, shadows: AppEffects.textGlowCyan),
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
