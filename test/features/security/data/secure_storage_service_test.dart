import 'package:flutter_test/flutter_test.dart';
import 'package:login/features/security/data/secure_storage_service.dart';

class MockSecureStorage implements ISecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _data[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }
}

void main() {
  group('SecureStorageService Tests', () {
    late SecureStorageService service;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      service = SecureStorageService.createWithMock(mockStorage);
    });

    test('Escritura de los cuatro campos', () async {
      await service.seedSensitiveData(userId: 'admin');

      final status = await service.getSensitiveDataStatus();

      expect(status['user_id'], isTrue);
      expect(status['access_token'], isTrue);
      expect(status['refresh_token'], isTrue);
      expect(status['session_secret'], isTrue);

      final hasData = await service.hasSensitiveData();
      expect(hasData, isTrue);
    });

    test('Detección de que los cuatro campos existen y luego eliminación', () async {
      await service.seedSensitiveData(userId: 'admin');
      
      expect(await service.hasSensitiveData(), isTrue);

      await service.deleteSensitiveData();

      expect(await service.hasSensitiveData(), isFalse);

      final status = await service.getSensitiveDataStatus();
      expect(status['user_id'], isFalse);
      expect(status['access_token'], isFalse);
      expect(status['refresh_token'], isFalse);
      expect(status['session_secret'], isFalse);
    });
  });
}
