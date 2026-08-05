import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'secure_storage_service.dart';

class DeviceRegistrationResult {
  final bool success;
  final bool fcmTokenAvailable;
  final bool firestoreRegistered;
  final String? errorMessage;

  DeviceRegistrationResult({
    required this.success,
    required this.fcmTokenAvailable,
    required this.firestoreRegistered,
    this.errorMessage,
  });
}

class DeviceRegistrationService {
  DeviceRegistrationService._();
  static final instance = DeviceRegistrationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DeviceRegistrationResult> registerDevice({
    required String remoteUserId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return DeviceRegistrationResult(
          success: false,
          fcmTokenAvailable: false,
          firestoreRegistered: false,
          errorMessage: 'Usuario anónimo no autenticado en Firebase.',
        );
      }

      String? token;
      try {
        // Obtenemos el token con timeout para no bloquear
        token = await FirebaseMessaging.instance.getToken().timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint('[DEVICE_REGISTRATION] Error obteniendo FCM Token: $e');
        return DeviceRegistrationResult(
          success: false,
          fcmTokenAvailable: false,
          firestoreRegistered: false,
          errorMessage: 'Error obteniendo FCM Token: $e',
        );
      }

      if (token == null || token.isEmpty) {
        return DeviceRegistrationResult(
          success: false,
          fcmTokenAvailable: false,
          firestoreRegistered: false,
          errorMessage: 'El FCM Token obtenido es nulo o vacío.',
        );
      }

      final installationId = await SecureStorageService.instance
          .getDeviceInstallationId();
      if (installationId == null) {
        return DeviceRegistrationResult(
          success: false,
          fcmTokenAvailable: true,
          firestoreRegistered: false,
          errorMessage: 'installationId local no encontrado.',
        );
      }

      final String platform = kIsWeb
          ? 'web'
          : (Platform.isAndroid
                ? 'android'
                : (Platform.isIOS ? 'ios' : 'unknown'));

      final docRef = _firestore
          .collection('users')
          .doc(remoteUserId)
          .collection('devices')
          .doc(installationId);

      try {
        await docRef
            .set({
              'fcmToken': token,
              'installationId': installationId,
              'remoteUserId': remoteUserId,
              'ownerUid': user.uid,
              'platform': platform,
              'updatedAt': FieldValue.serverTimestamp(),
              'enabled': true,
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('[DEVICE_REGISTRATION] Error guardando en Firestore: $e');
        return DeviceRegistrationResult(
          success: false,
          fcmTokenAvailable: true,
          firestoreRegistered: false,
          errorMessage: 'Error guardando en Firestore: $e',
        );
      }

      debugPrint(
        '[DEVICE_REGISTRATION] Dispositivo $installationId registrado en Firestore para $remoteUserId',
      );

      // Si todo fue bien, escuchamos por token refreshes para actualizarlo luego
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _updateTokenInFirestore(
          remoteUserId: remoteUserId,
          token: newToken,
          installationId: installationId,
          ownerUid: user.uid,
          platform: platform,
        );
      });

      return DeviceRegistrationResult(
        success: true,
        fcmTokenAvailable: true,
        firestoreRegistered: true,
      );
    } catch (e) {
      debugPrint('[DEVICE_REGISTRATION] Error general en registerDevice: $e');
      return DeviceRegistrationResult(
        success: false,
        fcmTokenAvailable: false,
        firestoreRegistered: false,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  Future<void> _updateTokenInFirestore({
    required String remoteUserId,
    required String token,
    required String installationId,
    required String ownerUid,
    required String platform,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(remoteUserId)
          .collection('devices')
          .doc(installationId);

      await docRef.set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '[DEVICE_REGISTRATION] Token FCM actualizado en Firestore para $remoteUserId',
      );
    } catch (e) {
      debugPrint(
        '[DEVICE_REGISTRATION] Error actualizando token en Firestore: $e',
      );
    }
  }
}
