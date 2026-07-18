import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/product_service.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import 'add_product_screen.dart';
import 'staff_product_detail_screen.dart';

/// Trang Staff — quản lý sản phẩm: xem danh sách + tồn kho, tìm kiếm, lọc
/// theo danh mục, thêm sản phẩm mới; sửa qua màn chi tiết (spec 2026-07-03).
/// BE chưa có API xoá. Tab-page: tự có app bar, không Scaffold.
class StaffProductsScreen extends StatefulWidget {
  const StaffProductsScreen({super.key});

  @override
  State<StaffProductsScreen> createState() => _StaffProductsScreenState();
}

class _StaffProductsScreenState extends State<StaffProductsScreen> {
  final _service = ProductService();
  final _auth = AuthService();
  final _searchCtrl = TextEditingController();

  List<Product> _products = [];
  List<String> _categories = const ['Tất cả'];
  bool _loading = true;
  String _query = '';
  String _category = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await _service.fetchProducts();
      final categories = await _service.fetchCategories();
      if (mounted) {
        setState(() {
          _products = products;
          _categories = categories;
        });
      }
    } catch (_) {
      if (mounted) {
        TvToast.show(context, 'Không tải được danh sách sản phẩm.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// BE `GET /api/Products` không nhận query param → lọc client-side
  /// (giống cách CatalogController.filter làm cho màn shop).
  List<Product> get _visible {
    final q = _query.trim().toLowerCase();
    return _products.where((p) {
      final matchesCat = _category == 'Tất cả' || p.categoryName == _category;
      final matchesQuery =
          q.isEmpty || '${p.name} ${p.brand}'.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();
  }

  Future<void> _openAdd() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (created == true && mounted) {
      TvToast.show(context, 'Đã thêm sản phẩm.');
      await _load();
    }
  }

  Future<void> _openDetail(Product p) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StaffProductDetailScreen(product: p)),
    );
    if (changed == true && mounted) {
      TvToast.show(context, 'Đã cập nhật sản phẩm.');
      await _load();
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TvAppBar(
          mode: TvAppBarMode.page,
          title: 'Quản lý sản phẩm',
          actions: [
            TvIconButton(
              icon: TvIcon('plus', color: AppColors.textAccent),
              tooltip: 'Thêm sản phẩm',
              onPressed: _openAdd,
            ),
            TvIconButton(
              icon: TvIcon('log-out', color: AppColors.textAccent),
              tooltip: 'Đăng xuất',
              onPressed: _logout,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TvInput(
            controller: _searchCtrl,
            leading: const TvIcon('search'),
            hintText: 'Tìm theo tên, hãng...',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = _categories[i];
              return _CategoryChip(
                label: c,
                selected: c == _category,
                onTap: () => setState(() => _category = c),
              );
            },
          ),
        ),
        Expanded(child: _list()),
      ],
    );
  }

  /// Sản phẩm "ma" cho skeleton.
  static const _ghost = Product(
    id: 'ghost',
    name: 'Sản phẩm đang tải về',
    brand: 'TECHVOID',
    categoryName: 'Đang tải',
    price: 12000000,
    stockQuantity: 5,
    imageUrl: '',
    description: '',
  );

  Widget _list() {
    if (_loading) {
      return Skeletonizer(
        effect: ShimmerEffect(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
        ),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter, 14, AppSpacing.gutter, 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => _productCard(_ghost),
        ),
      );
    }
    final items = _visible;
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.textAccent,
      backgroundColor: AppColors.bgSurface,
      child: items.isEmpty
          ? _empty()
          : ListView.separated(
              key: ValueKey('$_category|$_query'),
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter, 14, AppSpacing.gutter, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _productCard(items[i])
                  .animate(delay: AppEffects.staggerStep * i.clamp(0, 6))
                  .fadeIn(
                      duration: AppEffects.durEnter,
                      curve: AppEffects.easeStandard)
                  .moveY(
                    begin: AppEffects.entranceRise,
                    end: 0,
                    duration: AppEffects.durEnter,
                    curve: AppEffects.easeStandard,
                  ),
            ),
    );
  }

  Widget _empty() {
    final filtered = _query.trim().isNotEmpty || _category != 'Tất cả';
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
            child: TvIcon('package', size: 44, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            filtered ? 'Không có sản phẩm khớp bộ lọc' : 'Chưa có sản phẩm nào',
            style: AppText.body(AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _productCard(Product p) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(p),
      child: TvCard(
        padding: 12,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ColoredBox(
                  color: AppColors.ink900,
                  child: ProductImage(url: p.imageUrl, dimmed: p.isSoldOut),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong()),
                  const SizedBox(height: 2),
                  Text('${p.brand} · ${p.categoryName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.xs(AppColors.textTertiary)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatVnd(p.price),
                          style: AppText.price().copyWith(fontSize: 14)),
                      ProductStockBadge(p.stockQuantity),
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

/// Chip lọc danh mục — copy từ `_CategoryChip` private của
/// `product_list_screen.dart` (giữ private theo tiền lệ của team; nếu sau
/// này chỗ thứ 3 cần thì mới tách ra widgets/). Giữ y hệt style bản gốc
/// (Container/height/border-width/glow/AppText.label) để 2 màn đồng bộ
/// thị giác — KHÔNG theo bản AnimatedContainer nháp trong task brief.
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
          boxShadow: selected ? AppEffects.glowAccentSm : null,
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
