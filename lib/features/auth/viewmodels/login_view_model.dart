import 'dart:async';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  Timer? _inactivityTimer;

  static const Duration _timeout = Duration(seconds: 30);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

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
      _isLoggedIn = true;
      _startInactivityTimer();
      _setLoading(false);
      return true;
    }

    _errorMessage = 'Credenciales incorrectas. Usa admin / 1234.';
    _setLoading(false);
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _stopInactivityTimer();
    notifyListeners();
  }

  void resetInactivityTimer() {
    if (_isLoggedIn) {
      _startInactivityTimer();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeout, _sessionExpired);
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _sessionExpired() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
