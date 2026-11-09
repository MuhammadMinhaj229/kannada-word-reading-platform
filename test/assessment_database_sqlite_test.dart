import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/data/database/assessment_database.dart';
import 'package:padalab_android/data/security/database_key_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TestSecureStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};
  int readCalls = 0;
  int writeCalls = 0;

  @override
  Future<String?> read(String key) async {
    readCalls += 1;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writeCalls += 1;
    values[key] = value;
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('padalab-db-test-');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  AssessmentDatabase createDatabase(_TestSecureStore secureStore) {
    return AssessmentDatabase(
      keyProvider: DatabaseKeyProvider(store: secureStore),
      factory: databaseFactoryFfiNoIsolate,
      databasesPathProvider: () async => directory.path,
    );
  }

  test('creates the expected encrypted schema and enforces foreign keys',
      () async {
    final secureStore = _TestSecureStore();
    final database = createDatabase(secureStore);

    final db = await database.database;
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    final tables = rows.map((row) => row['name'] as String).toSet();

    expect(
      tables,
      containsAll(<String>{
        'children',
        'assessors',
        'sessions',
        'session_manifest_items',
        'trials',
        'item_bank_metadata',
        'exports',
        'app_metadata',
      }),
    );

    final foreignKeyViolations = await db.rawQuery('PRAGMA foreign_key_check');
    expect(foreignKeyViolations, isEmpty);
    expect(secureStore.readCalls, greaterThanOrEqualTo(1));
    expect(secureStore.writeCalls, 1);

    await database.close();
  });

  test('concurrent callers share one database opening and one key creation',
      () async {
    final secureStore = _TestSecureStore();
    final database = createDatabase(secureStore);

    final opened = await Future.wait<Database>(<Future<Database>>[
      database.database,
      database.database,
      database.database,
    ]);

    expect(opened[0], same(opened[1]));
    expect(opened[1], same(opened[2]));
    expect(secureStore.writeCalls, 1);

    await database.close();
  });

  test('close waits for an in-flight open and permits a later reopen',
      () async {
    final secureStore = _TestSecureStore();
    final databasePath = Completer<String>();
    final database = AssessmentDatabase(
      keyProvider: DatabaseKeyProvider(store: secureStore),
      factory: databaseFactoryFfiNoIsolate,
      databasesPathProvider: () => databasePath.future,
    );

    final firstOpen = database.database;
    final closing = database.close();
    // A caller arriving during close must wait for the old handle to close.
    final reopenedAfterClose = database.database;
    databasePath.complete(directory.path);

    await closing;
    await firstOpen;

    final reopened = await reopenedAfterClose;
    expect(reopened.isOpen, isTrue);
    expect(secureStore.writeCalls, 1);

    await database.close();
  });

  test('preserves and refuses to open a legacy plaintext database', () async {
    final legacyFile = File(
      '${directory.path}/${AssessmentDatabase.legacyPlaintextDatabaseFileName}',
    );
    await legacyFile.writeAsString('legacy fixture: do not delete');

    final secureStore = _TestSecureStore();
    final database = createDatabase(secureStore);

    await expectLater(database.database, throwsA(isA<StateError>()));
    expect(await legacyFile.readAsString(), 'legacy fixture: do not delete');
    expect(secureStore.readCalls, 0);
    expect(secureStore.writeCalls, 0);

    await database.close();
  });

  test('does not generate a replacement key for an existing encrypted DB',
      () async {
    final encryptedFile = File(
      '${directory.path}/${AssessmentDatabase.databaseFileName}',
    );
    await encryptedFile.writeAsBytes(<int>[1, 2, 3, 4]);

    final secureStore = _TestSecureStore();
    final database = createDatabase(secureStore);

    await expectLater(
      database.database,
      throwsA(isA<DatabaseKeyUnavailable>()),
    );
    expect(secureStore.writeCalls, 0);
    expect(await encryptedFile.readAsBytes(), <int>[1, 2, 3, 4]);

    await database.close();
  });
}
