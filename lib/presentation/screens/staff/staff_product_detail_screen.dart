import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../widgets/widgets.dart';

/// Chi tiết sản phẩm cho Staff — CHỈ ĐỌC (đối chiếu thông tin, tồn kho).
/// Không có nút giỏ hàng; sửa/xoá chưa làm vì BE chưa có endpoint
/// (xem spec 2026-07-02). Màn push full-screen nên tự bọc Scaffold.
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
                        color: Colors.black,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
