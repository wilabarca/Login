import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login/features/security/data/remote_wipe_service.dart';
import 'package:login/features/security/data/secure_storage_service.dart';

class MockSecureStorage implements ISecureStorage {
  final Map<String, String> _storage = {};
  bool throwOnDelete = false;

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    if (throwOnDelete) throw Exception('Simulated storage error');
    _storage.remove(key);
  }
}

void main() {
  late MockSecureStorage mockStorage;
  late SecureStorageService secureStorageService;
  late RemoteWipeService remoteWipeService;

  setUp(() {
    mockStorage = MockSecureStorage();
    secureStorageService = SecureStorageService.createWithMock(mockStorage);
    remoteWipeService = RemoteWipeService.createWithStorage(secureStorageService);
  });

  RemoteMessage createMessage({
    String action = 'remote_wipe',
    String targetUserId = 'admin',
    String commandId = 'cmd_123',
    int expiresOffset = 300,
  }) {
    final now = DateTime.now();
    return RemoteMessage(
      data: {
        'action': action,
        'targetUserId': targetUserId,
        'commandId': commandId,
        'issuedAt': now.toIso8601String(),
        'expiresAt': now.add(Duration(seconds: expiresOffset)).toIso8601String(),
      },
    );
  }

  group('RemoteWipeService Validations', () {
    test('1. Orden válida para admin elimina los cuatro campos y retorna applied', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = createMessage(targetUserId: 'admin');
      final result = await remoteWipeService.handleRemoteMessage(msg);

      expect(result, RemoteWipeResult.applied);
      
      final status = await secureStorageService.getSensitiveDataStatus();
      for (final isSaved in status.values) {
        expect(isSaved, false, reason: 'El campo sensible no fue eliminado');
      }
    });

    test('2. Usuario incorrecto no elimina ningún campo y retorna wrongUser', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = createMessage(targetUserId: 'otro_usuario');
      final result = await remoteWipeService.handleRemoteMessage(msg);

      expect(result, RemoteWipeResult.wrongUser);
      
      final status = await secureStorageService.getSensitiveDataStatus();
      for (final isSaved in status.values) {
        expect(isSaved, true, reason: 'El campo fue eliminado pero no debió serlo');
      }
    });

    test('3. Orden expirada no elimina datos y retorna expired', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = createMessage(expiresOffset: -10); // Expiró hace 10s
      final result = await remoteWipeService.handleRemoteMessage(msg);

      expect(result, RemoteWipeResult.expired);
    });

    test('4. Acción incorrecta no elimina datos y retorna invalidAction', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = createMessage(action: 'unknown_action');
      final result = await remoteWipeService.handleRemoteMessage(msg);

      expect(result, RemoteWipeResult.invalidAction);
    });

    test('5. Payload incompleto no elimina datos y retorna invalidPayload', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = RemoteMessage(data: {'action': 'remote_wipe'}); // Sin ID, targetUserId, fechas
      final result = await remoteWipeService.handleRemoteMessage(msg);

      expect(result, RemoteWipeResult.invalidPayload);
    });

    test('6. commandId duplicado no elimina nuevamente y retorna duplicate', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = createMessage(commandId: 'dup_cmd_001');
      final result1 = await remoteWipeService.handleRemoteMessage(msg);
      expect(result1, RemoteWipeResult.applied);
      
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin'); // Simulamos re-ingreso
      
      final result2 = await remoteWipeService.handleRemoteMessage(msg);
      expect(result2, RemoteWipeResult.duplicate); // Segunda vez es duplicado
    });

    test('7. No existe target_user_id local y retorna noLocalUser', () async {
      // No llamamos a seedSensitiveData
      final msg = createMessage();
      final result = await remoteWipeService.handleRemoteMessage(msg);

      expect(result, RemoteWipeResult.noLocalUser);
    });

    test('8. Error del almacenamiento retorna storageError', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      mockStorage.throwOnDelete = true;
      
      final msg = createMessage();
      final result = await remoteWipeService.handleRemoteMessage(msg);

      expect(result, RemoteWipeResult.storageError);
    });

    test('9. Después de applied, los cuatro campos sensibles están ausentes', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = createMessage();
      await remoteWipeService.handleRemoteMessage(msg);
      
      final hasData = await secureStorageService.hasSensitiveData();
      expect(hasData, false);
      
      final status = await secureStorageService.getSensitiveDataStatus();
      expect(status.values.every((v) => v == false), isTrue);
    });

    test('10. target_user_id e installationId permanecen después del borrado', () async {
      await secureStorageService.seedSensitiveData(remoteUserId: 'admin');
      
      final msg = createMessage();
      await remoteWipeService.handleRemoteMessage(msg);
      
      final targetUserId = await secureStorageService.getTargetUserId();
      expect(targetUserId, 'admin');
      
      final installId = await secureStorageService.getDeviceInstallationId();
      expect(installId, isNotNull);
      expect(installId, isNotEmpty);
    });
  });
}
