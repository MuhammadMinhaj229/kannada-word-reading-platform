import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/data/security/database_key_provider.dart';

class _MemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('simulated secure-store read failure');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('simulated secure-store write failure');
    values[key] = value;
  }
}

void main() {
  test('creates and persists a cryptographically shaped 256-bit key', () async {
    final store = _MemorySecureStore();
    final provider = DatabaseKeyProvider(store: store);

    final first = await provider.getOrCreate(databaseAlreadyExists: false);
    final second = await provider.getOrCreate(databaseAlreadyExists: false);

    expect(first, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(second, first);
    expect(store.values[DatabaseKeyProvider.storageKey], first);
  });

  test('never replaces a missing key when an encrypted database exists',
      () async {
    final store = _MemorySecureStore();
    final provider = DatabaseKeyProvider(store: store);

    await expectLater(
      provider.getOrCreate(databaseAlreadyExists: true),
      throwsA(isA<DatabaseKeyUnavailable>()),
    );
    expect(store.values, isEmpty);
  });

  test('rejects an invalid stored key without overwriting it', () async {
    final store = _MemorySecureStore()
      ..values[DatabaseKeyProvider.storageKey] = 'not-a-valid-key';
    final provider = DatabaseKeyProvider(store: store);

    await expectLater(
      provider.getOrCreate(databaseAlreadyExists: true),
      throwsA(isA<DatabaseKeyUnavailable>()),
    );
    expect(store.values[DatabaseKeyProvider.storageKey], 'not-a-valid-key');
  });

  test('fails closed when secure storage cannot be read', () async {
    final store = _MemorySecureStore()..failReads = true;
    final provider = DatabaseKeyProvider(store: store);

    await expectLater(
      provider.getOrCreate(databaseAlreadyExists: false),
      throwsA(isA<DatabaseKeyUnavailable>()),
    );
  });

  test('fails closed when secure storage cannot persist a new key', () async {
    final store = _MemorySecureStore()..failWrites = true;
    final provider = DatabaseKeyProvider(store: store);

    await expectLater(
      provider.getOrCreate(databaseAlreadyExists: false),
      throwsA(isA<DatabaseKeyUnavailable>()),
    );
  });
}
