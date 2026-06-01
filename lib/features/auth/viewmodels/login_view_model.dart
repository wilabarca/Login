import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    await Future.delayed(const Duration(milliseconds: 500));

    if (username.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Ingresa usuario y contraseña.';
      _setLoading(false);
      return false;
    }

    // Login local de prueba. No usa API.
    if (username.trim() == 'admin' && password.trim() == '1234') {
      _setLoading(false);
      return true;
    }

    _errorMessage = 'Credenciales incorrectas. Usa admin / 1234.';
    _setLoading(false);
    return false;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}