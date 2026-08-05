import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalAuthUser {
  const LocalAuthUser({
    required this.id,
    required this.username,
  });

  final String id;
  final String username;
}

class LocalAuthStorage {
  LocalAuthStorage._();

  static final LocalAuthStorage instance = LocalAuthStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _usersKey = 'local_users';
  static const String _currentUserIdKey = 'current_user_id';

  Future<void> ensureDemoUser() async {
    final users = await _readUsers();

    final exists = users.any(
      (user) => user['username'] == 'admin',
    );

    if (exists) return;

    const userId = 'local_demo_admin';

    users.add({
      'id': userId,
      'username': 'admin',
      'password_hash': _hashPassword(
        userId: userId,
        password: '1234',
      ),
      'created_at': DateTime.now().toIso8601String(),
    });

    await _saveUsers(users);
  }

  Future<LocalAuthUser> register({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) {
      throw Exception('Ingresa usuario y contraseña.');
    }

    if (normalizedPassword.length < 4) {
      throw Exception('La contraseña debe tener al menos 4 caracteres.');
    }

    final users = await _readUsers();

    final exists = users.any(
      (user) => user['username'] == normalizedUsername,
    );

    if (exists) {
      throw Exception('Ese usuario ya existe.');
    }

    final userId = _createLocalUserId();

    users.add({
      'id': userId,
      'username': normalizedUsername,
      'password_hash': _hashPassword(
        userId: userId,
        password: normalizedPassword,
      ),
      'created_at': DateTime.now().toIso8601String(),
    });

    await _saveUsers(users);

    await _storage.write(
      key: _currentUserIdKey,
      value: userId,
    );

    return LocalAuthUser(
      id: userId,
      username: normalizedUsername,
    );
  }

  Future<LocalAuthUser?> login({
    required String username,
    required String password,
  }) async {
    await ensureDemoUser();

    final normalizedUsername = username.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final users = await _readUsers();

    for (final user in users) {
      final userId = user['id'] as String;
      final storedUsername = user['username'] as String;
      final storedPasswordHash = user['password_hash'] as String;

      final incomingPasswordHash = _hashPassword(
        userId: userId,
        password: normalizedPassword,
      );

      if (storedUsername == normalizedUsername &&
          storedPasswordHash == incomingPasswordHash) {
        await _storage.write(
          key: _currentUserIdKey,
          value: userId,
        );

        return LocalAuthUser(
          id: userId,
          username: storedUsername,
        );
      }
    }

    return null;
  }

  Future<String?> getCurrentUserId() {
    return _storage.read(key: _currentUserIdKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _currentUserIdKey);
  }

  Future<List<Map<String, dynamic>>> _readUsers() async {
    final rawUsers = await _storage.read(key: _usersKey);

    if (rawUsers == null || rawUsers.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawUsers) as List<dynamic>;

    return decoded
        .map((user) => Map<String, dynamic>.from(user as Map))
        .toList();
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    await _storage.write(
      key: _usersKey,
      value: jsonEncode(users),
    );
  }

  String _createLocalUserId() {
    final random = Random.secure().nextInt(999999);
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return 'local_${timestamp}_$random';
  }

  static String _hashPassword({
    required String userId,
    required String password,
  }) {
    final value = '$userId:${password.trim()}';
    return sha256.convert(utf8.encode(value)).toString();
  }
}