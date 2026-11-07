import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/data/database/assessment_database.dart';
import 'package:padalab_android/data/security/database_key_provider.dart';
import 'package:padalab_android/features/assessment/domain/models/session_allocation.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item.dart';
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

  test('creates the expected schema and enforces declared foreign keys',
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
    expect(secureStore.readCalls, 2);
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

  Future<void> insertTestSession(Database db) async {
    await db.insert('children', <String, Object?>{
      'child_id': 'TEST-CHILD',
      'child_name': null,
      'created_at': DateTime(2026, 11, 7).toIso8601String(),
      'updated_at': DateTime(2026, 11, 7).toIso8601String(),
    });
    await db.insert('assessors', <String, Object?>{
      'assessor_id': 'TEST-ASSESSOR',
      'last_used_at': DateTime(2026, 11, 7).toIso8601String(),
    });
    await db.insert('sessions', <String, Object?>{
      'session_uuid': 'TEST-SESSION',
      'child_id': 'TEST-CHILD',
      'assessor_id': 'TEST-ASSESSOR',
      'device_id': 'TEST-DEVICE',
      'session_no': 1,
      'session_date': '2026-11-07',
      'started_at': DateTime(2026, 11, 7).toIso8601String(),
      'completed_at': null,
      'status': 'in_progress',
      'is_repeat': 0,
      'is_restart': 0,
      'protocol_version': 'TEST-PROTOCOL',
      'protocol_approval_reference': 'TEST-ONLY',
      'allocation_approval_reference': 'TEST-ONLY',
      'app_version': '0.1.0+1',
      'items_file_version': 'TEST-BANK',
      'items_file_sha256': 'a' * 64,
      'next_ordinal': 1,
      'coins_so_far': 0,
    });
    await db.insert('session_manifest_items', <String, Object?>{
      'session_uuid': 'TEST-SESSION',
      'ordinal': 1,
      'phase': 'test',
      'phase_trial_no': 1,
      'item_id': 'REAL-001',
      'item_text': 'ಮನೆ',
      'item_type': 'word',
      'nonword_method': null,
    });
  }

  test('refuses to display a trial whose complete content differs from manifest',
      () async {
    final database = createDatabase(_TestSecureStore());
    final db = await database.database;
    await insertTestSession(db);

    final tampered = PlannedTrial(
      ordinal: 1,
      phase: TrialPhase.test,
      phaseTrialNumber: 1,
      item: const StudyItem(
        id: 'REAL-001',
        text: 'ತಪ್ಪಾದ ಪದ',
        type: StudyItemType.realWord,
      ),
    );

    await expectLater(
      database.beginTrial(
        sessionUuid: 'TEST-SESSION',
        plannedTrial: tampered,
        shownAt: DateTime(2026, 11, 7, 10),
        appVersion: '0.1.0+1',
        itemBankVersion: 'TEST-BANK',
      ),
      throwsA(isA<StateError>()),
    );

    final trials = await db.query('trials');
    expect(trials, isEmpty);
    final session = (await db.query('sessions')).single;
    expect(session['next_ordinal'], 1);
    await database.close();
  });

  test('persists a response and advances the session cursor atomically',
      () async {
    final database = createDatabase(_TestSecureStore());
    final db = await database.database;
    await insertTestSession(db);

    final planned = PlannedTrial(
      ordinal: 1,
      phase: TrialPhase.test,
      phaseTrialNumber: 1,
      item: const StudyItem(
        id: 'REAL-001',
        text: 'ಮನೆ',
        type: StudyItemType.realWord,
      ),
    );
    final shownAt = DateTime(2026, 11, 7, 10);
    final answeredAt = shownAt.add(const Duration(milliseconds: 420));

    final trialUuid = await database.beginTrial(
      sessionUuid: 'TEST-SESSION',
      plannedTrial: planned,
      shownAt: shownAt,
      appVersion: '0.1.0+1',
      itemBankVersion: 'TEST-BANK',
    );

    await database.completeTrial(
      trialUuid: trialUuid,
      response: 'word',
      reactionTimeMs: 420,
      answeredAt: answeredAt,
      coinsSoFar: 0,
    );

    final trial = (await db.query(
      'trials',
      where: 'trial_uuid = ?',
      whereArgs: <Object?>[trialUuid],
    )).single;
    final session = (await db.query(
      'sessions',
      where: 'session_uuid = ?',
      whereArgs: <Object?>['TEST-SESSION'],
    )).single;

    expect(trial['status'], 'answered');
    expect(trial['response'], 'word');
    expect(trial['correct'], 1);
    expect(trial['rt_ms'], 420);
    expect(session['next_ordinal'], 2);
    expect(session['status'], 'completed');
    expect(session['completed_at'], isNotNull);
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

  test('does not generate a replacement key if an encrypted DB file exists',
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
