import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/product.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../state/catalog_controller.dart';
import '../../widgets/widgets.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import 'product_detail_screen.dart';

/// Product list — search, category chips, 2-column product grid
/// (`GET /api/Products`). Mirrors `ProductListScreen.jsx`.
///
/// This is a tab page: it provides its own brand app bar but no Scaffold/bottom
/// nav (the [RootShell] supplies those).
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.autofocusSearch = false});

  final bool autofocusSearch;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Tất cả';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _addToCart(Product product) {
    context.read<CartController>().add(product);
    TvToast.show(context, 'Đã thêm ${product.name} vào giỏ');
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().count;
    final appNav = context.read<AppNav>();
    final catalog = context.watch<CatalogController>();

    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.brand,
          brand: const TvLogo(),
          actions: [
            TvIconButton(
              icon: const TvIcon('bot'),
              tooltip: 'Trợ lý AI',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
            ),
            TvIconButton(
              icon: const TvIcon('bell'),
              tooltip: 'Thông báo',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            TvIconButton(
              icon: const TvIcon('shopping-cart'),
              badge: cartCount > 0 ? cartCount : null,
              tooltip: 'Giỏ hàng',
              onPressed: appNav.goToCart,
            ),
          ],
        ),
        Expanded(
          child: catalog.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _buildContent(catalog),
        ),
      ],
    );
  }

  Widget _buildContent(CatalogController catalog) {
    final list = catalog.filter(category: _category, query: _query);
    final categories = catalog.categories;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TvInput(
              controller: _searchController,
              autofocus: widget.autofocusSearch,
              leading: const TvIcon('search'),
              hintText: 'Tìm kiếm sản phẩm công nghệ...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                return _CategoryChip(
                  label: c,
                  selected: c == _category,
                  onTap: () => setState(() => _category = c),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('Không tìm thấy sản phẩm phù hợp.',
                    style: AppText.body(AppColors.textTertiary)
                        .copyWith(fontSize: 14)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final p = list[i];
                  return ProductCard(
                    product: p,
                    onTap: () => _openProduct(p),
                    onAdd: () => _addToCart(p),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? AppEffects.glowCyanSm : null,
        ),
        child: Text(
          label,
          style: AppText.label(
            selected ? AppColors.textAccent : AppColors.textSecondary,
          ).copyWith(fontSize: 12.5, letterSpacing: 0.25),
        ),
      ),
    );
  }
}
