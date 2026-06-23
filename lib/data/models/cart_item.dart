import 'product.dart';

/// A cart line item — mirrors TechStoreAPI's `CartResponseDTO`:
/// `{ id, productId, productName, productImageUrl, unitPrice, quantity, totalPrice }`.
///
/// [totalPrice] is derived (`unitPrice × quantity`) so the client never trusts
/// a stale server total when the quantity changes locally.
class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brand,
    required this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String productName;
  final String brand;
  final String productImageUrl;
  final double unitPrice;
  final int quantity;

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        productId: productId,
        productName: productName,
        brand: brand,
        productImageUrl: productImageUrl,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
      );

  /// Build a fresh line item from a [Product] (used on "add to cart").
  factory CartItem.fromProduct(Product product, {int quantity = 1, String? id}) =>
      CartItem(
        id: id ?? 'c_${product.id}',
        productId: product.id,
        productName: product.name,
        brand: product.brand,
        productImageUrl: product.imageUrl,
        unitPrice: product.price,
        quantity: quantity,
      );

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: '${json['id'] ?? ''}',
        productId: '${json['productId'] ?? ''}',
        productName: json['productName'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        productImageUrl: json['productImageUrl'] as String? ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'productImageUrl': productImageUrl,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'totalPrice': totalPrice,
      };
}
