/// Một danh mục từ `GET /api/Category` (CategoryResponseDTO):
/// `{ id, name, description? }`.
///
/// Khác với chip lọc (chỉ cần tên — `ProductService.fetchCategories`),
/// form thêm sản phẩm cần cả `id` (Guid) để gửi `categoryId` lên
/// `POST /api/Products`. Không đặt tên `Category` để tránh đụng annotation
/// `Category` của Flutter foundation.
class CategoryOption {
  const CategoryOption({required this.id, required this.name});

  final String id;
  final String name;

  factory CategoryOption.fromJson(Map<String, dynamic> json) => CategoryOption(
        id: '${json['id'] ?? ''}',
        name: json['name'] as String? ?? '',
      );
}
