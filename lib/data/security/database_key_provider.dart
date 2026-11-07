import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class DatabaseKeyUnavailable implements Exception {
  const DatabaseKeyUnavailable(this.message);

  final String message;

  @override
  String toString() => 'DatabaseKeyUnavailable: $message';
}

/// Supplies the SQLCipher key from Android Keystore-backed secure storage.
///
/// If the encrypted database exists but its key is absent, this provider
/// refuses to create a replacement key. A new key would make the existing
/// research records unreadable and could conceal a device-restore problem.
class DatabaseKeyProvider {
  DatabaseKeyProvider({
    SecureKeyValueStore? store,
    Random? secureRandom,
  })  : _store = store ?? const FlutterSecureKeyValueStore(),
        _secureRandom = secureRandom ?? Random.secure();

  static const String storageKey = 'padalab.sqlcipher.database-key.v1';

  final SecureKeyValueStore _store;
  final Random _secureRandom;

  Future<String> getOrCreate({required bool databaseAlreadyExists}) async {
    String? existing;
    try {
      existing = await _store.read(storageKey);
    } catch (_) {
      throw const DatabaseKeyUnavailable(
        'Unable to read the database key from secure storage.',
      );
    }

    if (existing != null) {
      if (!_isValidKey(existing)) {
        throw const DatabaseKeyUnavailable(
          'The stored database key has an invalid format. Do not reset it.',
        );
      }
      return existing;
    }

    if (databaseAlreadyExists) {
      throw const DatabaseKeyUnavailable(
        'The encrypted database exists but its key is missing. '
        'Restore the original secure key or follow the approved recovery plan.',
      );
    }

    final key = List<int>.generate(
      32,
      (_) => _secureRandom.nextInt(256),
      growable: false,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    try {
      await _store.write(storageKey, key);
      final verification = await _store.read(storageKey);
      if (verification != key) {
        throw const DatabaseKeyUnavailable(
          'The database key could not be verified after secure storage.',
        );
      }
    } on DatabaseKeyUnavailable {
      rethrow;
    } catch (_) {
      throw const DatabaseKeyUnavailable(
        'Unable to store the new database key securely.',
      );
    }

    return key;
  }

  bool _isValidKey(String key) =>
      RegExp(r'^[a-f0-9]{64}$').hasMatch(key);
}
