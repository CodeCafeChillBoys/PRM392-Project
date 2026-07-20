import '../../core/config/api_config.dart';
import '../models/review.dart';
import 'api_client.dart';

/// Gọi endpoint đánh giá (ReviewsController). GET công khai (ApiClient tự đính
/// token nếu có → biết isMine); POST/PUT/DELETE cần token.
class ReviewService {
  ReviewService({ApiClient? client}) : _client = client ?? apiClient;
  final ApiClient _client;

  Future<List<Review>> fetchReviews(String productId) async {
    final json = await _client.get(ApiConfig.productReviews(productId));
    final list = json is List
        ? json
        : (json is Map ? (json['data'] ?? const []) : const []);
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map(Review.fromJson)
        .toList();
  }

  Future<Review> createReview(
    String productId,
    int rating,
    String comment,
  ) async {
    final json = await _client.post(
      ApiConfig.productReviews(productId),
      body: {'rating': rating, 'comment': comment},
    );
    return Review.fromJson(_asMap(json));
  }

  Future<Review> updateReview(String id, int rating, String comment) async {
    final json = await _client.put(
      ApiConfig.reviewById(id),
      body: {'rating': rating, 'comment': comment},
    );
    return Review.fromJson(_asMap(json));
  }

  Future<void> deleteReview(String id) async {
    await _client.delete(ApiConfig.reviewById(id));
  }

  static Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      return data is Map<String, dynamic> ? data : json;
    }
    return <String, dynamic>{};
  }
}
