import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'secure_storage_service.dart';

class DeviceRegistrationService {
  DeviceRegistrationService._();
  static final instance = DeviceRegistrationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerDevice({required String userId}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      
      await _saveTokenToFirestore(userId: userId, token: token);
      
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(userId: userId, token: newToken);
      });
      
    } catch (e) {
      debugPrint('Error registrando dispositivo en Firestore: $e');
    }
  }

  Future<void> _saveTokenToFirestore({
    required String userId,
    required String token,
  }) async {
    try {
      final installationId = await SecureStorageService.instance.getDeviceInstallationId();
      if (installationId == null) return;
      
      final String platform = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown'));
      
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(installationId);
          
      await docRef.set({
        'fcmToken': token,
        'installationId': installationId,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
        'enabled': true,
      }, SetOptions(merge: true));
      
      debugPrint('Dispositivo $installationId registrado en Firestore para $userId');
    } catch (e) {
      debugPrint('Error guardando token en Firestore: $e');
    }
  }
}
