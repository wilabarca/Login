import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../security/data/remote_wipe_service.dart';

class FcmService {
  FcmService._internal();

  static final FcmService instance = FcmService._internal();

  final _wipeResultController = StreamController<RemoteWipeResult>.broadcast();

  Stream<RemoteWipeResult> get onWipeResult => _wipeResultController.stream;

  Future<void> init() async {
    // 1. Solicitar permiso de notificaciones (Android 13+ / iOS)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '[FCM] Estado del permiso de notificaciones: ${settings.authorizationStatus}',
    );

    // 2. Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM] Mensaje recibido en foreground');
      final result = await RemoteWipeService.instance.handleRemoteMessage(
        message,
      );
      _wipeResultController.add(result);
    });

    // 3. Escuchar cuando la app se abre desde una notificación (background -> foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('[FCM] Mensaje abierto desde background');
      final result = await RemoteWipeService.instance.handleRemoteMessage(
        message,
      );
      _wipeResultController.add(result);
    });

    // 4. Procesar mensaje inicial si la app estaba terminada y se abrió por notificación
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] Procesando mensaje inicial (app terminada)');
      final result = await RemoteWipeService.instance.handleRemoteMessage(
        initialMessage,
      );
      _wipeResultController.add(result);
    }
  }

  void dispose() {
    _wipeResultController.close();
  }
}
