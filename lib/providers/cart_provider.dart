import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<dynamic> _cartItems = [];
  List<dynamic> get cartItems => _cartItems;

  void addToCart(dynamic item) {
    _cartItems.add(item);
    notifyListeners();
  }
}
