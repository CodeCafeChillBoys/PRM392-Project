/// Một đánh giá sản phẩm — khớp BE `ReviewResponseDTO`.
/// Parse tolerant nhiều tên key (kiểu OrderModel).
class Review {
  const Review({
    required this.id,
    required this.productId,
    required this.customerName,
    required this.rating,
    this.comment = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.isMine = false,
  });

  final String id;
  final String productId;
  final String customerName;
  final int rating;
  final String comment;
  final String createdAt;
  final String updatedAt;

  /// Đánh giá này của user đang đăng nhập (BE set theo JWT) → cho phép sửa/xoá.
  final bool isMine;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: '${json['id'] ?? ''}',
    productId: '${json['productId'] ?? ''}',
    customerName:
        json['customerName'] as String? ??
        json['fullName'] as String? ??
        'Khách',
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String? ?? '',
    createdAt: '${json['createdAt'] ?? ''}',
    updatedAt: '${json['updatedAt'] ?? ''}',
    isMine: json['isMine'] as bool? ?? false,
  );
}
