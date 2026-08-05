import 'package:flutter_test/flutter_test.dart';
import 'package:login/features/remote_wipe/data/remote_wipe_message_parser.dart';

void main() {
  group('RemoteWipeMessageParser Tests', () {
    test('Mensaje válido para el usuario actual', () {
      final now = DateTime.now();
      final data = {
        'action': 'remote_wipe',
        'targetUserId': 'admin',
        'commandId': '12345',
        'issuedAt': now.toIso8601String(),
        'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
      };

      final command = RemoteWipeMessageParser.parse(data);
      expect(command, isNotNull);
      expect(command!.targetUserId, 'admin');
      expect(command.isExpired, isFalse);
    });

    test('Mensaje expirado', () {
      final now = DateTime.now();
      final data = {
        'action': 'remote_wipe',
        'targetUserId': 'admin',
        'commandId': '12345',
        'issuedAt': now.subtract(const Duration(minutes: 10)).toIso8601String(),
        'expiresAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
      };

      final command = RemoteWipeMessageParser.parse(data);
      expect(command, isNotNull);
      expect(command!.isExpired, isTrue);
    });

    test('Mensaje con acción incorrecta (incompleto o nulo)', () {
      final data = {
        'action': 'other_action',
        'targetUserId': 'admin',
        // Faltan campos
      };

      final command = RemoteWipeMessageParser.parse(data);
      expect(command, isNull);
    });

    test('Mensaje sin commandId', () {
      final now = DateTime.now();
      final data = {
        'action': 'remote_wipe',
        'targetUserId': 'admin',
        'issuedAt': now.toIso8601String(),
        'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
      };

      final command = RemoteWipeMessageParser.parse(data);
      expect(command, isNull);
    });
  });
}
