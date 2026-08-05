import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../remote_wipe/data/remote_wipe_message_parser.dart';
import 'secure_storage_service.dart';

enum RemoteWipeResult {
  applied,
  invalidPayload,
  invalidAction,
  expired,
  wrongUser,
  duplicate,
  noLocalUser,
  storageError,
}

class RemoteWipeService {
  RemoteWipeService._internal(this._storageService);

  static final RemoteWipeService instance = RemoteWipeService._internal(
    SecureStorageService.instance,
  );

  @visibleForTesting
  static RemoteWipeService createWithStorage(
    SecureStorageService storageService,
  ) {
    return RemoteWipeService._internal(storageService);
  }

  final SecureStorageService _storageService;

  static const String remoteWipeAction = 'remote_wipe';

  Future<RemoteWipeResult> handleRemoteMessage(RemoteMessage message) async {
    debugPrint('[REMOTE_WIPE] Evaluando orden FCM recibida...');

    final command = RemoteWipeMessageParser.parse(message.data);

    if (command == null) {
      debugPrint('[REMOTE_WIPE] Orden rechazada: invalidPayload');
      return RemoteWipeResult.invalidPayload;
    }

    if (command.action != remoteWipeAction) {
      debugPrint(
        '[REMOTE_WIPE] Orden rechazada: invalidAction (${command.action})',
      );
      return RemoteWipeResult.invalidAction;
    }

    if (command.isExpired) {
      debugPrint('[REMOTE_WIPE] Orden rechazada: expired');
      return RemoteWipeResult.expired;
    }

    final localUserId = await _storageService.getTargetUserId();

    if (localUserId == null || localUserId.isEmpty) {
      debugPrint('[REMOTE_WIPE] Orden rechazada: noLocalUser');
      return RemoteWipeResult.noLocalUser;
    }

    if (command.targetUserId != localUserId) {
      debugPrint(
        '[REMOTE_WIPE] Orden rechazada: wrongUser (${command.targetUserId} != $localUserId)',
      );
      return RemoteWipeResult.wrongUser;
    }

    final lastCommandId = await _storageService.getLastProcessedCommandId();

    if (lastCommandId == command.commandId) {
      debugPrint(
        '[REMOTE_WIPE] Orden rechazada: duplicate (${command.commandId})',
      );
      return RemoteWipeResult.duplicate;
    }

    debugPrint('[REMOTE_WIPE] Usuario validado: $localUserId');

    // Ejecutamos el borrado
    try {
      await _storageService.deleteSensitiveData();
      await _storageService.saveProcessedCommandId(command.commandId);
    } catch (e) {
      debugPrint('[REMOTE_WIPE] Excepción durante el borrado: $e');
      return RemoteWipeResult.storageError;
    }

    // Verificación
    final status = await _storageService.getSensitiveDataStatus();
    final hasAny = status.values.any((isSaved) => isSaved == true);

    if (hasAny) {
      debugPrint(
        '[REMOTE_WIPE] Error: storageError (No se pudieron eliminar todos los campos)',
      );
      return RemoteWipeResult.storageError;
    }

    debugPrint('[REMOTE_WIPE] Borrado aplicado');
    debugPrint('[REMOTE_WIPE] Command ID: ${command.commandId}');
    return RemoteWipeResult.applied;
  }
}
