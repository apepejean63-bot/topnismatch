import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _api.isLoggedIn();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.login(email, password);
      await _api.saveToken(response['token']);
      _currentUser = response;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Email o contraseña incorrectos';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.register(data);
      await _api.saveToken(response['token']);
      _currentUser = response;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrarse. Intenta de nuevo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (e) {
      // ignore
    }
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
