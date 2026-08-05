import 'package:flutter/foundation.dart';
import '../domain/remote_wipe_command.dart';

class RemoteWipeMessageParser {
  RemoteWipeMessageParser._();

  static RemoteWipeCommand? parse(Map<String, dynamic> data) {
    try {
      final action = data['action'] as String?;
      final targetUserId = data['targetUserId'] as String?;
      final commandId = data['commandId'] as String?;
      final issuedAtStr = data['issuedAt'] as String?;
      final expiresAtStr = data['expiresAt'] as String?;

      if (action == null ||
          targetUserId == null ||
          commandId == null ||
          issuedAtStr == null ||
          expiresAtStr == null) {
        debugPrint('FCM ignorado: estructura del mensaje incompleta.');
        return null;
      }

      final issuedAt = DateTime.tryParse(issuedAtStr);
      final expiresAt = DateTime.tryParse(expiresAtStr);

      if (issuedAt == null || expiresAt == null) {
        debugPrint('FCM ignorado: formato de fecha inválido.');
        return null;
      }

      return RemoteWipeCommand(
        action: action,
        targetUserId: targetUserId,
        commandId: commandId,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
      );
    } catch (e) {
      debugPrint('FCM ignorado: error parseando payload: $e');
      return null;
    }
  }
}
