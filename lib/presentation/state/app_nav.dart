import 'package:flutter/foundation.dart';

/// Drives the selected tab of the main [RootShell] bottom navigation, so code
/// running above the shell (e.g. a pushed product-detail route) can jump tabs.
class AppNav extends ChangeNotifier {
  static const int explore = 0;
  static const int search = 1;
  static const int cart = 2;
  static const int profile = 3;

  int _tabIndex = explore;
  int get tabIndex => _tabIndex;

  void select(int index) {
    if (index == _tabIndex) return;
    _tabIndex = index;
    notifyListeners();
  }

  void goExplore() => select(explore);
  void goToCart() => select(cart);
}
