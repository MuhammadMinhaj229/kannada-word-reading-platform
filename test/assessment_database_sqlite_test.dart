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
        'content_draft_items',
        'content_draft_item_revisions',
      }),
    );

    final foreignKeyViolations = await db.rawQuery('PRAGMA foreign_key_check');
    expect(foreignKeyViolations, isEmpty);
    expect(secureStore.readCalls, greaterThanOrEqualTo(1));
    expect(secureStore.writeCalls, 1);

    await database.close();
  });

  test('content draft revisions persist atomically and reject stale editors',
      () async {
    final database = createDatabase(_TestSecureStore());

    final first = await database.saveContentDraftItem(
      itemId: 'W001',
      itemType: 'word',
      itemText: 'ಮನೆ',
      metadataJson: '{"meaning":"house"}',
      expectedRevision: 0,
    );
    expect(first['revision'], 1);
    expect(first['text'], 'ಮನೆ');

    final second = await database.saveContentDraftItem(
      itemId: 'W001',
      itemType: 'word',
      itemText: 'ಮನೆಯು',
      metadataJson: '{"meaning":"house (nominative)"}',
      expectedRevision: 1,
    );
    expect(second['revision'], 2);
    expect(second['created_at'], first['created_at']);

    await expectLater(
      database.saveContentDraftItem(
        itemId: 'W001',
        itemType: 'word',
        itemText: 'stale edit',
        metadataJson: '{}',
        expectedRevision: 1,
      ),
      throwsA(isA<StateError>()),
    );

    final current = await database.loadContentDraftItems();
    expect(current, hasLength(1));
    expect(current.single['revision'], 2);
    expect(current.single['text'], 'ಮನೆಯು');

    final history = await database.loadContentDraftHistory('W001');
    expect(history.map((row) => row['revision']).toList(), <int>[2, 1]);
    expect(history.last['text'], 'ಮನೆ');

    await database.close();
  });

  test('content drafts keep Real Word and Non-Word types immutable', () async {
    final database = createDatabase(_TestSecureStore());
    await database.saveContentDraftItem(
      itemId: 'NDRAFT-01',
      itemType: 'nonword',
      itemText: 'ಮನೆಕ',
      metadataJson: '{"method":"A_vowel"}',
      expectedRevision: 0,
    );

    await expectLater(
      database.saveContentDraftItem(
        itemId: 'NDRAFT-01',
        itemType: 'word',
        itemText: 'ಮನೆಕ',
        metadataJson: '{}',
        expectedRevision: 1,
      ),
      throwsA(isA<StateError>()),
    );
    await database.close();
  });

  test('upgrades a version-one database with the content draft tables',
      () async {
    final secureStore = _TestSecureStore();
    final firstOpen = createDatabase(secureStore);
    final oldVersionDatabase = await firstOpen.database;
    await oldVersionDatabase.execute('DROP TABLE content_draft_item_revisions');
    await oldVersionDatabase.execute('DROP INDEX idx_content_draft_type_updated');
    await oldVersionDatabase.execute('DROP TABLE content_draft_items');
    await oldVersionDatabase.execute('PRAGMA user_version = 1');
    await firstOpen.close();

    final upgradedDatabase = createDatabase(secureStore);
    final db = await upgradedDatabase.database;
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tables = rows.map((row) => row['name'] as String).toSet();
    expect(
      tables,
      containsAll(<String>{
        'content_draft_items',
        'content_draft_item_revisions',
      }),
    );
    final version = await db.rawQuery('PRAGMA user_version');
    expect(version.single['user_version'], 2);
    await upgradedDatabase.close();
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
