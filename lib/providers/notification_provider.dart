import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  void incrementUnread() {
    _unreadCount++;
    notifyListeners();
  }
}
