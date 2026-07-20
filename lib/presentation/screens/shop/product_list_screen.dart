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
import '../../../data/services/api_client.dart';
import '../../../data/services/recently_viewed_service.dart';
import '../../../data/services/wishlist_service.dart';
import '../../state/app_nav.dart';
import '../../state/cart_controller.dart';
import '../../state/catalog_controller.dart';
import '../../widgets/widgets.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import 'home_sections.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart';

/// Cách sắp xếp lưới sản phẩm ở Khám phá.
enum _SortMode { relevant, priceAsc, priceDesc, ratingDesc, nameAsc }

extension _SortModeLabel on _SortMode {
  String get label => switch (this) {
    _SortMode.relevant => 'Liên quan',
    _SortMode.priceAsc => 'Giá thấp → cao',
    _SortMode.priceDesc => 'Giá cao → thấp',
    _SortMode.ratingDesc => 'Đánh giá cao',
    _SortMode.nameAsc => 'Tên A → Z',
  };
}

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

  // ── Lọc + sắp xếp (áp lên lưới sản phẩm, thuần client) ─────────────────────
  _SortMode _sort = _SortMode.relevant;
  final Set<String> _brands = {}; // hãng đã chọn (rỗng = tất cả)
  bool _inStock = false; // chỉ còn hàng
  int _minRating = 0; // 0 = mọi mức, 4 = từ 4★

  int get _activeFilters =>
      _brands.length + (_inStock ? 1 : 0) + (_minRating > 0 ? 1 : 0);

  /// Áp bộ lọc + sắp xếp lên danh sách đã lọc theo danh mục/từ khoá.
  List<Product> _applyFilterSort(List<Product> input) {
    var r = input.where((p) {
      if (_brands.isNotEmpty && !_brands.contains(p.brand)) return false;
      if (_inStock && p.isSoldOut) return false;
      if (_minRating > 0 && p.averageRating < _minRating) return false;
      return true;
    }).toList();
    switch (_sort) {
      case _SortMode.priceAsc:
        r.sort((a, b) => a.price.compareTo(b.price));
      case _SortMode.priceDesc:
        r.sort((a, b) => b.price.compareTo(a.price));
      case _SortMode.ratingDesc:
        r.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case _SortMode.nameAsc:
        r.sort((a, b) => a.name.compareTo(b.name));
      case _SortMode.relevant:
        break; // giữ nguyên thứ tự BE
    }
    return r;
  }

  // ── Thanh Lọc / Sắp xếp trên lưới ──────────────────────────────────────────
  Widget _sortFilterBar(CatalogController catalog) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 14),
      child: Row(
        children: [
          Expanded(
            child: _barPill(
              icon: 'chevron-down',
              label: 'Sắp xếp: ${_sort.label}',
              onTap: _showSortSheet,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _barPill(
              icon: 'sliders-horizontal',
              label: _activeFilters > 0 ? 'Bộ lọc · $_activeFilters' : 'Bộ lọc',
              active: _activeFilters > 0,
              onTap: () => _showFilterSheet(catalog),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barPill({
    required String icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.accentSoft : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: active ? AppColors.accentSoftLine : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TvIcon(
              icon,
              size: 16,
              color: active ? AppColors.textAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sm(
                  active ? AppColors.textAccent : AppColors.textPrimary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _sheetShell('Sắp xếp theo', [
        for (final m in _SortMode.values)
          PressableScale(
            onTap: () {
              setState(() => _sort = m);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _sort == m
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: _sort == m
                        ? AppColors.textAccent
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    m.label,
                    style: AppText.body().copyWith(
                      fontSize: 15,
                      fontWeight: _sort == m
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }

  void _showFilterSheet(CatalogController catalog) {
    final brands =
        catalog.products
            .map((p) => p.brand)
            .where((b) => b.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final tmpBrands = Set<String>.from(_brands);
    var tmpInStock = _inStock;
    var tmpRating = _minRating;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _sheetShell('Bộ lọc', [
          Text('Thương hiệu', style: AppText.label()),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in brands)
                _chip(
                  b,
                  tmpBrands.contains(b),
                  () => setSheet(
                    () => tmpBrands.contains(b)
                        ? tmpBrands.remove(b)
                        : tmpBrands.add(b),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Đánh giá', style: AppText.label()),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip(
                'Tất cả',
                tmpRating == 0,
                () => setSheet(() => tmpRating = 0),
              ),
              const SizedBox(width: 8),
              _chip(
                'Từ 4★',
                tmpRating == 4,
                () => setSheet(() => tmpRating = 4),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chỉ hiện còn hàng',
                style: AppText.body().copyWith(fontSize: 15),
              ),
              Switch(
                value: tmpInStock,
                activeThumbColor: AppColors.accent,
                onChanged: (v) => setSheet(() => tmpInStock = v),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TvButton(
                  label: 'Xoá lọc',
                  variant: TvButtonVariant.ghost,
                  size: TvButtonSize.lg,
                  onPressed: () {
                    setState(() {
                      _brands.clear();
                      _inStock = false;
                      _minRating = 0;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TvButton(
                  label: 'Áp dụng',
                  size: TvButtonSize.lg,
                  onPressed: () {
                    setState(() {
                      _brands
                        ..clear()
                        ..addAll(tmpBrands);
                      _inStock = tmpInStock;
                      _minRating = tmpRating;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? AppColors.accentSoftLine : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppText.sm(
            selected ? AppColors.textAccent : AppColors.textSecondary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _sheetShell(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.h2().copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

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

  /// Lời chào theo giờ máy — Home "sống" hơn tiêu đề tĩnh, và gọi tên khách
  /// nếu đã đăng nhập (lấy tên đầu cho gọn).
  String _greeting() {
    final h = DateTime.now().hour;
    final part = h < 11
        ? 'Chào buổi sáng'
        : h < 14
        ? 'Chào buổi trưa'
        : h < 18
        ? 'Chào buổi chiều'
        : 'Chào buổi tối';
    final name = apiClient.userName?.trim();
    if (name == null || name.isEmpty) return part;
    final first = name.split(' ').last; // người Việt gọi theo tên cuối
    return '$part,\n$first';
  }

  void _openDetail(Product p) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)));

  /// Sản phẩm "vừa xem" — id lấy từ local, DỮ LIỆU lấy từ catalog hiện tại nên
  /// giá/tồn kho luôn mới; id không còn trong catalog thì tự rụng.
  List<Product> _recentlyViewed(CatalogController catalog) {
    final ids = RecentlyViewedService.instance.ids;
    if (ids.isEmpty || catalog.products.isEmpty) return const [];
    final byId = {for (final p in catalog.products) p.id: p};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ].take(8).toList();
  }

  /// VOID PICKS — "biên tập viên chọn". Chọn tất định theo NGÀY (không Random)
  /// để mỗi ngày đổi một món mà mở lại app trong ngày vẫn thấy y nguyên.
  Product? _pick(CatalogController catalog) {
    final inStock = catalog.products
        .where((p) => !p.isSoldOut)
        .toList(growable: false);
    if (inStock.isEmpty) return null;
    final now = DateTime.now();
    final dayIndex = now.year * 1000 + now.month * 40 + now.day;
    return inStock[dayIndex % inStock.length];
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().count;
    final appNav = context.read<AppNav>();
    final catalog = context.watch<CatalogController>();

    // Header kính ĐÈ lên nội dung cuộn (Green-SM/iOS): content cuộn phía sau
    // → glass mới thật sự "ăn" màu (lời chào lớn + banner nhoè qua kính).
    return Stack(
      children: [
        Positioned.fill(
          child: catalog.isLoading ? _buildSkeleton() : _buildContent(catalog),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TvAppBar(
            mode: TvAppBarMode.brand,
            glass: true,
            brand: const TvLogo(),
            actions: [
              TvIconButton(
                icon: const TvIcon('bot'),
                tooltip: 'Trợ lý AI',
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
              ),
              TvIconButton(
                icon: const TvIcon('bell'),
                tooltip: 'Thông báo',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: WishlistService.instance.notifier,
                builder: (context, ids, _) => TvIconButton(
                  icon: const TvIcon('heart'),
                  badge: ids.isNotEmpty ? ids.length : null,
                  tooltip: 'Yêu thích',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  ),
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
        ),
      ],
    );
  }

  /// Chiều cao header kính (status bar + bar 56) — content chừa đúng chỗ này ở
  /// đỉnh để không bị header che khi chưa cuộn.
  double _headerInset(BuildContext context) =>
      MediaQuery.of(context).padding.top + 56;

  /// Skeleton grid 6 card ma — shimmer trung tính ink800→ink700 (không gold).
  Widget _buildSkeleton() {
    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight,
      ),
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          _headerInset(context) + 16,
          AppSpacing.gutter,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          // Chiều cao ô CỐ ĐỊNH (không co theo bề rộng như childAspectRatio) — đủ
          // chứa card kể cả dòng đánh giá ở mọi bề rộng máy; máy hẹp chỉ dư chỗ,
          // không bao giờ tràn (overflow "BOTTOM OVERFLOWED").
          mainAxisExtent: 322,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const ProductCard(product: _ghost),
      ),
    );
  }

  Widget _buildContent(CatalogController catalog) {
    final list = _applyFilterSort(
      catalog.filter(category: _category, query: _query),
    );
    final categories = catalog.categories;
    // extendBody đã bơm chiều cao nav nổi vào MediaQuery.padding.bottom → chỉ
    // cần thêm khoảng thở, KHÔNG cộng bottomNavHeight nữa (tránh chừa gấp đôi).
    final bottomInset = MediaQuery.of(context).padding.bottom + 24;
    // Chế độ "khám phá" thuần (không search/filter, không phải tab Tìm kiếm)
    // → hiện các tầng merchandising: banner, category tiles, flash sale.
    final merchMode =
        !widget.autofocusSearch &&
        _query.trim().isEmpty &&
        _category == 'Tất cả';

    // Pull-to-refresh: dùng RefreshIndicator chuẩn (tin cậy trên mọi physics),
    // nhuộm theo brand thay vì tự viết indicator.
    return RefreshIndicator(
      onRefresh: () => context.read<CatalogController>().load(),
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      // Spinner hiện DƯỚI header kính (không bị che).
      edgeOffset: _headerInset(context),
      child: CustomScrollView(
        // Luôn cho phép kéo dù nội dung ngắn hơn màn.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header editorial — chừa đỉnh cho header kính đè lên (content
                // cuộn phía sau nó), rồi tới khoảnh khắc whitespace luxury.
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    _headerInset(context) + 8,
                    AppSpacing.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.autofocusSearch ? 'Tìm kiếm' : _greeting(),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
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
          // ── Merchandising layers (chỉ ở chế độ khám phá) ──────────────────
          if (merchMode) ...[
            SliverToBoxAdapter(
              child:
                  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HomeBannerCarousel(
                            onOpenAi: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChatScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          CategoryTilesRow(
                            categories: categories
                                .where((c) => c != 'Tất cả')
                                .toList(),
                            onSelect: (c) => setState(() => _category = c),
                          ),
                          const SizedBox(height: 20),
                          FlashSaleStrip(
                            products: catalog.products,
                            onOpen: _openDetail,
                          ),
                          // "Vừa xem" — chỉ hiện khi khách đã xem sản phẩm nào đó.
                          if (_recentlyViewed(catalog).isNotEmpty) ...[
                            const SizedBox(height: 24),
                            RecentlyViewedStrip(
                              products: _recentlyViewed(catalog),
                              onOpen: _openDetail,
                            ),
                          ],
                          if (_pick(catalog) != null) ...[
                            const SizedBox(height: 26),
                            VoidPicksSection(
                              product: _pick(catalog)!,
                              onOpen: () => _openDetail(_pick(catalog)!),
                            ),
                          ],
                          const SizedBox(height: 22),
                          const TrustStrip(),
                          const SizedBox(height: 26),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.gutter,
                            ),
                            child: Text(
                              'TẤT CẢ SẢN PHẨM',
                              style: AppText.label(
                                AppColors.textPrimary,
                              ).copyWith(fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      )
                      .animate()
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
          ],
          SliverToBoxAdapter(child: _sortFilterBar(catalog)),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 56),
                child:
                    Column(
                          children: [
                            Icon(
                              AppIcons.get('search'),
                              size: 40,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Không tìm thấy sản phẩm',
                              style: AppText.h2(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Thử từ khoá khác hoặc đổi danh mục nhé.',
                              style: AppText.sm(AppColors.textTertiary),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: AppEffects.durEnter)
                        .moveY(
                          begin: AppEffects.entranceRise,
                          end: 0,
                          curve: AppEffects.easeStandard,
                        ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                bottomInset.toDouble(),
              ),
              sliver: SliverGrid(
                // Key theo bộ lọc/sắp xếp → đổi là stagger chạy lại.
                key: ValueKey(
                  '$_category|$_query|${_sort.index}|${_brands.length}|$_inStock|$_minRating',
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  // Chiều cao ô CỐ ĐỊNH (không co theo bề rộng như childAspectRatio) — đủ
                  // chứa card kể cả dòng đánh giá ở mọi bề rộng máy; máy hẹp chỉ dư chỗ,
                  // không bao giờ tràn (overflow "BOTTOM OVERFLOWED").
                  mainAxisExtent: 322,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
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
                          milliseconds: (row * 80 + col * 60).clamp(0, 480),
                        ),
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
                }, childCount: list.length),
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
