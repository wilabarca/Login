import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

abstract class ISecureStorage {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class FlutterSecureStorageWrapper implements ISecureStorage {
  final FlutterSecureStorage _storage;
  
  FlutterSecureStorageWrapper(this._storage);

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
}

class SecureStorageService {
  SecureStorageService._internal(this._storage);

  static final SecureStorageService instance = SecureStorageService._internal(
    FlutterSecureStorageWrapper(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(),
      ),
    ),
  );
  
  @visibleForTesting
  static SecureStorageService createWithMock(ISecureStorage mockStorage) {
    return SecureStorageService._internal(mockStorage);
  }

  final ISecureStorage _storage;

  static const String userIdKey = 'user_id';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String sessionSecretKey = 'session_secret';

  static const String deviceInstallationIdKey = 'device_installation_id';
  static const String lastRemoteWipeAtKey = 'last_remote_wipe_at';
  static const String lastProcessedCommandIdKey = 'last_processed_command_id';
  static const String targetUserIdKey = 'target_user_id';

  static const List<String> sensitiveKeys = [
    userIdKey,
    accessTokenKey,
    refreshTokenKey,
    sessionSecretKey,
  ];

  String _generateCryptoRandomString([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  Future<void> seedSensitiveData({required String userId}) async {
    await _storage.write(key: userIdKey, value: userId);
    await _storage.write(key: targetUserIdKey, value: userId);
    
    await _storage.write(
      key: accessTokenKey,
      value: _generateCryptoRandomString(),
    );
    
    await _storage.write(
      key: refreshTokenKey,
      value: _generateCryptoRandomString(),
    );
    
    await _storage.write(
      key: sessionSecretKey,
      value: _generateCryptoRandomString(),
    );
    
    final existingInstallId = await _storage.read(key: deviceInstallationIdKey);
    if (existingInstallId == null) {
      await _storage.write(
        key: deviceInstallationIdKey,
        value: const Uuid().v4(),
      );
    }
  }

  Future<bool> hasSensitiveData() async {
    for (final key in sensitiveKeys) {
      final value = await _storage.read(key: key);
      if (value == null || value.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<Map<String, bool>> getSensitiveDataStatus() async {
    final Map<String, bool> status = {};
    for (final key in sensitiveKeys) {
      final value = await _storage.read(key: key);
      status[key] = (value != null && value.isNotEmpty);
    }
    return status;
  }

  Future<void> deleteSensitiveData() async {
    for (final key in sensitiveKeys) {
      await _storage.delete(key: key);
    }
    
    await _storage.write(
      key: lastRemoteWipeAtKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getTargetUserId() async {
    return _storage.read(key: targetUserIdKey);
  }

  Future<String?> getDeviceInstallationId() async {
    return _storage.read(key: deviceInstallationIdKey);
  }

  Future<String?> getLastProcessedCommandId() async {
    return _storage.read(key: lastProcessedCommandIdKey);
  }

  Future<void> saveProcessedCommandId(String commandId) async {
    await _storage.write(key: lastProcessedCommandIdKey, value: commandId);
  }
  
  Future<String?> getLastRemoteWipeAt() async {
    return _storage.read(key: lastRemoteWipeAtKey);
  }
}
