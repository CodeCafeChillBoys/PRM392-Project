/// A product from the TechStoreAPI `Product` module.
///
/// Backend DTO shape (per the API design doc):
/// `{ id, name, brand, price, stockQuantity, imageUrl, description, categoryName, categoryId }`
///
/// [heroImageUrl] is a UI-only convenience (large detail image); the backend
/// currently exposes a single `imageUrl`, so it falls back to that.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryName,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
    required this.description,
    String? heroImageUrl,
    this.categoryId = '',
  }) : heroImageUrl = heroImageUrl ?? imageUrl;

  final String id;
  final String name;
  final String brand;
  final String categoryName;
  final double price;
  final int stockQuantity;
  final String imageUrl;
  final String heroImageUrl;
  final String description;
  final String categoryId;

  bool get isSoldOut => stockQuantity <= 0;
  bool get isLowStock => !isSoldOut && stockQuantity <= 10;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: '${json['id'] ?? json['productId'] ?? ''}',
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        categoryName:
            json['categoryName'] as String? ?? json['category'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
        imageUrl:
            json['imageUrl'] as String? ?? json['img'] as String? ?? '',
        heroImageUrl: json['heroImageUrl'] as String? ?? json['hero'] as String?,
        description: json['description'] as String? ?? '',
        categoryId: '${json['categoryId'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'categoryName': categoryName,
        'price': price,
        'stockQuantity': stockQuantity,
        'imageUrl': imageUrl,
        'description': description,
        'categoryId': categoryId,
      };
}
