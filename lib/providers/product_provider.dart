import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  final List<dynamic> _products = [];
  List<dynamic> get products => _products;

  Future<void> fetchProducts() async {
    notifyListeners();
  }
}
