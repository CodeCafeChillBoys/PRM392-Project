import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // Cập nhật UI hiển thị loading vòng xoay

    try {
      // Gọi lên BE thông qua Repository
      final response = await _authRepository.login(username, password);
      
      // Thành công
      _isAuthenticated = true;
      // TODO: Bạn có thể lưu Token vào local storage (SharedPreferences) ở đây
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Bị lỗi (sai pass, mất mạng...)
      _isAuthenticated = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    // TODO: Xóa token trong local storage
    notifyListeners();
  }
}
