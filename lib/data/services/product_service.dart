import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../models/product.dart';
import 'api_client.dart';
import 'mock_data.dart';

/// Reads the TechStoreAPI Product module (`GET /api/Products`,
/// `GET /api/Products/{id}`). Returns mock data while [AppConfig.useMockData].
class ProductService {
  ProductService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  /// Category chips. (`'Tất cả'` is the "all" sentinel — not a real category.)
  Future<List<String>> fetchCategories() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockData.categories;
    }
    final json = await _client.get(ApiConfig.categories);
    final List<dynamic> list = (json is Map<String, dynamic> && json['data'] is List)
        ? (json['data'] as List)
        : (json is List ? json : []);
    final names = list.map((e) => e['name'] as String).toList();
    return ['Tất cả', ...names];
  }


  /// All products, optionally filtered by [category] and a free-text [query]
  /// (name + brand). The same filtering the backend `?category=&q=` would do.
  Future<List<Product>> fetchProducts({String? category, String? query}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return _filter(MockData.products, category: category, query: query);
    }
    final json = await _client.get(ApiConfig.products, query: {
      if (category != null && category != 'Tất cả') 'category': category,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    });
    final List<dynamic> list = (json is Map<String, dynamic> && json['data'] is List)
        ? (json['data'] as List)
        : (json is List ? json : []);
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> fetchProductById(String id) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return MockData.products.firstWhere((p) => p.id == id);
    }
    final json = await _client.get(ApiConfig.productById(id));
    final Map<String, dynamic> data = (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : (json is Map<String, dynamic> ? json : {});
    return Product.fromJson(data);
  }

  List<Product> _filter(List<Product> source,
      {String? category, String? query}) {
    final q = (query ?? '').trim().toLowerCase();
    return source.where((p) {
      final matchesCat =
          category == null || category == 'Tất cả' || p.categoryName == category;
      final matchesQuery =
          q.isEmpty || '${p.name} ${p.brand}'.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();
  }
}
