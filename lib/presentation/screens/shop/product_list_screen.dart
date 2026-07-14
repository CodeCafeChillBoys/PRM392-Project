import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/product.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../state/catalog_controller.dart';
import '../../widgets/widgets.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import 'product_detail_screen.dart';

/// Product list — VOID LUXE editorial: header "Khám phá" cỡ display, search,
/// category chips gold, lưới sản phẩm SliverGrid lazy với entrance stagger,
/// skeleton loading thay spinner, và card→detail morph bằng [OpenContainer].
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

  /// Sản phẩm "ma" cho skeleton — layout thật, dữ liệu giả, Skeletonizer
  /// tự phủ bone lên chữ/ảnh.
  static const _ghost = Product(
    id: 'ghost',
    name: 'Sản phẩm đang tải',
    brand: 'TECHVOID',
    categoryName: 'Đang tải',
    price: 30000000,
    stockQuantity: 1,
    imageUrl: '',
    description: '',
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          child: catalog.isLoading ? _buildSkeleton() : _buildContent(catalog),
        ),
      ],
    );
  }

  /// Skeleton grid 6 card ma — shimmer trung tính ink800→ink700 (không gold).
  Widget _buildSkeleton() {
    return Skeletonizer(
      effect: const ShimmerEffect(
        baseColor: AppColors.ink800,
        highlightColor: AppColors.ink700,
      ),
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 16, AppSpacing.gutter,
            AppSpacing.bottomNavHeight + 24),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.64,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const ProductCard(product: _ghost),
      ),
    );
  }

  Widget _buildContent(CatalogController catalog) {
    final list = catalog.filter(category: _category, query: _query);
    final categories = catalog.categories;
    final bottomInset = AppSpacing.bottomNavHeight +
        MediaQuery.of(context).padding.bottom +
        24;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header editorial — khoảnh khắc whitespace luxury.
              Padding(
                padding:
                    EdgeInsets.fromLTRB(AppSpacing.gutter, 24, AppSpacing.gutter, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.autofocusSearch ? 'Tìm kiếm' : 'Khám phá',
                      style: AppText.display(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.autofocusSearch
                          ? 'Gõ tên sản phẩm hoặc thương hiệu bạn cần.'
                          : 'Công nghệ tuyển chọn, giá độc quyền.',
                      style: AppText.sm(AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: TvInput(
                  controller: _searchController,
                  autofocus: widget.autofocusSearch,
                  leading: const TvIcon('search'),
                  hintText: 'Tìm kiếm sản phẩm công nghệ...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
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
              const SizedBox(height: 18),
            ],
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 56),
              child: Column(
                children: [
                  Icon(AppIcons.get('search'),
                      size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: 14),
                  Text('Không tìm thấy sản phẩm', style: AppText.h2()),
                  const SizedBox(height: 6),
                  Text(
                    'Thử từ khoá khác hoặc đổi danh mục nhé.',
                    style: AppText.sm(AppColors.textTertiary),
                  ),
                ],
              ).animate().fadeIn(duration: AppEffects.durEnter).moveY(
                  begin: AppEffects.entranceRise,
                  end: 0,
                  curve: AppEffects.easeStandard),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter, 0, AppSpacing.gutter, bottomInset.toDouble()),
            sliver: SliverGrid(
              // Key theo bộ lọc → đổi danh mục/từ khoá là stagger chạy lại.
              key: ValueKey('$_category|$_query'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final p = list[i];
                  final row = i ~/ 2;
                  final col = i % 2;
                  return OpenContainer(
                    transitionType: ContainerTransitionType.fadeThrough,
                    transitionDuration: AppEffects.durMorph,
                    closedElevation: 0,
                    openElevation: 0,
                    closedColor: Colors.transparent,
                    middleColor: AppColors.bgBase,
                    openColor: AppColors.bgBase,
                    closedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    openBuilder: (_, _) => ProductDetailScreen(product: p),
                    closedBuilder: (_, open) => ProductCard(
                      product: p,
                      onTap: open,
                      onAdd: () => _addToCart(p),
                    ),
                  )
                      .animate(
                        delay: Duration(
                            milliseconds:
                                (row * 80 + col * 60).clamp(0, 480)),
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
                      );
                },
                childCount: list.length,
              ),
            ),
          ),
      ],
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
      child: AnimatedContainer(
        duration: AppEffects.durBase,
        curve: AppEffects.easeStandard,
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.goldSoftLine : AppColors.borderDefault,
          ),
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
