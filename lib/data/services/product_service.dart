import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../models/category_option.dart';
import '../models/product.dart';
import 'api_client.dart';
import 'mock_data.dart';

/// Reads & writes the TechStoreAPI Product module (`GET /api/Products`,
/// `GET /api/Products/{id}`, `POST /api/Products`, `GET /api/Category`).
/// Returns mock data while [AppConfig.useMockData].
class ProductService {
  ProductService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  /// Sản phẩm Staff tạo trong phiên chạy mock — MockData.products là `const`
  /// nên không chèn vào được; giữ riêng để demo offline vẫn thấy SP mới.
  static final List<Product> _mockCreated = [];

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

  /// Danh mục kèm id (`GET /api/Category`) — form thêm sản phẩm cần
  /// `categoryId` (Guid), khác [fetchCategories] chỉ trả tên cho chip lọc.
  Future<List<CategoryOption>> fetchCategoryOptions() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return [
        for (final name in MockData.categories)
          if (name != 'Tất cả') CategoryOption(id: 'mock-$name', name: name),
      ];
    }
    final json = await _client.get(ApiConfig.categories);
    final List<dynamic> list = (json is Map<String, dynamic> && json['data'] is List)
        ? (json['data'] as List)
        : (json is List ? json : []);
    return list
        .map((e) => CategoryOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tạo sản phẩm mới (`POST /api/Products`, body khớp CreateProductDTO).
  /// [categoryName] chỉ để dựng Product hiển thị ở chế độ mock (BE thật tự
  /// trả về categoryName). Sau khi tạo, BE broadcast notification
  /// "Siêu phẩm mới" tới mọi thiết bị — không cần FE làm gì thêm.
  Future<Product> createProduct({
    required String name,
    required String brand,
    required double price,
    required int stockQuantity,
    required String categoryId,
    required String categoryName,
    String? imageUrl,
    String? description,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      final created = Product(
        id: 'mock-sp-${_mockCreated.length + 1}',
        name: name,
        brand: brand,
        categoryName: categoryName,
        price: price,
        stockQuantity: stockQuantity,
        imageUrl: imageUrl ?? '',
        description: description ?? '',
      );
      _mockCreated.insert(0, created);
      return created;
    }
    final json = await _client.post(ApiConfig.products, body: {
      'name': name,
      'brand': brand,
      'price': price,
      'stockQuantity': stockQuantity,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (description != null && description.isNotEmpty)
        'description': description,
      'categoryId': categoryId,
    });
    final Map<String, dynamic> data =
        (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>)
            ? (json['data'] as Map<String, dynamic>)
            : (json is Map<String, dynamic> ? json : {});
    return Product.fromJson(data);
  }

  /// All products, optionally filtered by [category] and a free-text [query]
  /// (name + brand). The same filtering the backend `?category=&q=` would do.
  Future<List<Product>> fetchProducts({String? category, String? query}) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return _filter([..._mockCreated, ...MockData.products],
          category: category, query: query);
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
