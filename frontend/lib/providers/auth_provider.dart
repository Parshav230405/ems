import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isSuperAdmin => _currentUser?.isSuperAdmin ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      final token = res['token'];
      _api.setToken(token);

      _currentUser = UserModel.fromJson(res['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _api.setToken(null);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    if (_api.token == null) return;
    try {
      final res = await _api.get('/auth/me');
      _currentUser = UserModel.fromJson(res['user']);
      notifyListeners();
    } catch (_) {
      logout();
    }
  }

  void updateClientName(String newName) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(clientName: newName);
      notifyListeners();
    }
  }
}
