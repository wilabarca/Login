import 'package:flutter/material.dart';

import '../data/location_security_service.dart';

enum FakeGpsStatus {
  checking,
  allowed,
  blocked,
  locationDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class FakeGpsViewModel extends ChangeNotifier {
  FakeGpsViewModel(this._locationSecurityService);

  final LocationSecurityService _locationSecurityService;

  FakeGpsStatus _status = FakeGpsStatus.checking;
  String _message = 'Validando seguridad de ubicación...';

  FakeGpsStatus get status => _status;
  String get message => _message;

  bool get canContinue => _status == FakeGpsStatus.allowed;
  bool get isChecking => _status == FakeGpsStatus.checking;

  // Llamado en web: salta la validación GPS y permite continuar
  void skipValidation() {
    _setState(FakeGpsStatus.allowed, 'Ubicación válida.');
  }

  Future<void> validateDeviceLocation() async {
    _setState(
      FakeGpsStatus.checking,
      'Validando seguridad de ubicación...',
    );

    try {
      final isFakeGpsEnabled =
          await _locationSecurityService.isFakeGpsEnabled();

      if (isFakeGpsEnabled) {
        _setState(
          FakeGpsStatus.blocked,
          'Se detectó una ubicación simulada. Desactiva el Fake GPS para continuar.',
        );
        return;
      }

      _setState(FakeGpsStatus.allowed, 'Ubicación válida.');
    } on LocationServiceDisabledException {
      _setState(
        FakeGpsStatus.locationDisabled,
        'Activa la ubicación del dispositivo para continuar.',
      );
    } on LocationPermissionDeniedException {
      _setState(
        FakeGpsStatus.permissionDenied,
        'Debes conceder permiso de ubicación para validar el dispositivo.',
      );
    } on LocationPermissionDeniedForeverException {
      _setState(
        FakeGpsStatus.permissionDeniedForever,
        'El permiso de ubicación fue denegado permanentemente. Actívalo desde ajustes.',
      );
    } catch (_) {
      _setState(
        FakeGpsStatus.error,
        'No se pudo validar la ubicación del dispositivo.',
      );
    }
  }

  Future<void> openAppSettings() {
    return _locationSecurityService.openAppSettings();
  }

  Future<void> openLocationSettings() {
    return _locationSecurityService.openLocationSettings();
  }

  void _setState(FakeGpsStatus newStatus, String newMessage) {
    _status = newStatus;
    _message = newMessage;
    notifyListeners();
  }
}
