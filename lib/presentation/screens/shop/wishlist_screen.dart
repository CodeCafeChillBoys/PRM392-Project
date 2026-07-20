import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/wishlist_service.dart';
import '../../state/app_nav.dart';
import '../../state/catalog_controller.dart';
import '../../state/cart_controller.dart';
import '../../widgets/widgets.dart';
import 'product_detail_screen.dart';

/// Màn "Yêu thích" — lưới sản phẩm khách đã thả tim (lưu local). Nghe
/// [WishlistService] nên bỏ tim là mất khỏi lưới ngay; nghe [CatalogController]
/// để giá/tồn kho luôn mới.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final all = context.watch<CatalogController>().products;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Yêu thích',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: WishlistService.instance.notifier,
              builder: (context, ids, _) {
                final wished = all.where((p) => ids.contains(p.id)).toList();
                if (wished.isEmpty) return _empty(context);
                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    14,
                    AppSpacing.gutter,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 322,
                  ),
                  itemCount: wished.length,
                  itemBuilder: (context, i) {
                    final p = wished[i];
                    return ProductCard(
                      product: p,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: p),
                        ),
                      ),
                      onAdd: () {
                        context.read<CartController>().add(p);
                        TvToast.show(context, 'Đã thêm ${p.name} vào giỏ');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => ListView(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    children: [
      const SizedBox(height: 100),
      Center(
        child: Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentSoft,
            border: Border.all(color: AppColors.accentSoftLine),
          ),
          child: const Icon(Icons.favorite_border, size: 34),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          'Chưa có sản phẩm yêu thích',
          style: AppText.h2().copyWith(fontSize: 18),
        ),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text(
          'Thả tim ở sản phẩm bạn thích để lưu lại đây.',
          textAlign: TextAlign.center,
          style: AppText.sm(AppColors.textTertiary),
        ),
      ),
      const SizedBox(height: 22),
      Center(
        child: SizedBox(
          width: 200,
          child: TvButton(
            label: 'Khám phá ngay',
            variant: TvButtonVariant.gradient,
            onPressed: () {
              context.read<AppNav>().goExplore();
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    ],
  );
}
