import 'dart:async';

import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  Timer? _warningTimer;
  Timer? _countdownTimer;

  bool _showInactivityWarning = false;
  int _secondsRemaining = 10;

  // Tiempo total sin uso antes de cerrar sesión.
  static const Duration _inactivityTimeout = Duration(seconds: 30);

  // Cuánto tiempo antes del cierre se mostrará el aviso.
  static const Duration _warningBeforeLogout = Duration(seconds: 10);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  bool get showInactivityWarning => _showInactivityWarning;
  int get secondsRemaining => _secondsRemaining;

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
      _errorMessage = null;
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
    _errorMessage = null;
    _showInactivityWarning = false;
    _stopInactivityTimers();
    notifyListeners();
  }

  void resetInactivityTimer() {
    if (!_isLoggedIn) return;

    _showInactivityWarning = false;
    _secondsRemaining = _warningBeforeLogout.inSeconds;

    _startInactivityTimer();
    notifyListeners();
  }

  void _startInactivityTimer() {
    _stopInactivityTimers();

    _showInactivityWarning = false;
    _secondsRemaining = _warningBeforeLogout.inSeconds;

    final warningDelay = Duration(
      seconds: _inactivityTimeout.inSeconds - _warningBeforeLogout.inSeconds,
    );

    _warningTimer = Timer(warningDelay, _showWarningAndStartCountdown);
  }

  void _showWarningAndStartCountdown() {
    if (!_isLoggedIn) return;

    _showInactivityWarning = true;
    _secondsRemaining = _warningBeforeLogout.inSeconds;
    notifyListeners();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!_isLoggedIn) {
          timer.cancel();
          return;
        }

        _secondsRemaining--;

        if (_secondsRemaining <= 0) {
          timer.cancel();
          _expireSession();
          return;
        }

        notifyListeners();
      },
    );
  }

  void _expireSession() {
    _isLoggedIn = false;
    _showInactivityWarning = false;
    _errorMessage = 'Tu sesión se cerró por inactividad.';
    _stopInactivityTimers();
    notifyListeners();
  }

  void _stopInactivityTimers() {
    _warningTimer?.cancel();
    _countdownTimer?.cancel();

    _warningTimer = null;
    _countdownTimer = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopInactivityTimers();
    super.dispose();
  }
}