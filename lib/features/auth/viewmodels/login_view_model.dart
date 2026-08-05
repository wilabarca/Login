import 'dart:async';

import 'package:flutter/material.dart';

import '../../security/data/secure_storage_service.dart';
import '../../security/data/device_registration_service.dart';
import '../../security/data/local_auth_storage.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  bool _showInactivityWarning = false;
  int _secondsRemaining = _timeout.inSeconds;

  String? _currentUserId;
  String? _currentUsername;

  bool _fcmTokenAvailable = false;
  bool _firestoreRegistered = false;
  String? _registrationError;

  Timer? _inactivityTimer;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _warningThresholdSeconds = 10;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  bool get showInactivityWarning => _showInactivityWarning;
  int get secondsRemaining => _secondsRemaining;

  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;

  bool get fcmTokenAvailable => _fcmTokenAvailable;
  bool get firestoreRegistered => _firestoreRegistered;
  String? get registrationError => _registrationError;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _registrationError = null;

    await Future.delayed(const Duration(milliseconds: 400));

    if (username.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Ingresa usuario y contraseña.';
      _setLoading(false);
      return false;
    }

    final user = await LocalAuthStorage.instance.login(
      username: username,
      password: password,
    );

    if (user == null) {
      _errorMessage = 'Credenciales incorrectas.';
      _setLoading(false);
      return false;
    }

    await _completeLogin(user);

    return true;
  }

  Future<bool> register({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _registrationError = null;

    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final user = await LocalAuthStorage.instance.register(
        username: username,
        password: password,
      );

      await _completeLogin(user);

      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _completeLogin(LocalAuthUser user) async {
    _currentUserId = user.id;
    _currentUsername = user.username;

    // Se usa user.username como remoteUserId
    await SecureStorageService.instance.seedSensitiveData(
      remoteUserId: user.username,
    );

    // Registramos en Firestore y esperamos el resultado
    final result = await DeviceRegistrationService.instance.registerDevice(
      remoteUserId: user.username,
    );

    _fcmTokenAvailable = result.fcmTokenAvailable;
    _firestoreRegistered = result.firestoreRegistered;
    _registrationError = result.errorMessage;

    _isLoggedIn = true;
    _errorMessage = null;

    _startInactivityTimer();

    _setLoading(false);
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _showInactivityWarning = false;
    _secondsRemaining = _timeout.inSeconds;
    _currentUserId = null;
    _currentUsername = null;
    _fcmTokenAvailable = false;
    _firestoreRegistered = false;
    _registrationError = null;

    await LocalAuthStorage.instance.logout();

    _stopInactivityTimer();

    notifyListeners();
  }

  void resetInactivityTimer() {
    if (!_isLoggedIn) return;

    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _stopInactivityTimer();

    _secondsRemaining = _timeout.inSeconds;
    _showInactivityWarning = false;

    notifyListeners();

    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isLoggedIn) {
        _stopInactivityTimer();
        return;
      }

      _secondsRemaining--;

      if (_secondsRemaining <= _warningThresholdSeconds) {
        _showInactivityWarning = true;
      }

      if (_secondsRemaining <= 0) {
        _sessionExpired();
        return;
      }

      notifyListeners();
    });
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _sessionExpired() {
    _isLoggedIn = false;
    _showInactivityWarning = false;
    _secondsRemaining = _timeout.inSeconds;
    _currentUserId = null;
    _currentUsername = null;

    _stopInactivityTimer();

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopInactivityTimer();
    super.dispose();
  }
}
