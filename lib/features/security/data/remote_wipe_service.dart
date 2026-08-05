import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../remote_wipe/data/remote_wipe_message_parser.dart';
import 'secure_storage_service.dart';

class RemoteWipeService {
  RemoteWipeService._();

  static final RemoteWipeService instance = RemoteWipeService._();

  static const String remoteWipeAction = 'remote_wipe';

  Future<void> handleRemoteMessage(RemoteMessage message) async {
    final command = RemoteWipeMessageParser.parse(message.data);

    if (command == null) {
      return; // El parser ya hizo el debugPrint
    }

    if (command.action != remoteWipeAction) {
      debugPrint('FCM ignorado: action no es remote_wipe.');
      return;
    }

    if (command.isExpired) {
      debugPrint('FCM ignorado: la orden ha expirado.');
      return;
    }

    final localUserId = await SecureStorageService.instance.getTargetUserId();

    if (localUserId == null || localUserId.isEmpty) {
      debugPrint('FCM ignorado: no existe usuario registrado localmente.');
      return;
    }

    if (command.targetUserId != localUserId) {
      debugPrint('FCM ignorado: la orden va dirigida a otro usuario (${command.targetUserId} != $localUserId).');
      return;
    }

    final lastCommandId = await SecureStorageService.instance.getLastProcessedCommandId();

    if (lastCommandId == command.commandId) {
      debugPrint('FCM ignorado: la orden ya fue procesada anteriormente.');
      return;
    }

    // Si pasamos todas las validaciones, ejecutamos el borrado
    await SecureStorageService.instance.deleteSensitiveData();
    await SecureStorageService.instance.saveProcessedCommandId(command.commandId);

    debugPrint('================ FCM DEBUG ================');
    debugPrint('Datos sensibles eliminados remotamente por FCM.');
    debugPrint('Command ID: ${command.commandId}');
    debugPrint('Target User ID: ${command.targetUserId}');
    debugPrint('===========================================');
  }
}