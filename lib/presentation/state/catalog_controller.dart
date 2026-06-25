import 'package:flutter/foundation.dart';

import '../../data/models/product.dart';
import '../../data/services/product_service.dart';

/// Loads the product catalog ONCE and shares it across the Explore and Search
/// tabs, so the two [ProductListScreen] instances in the shell's IndexedStack
/// don't each hit the backend. Categories are derived from the loaded products
/// (no separate request).
class CatalogController extends ChangeNotifier {
  CatalogController({ProductService? service})
      : _service = service ?? ProductService() {
    load();
  }

  final ProductService _service;
  List<Product> _products = const [];
  List<String> _categories = const ['Tất cả'];
  bool _loading = true;

  bool get isLoading => _loading;
  List<Product> get products => _products;
  List<String> get categories => _categories;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _products = await _service.fetchProducts();
      _categories = await _service.fetchCategories();
    } catch (_) {
      _products = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Client-side filter by category + free-text query (name + brand).
  List<Product> filter({required String category, required String query}) {
    final q = query.trim().toLowerCase();
    return _products.where((p) {
      final matchesCat = category == 'Tất cả' || p.categoryName == category;
      final matchesQuery =
          q.isEmpty || '${p.name} ${p.brand}'.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();
  }
}
