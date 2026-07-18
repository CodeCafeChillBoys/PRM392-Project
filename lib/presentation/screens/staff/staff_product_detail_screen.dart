import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../widgets/widgets.dart';
import 'add_product_screen.dart';

/// Chi tiết sản phẩm cho Staff — hiển thị CHỈ ĐỌC (đối chiếu thông tin, tồn
/// kho), có nút Sửa sản phẩm (BE đã có PUT). Không có nút giỏ hàng.
/// Màn push full-screen nên tự bọc Scaffold.
class StaffProductDetailScreen extends StatelessWidget {
  const StaffProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            title: 'Chi tiết sản phẩm',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ColoredBox(
                        color: AppColors.ink900,
                        child: ProductImage(
                          url: product.heroImageUrl,
                          dimmed: product.isSoldOut,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${product.brand} · ${product.categoryName}',
                      style: AppText.xs(AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text(product.name, style: AppText.h2()),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatVnd(product.price), style: AppText.price()),
                      ProductStockBadge(product.stockQuantity),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Mô tả', style: AppText.label()),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? 'Chưa có mô tả.'
                        : product.description,
                    style: AppText.body(product.description.isEmpty
                        ? AppColors.textTertiary
                        : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TvButton(
                    label: 'Sửa sản phẩm',
                    fullWidth: true,
                    leadingIcon: const TvIcon('edit', size: 16),
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => AddProductScreen(initial: product)),
                      );
                      if (updated == true && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
