import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' as sqlcipher_api;
import 'package:uuid/uuid.dart';

import '../../core/config/assessment_release_gate.dart';
import '../../core/time/local_timestamp.dart';
import '../../features/assessment/domain/services/session_recovery_policy.dart';
import '../../features/assessment/domain/services/session_integrity_audit.dart';
import '../../features/assessment/domain/services/trial_response_validation.dart';
import '../../features/assessment/domain/models/session_allocation.dart';
import '../../features/assessment/domain/models/study_item.dart';
import '../../features/assessment/domain/models/study_item_bank.dart';
import '../security/database_key_provider.dart';
import 'active_session_snapshot.dart';

/// Local-only encrypted SQLite boundary.
///
/// Session creation freezes the approved manifest in one transaction. A
/// response is persisted and the next-ordinal pointer advances in one
/// transaction. The child screen must await both operations before showing
/// the next item. A failed write leaves the current item active.
class AssessmentDatabase {
  AssessmentDatabase({
    DatabaseKeyProvider? keyProvider,
    sqlcipher_api.DatabaseFactory? factory,
    Future<String> Function()? databasesPathProvider,
  })  : _keyProvider = keyProvider ?? DatabaseKeyProvider(),
        _releaseGate = AssessmentReleaseGate.current,
        _databaseFactory = factory ?? databaseFactory,
        _databasesPathProvider = databasesPathProvider ?? getDatabasesPath;

  static const int schemaVersion = 1;
  static const String databaseFileName = 'padalab_assessment_secure.db';
  static const String legacyPlaintextDatabaseFileName =
      'padalab_assessment.db';

  static const Uuid _uuid = Uuid();

  final DatabaseKeyProvider _keyProvider;
  final AssessmentReleaseGate _releaseGate;
  final sqlcipher_api.DatabaseFactory _databaseFactory;
  final Future<String> Function() _databasesPathProvider;

  Database? _database;

  Future<Database>? _openingDatabase;
  Completer<void>? _closingDatabase;

  Future<Database> get database async {
    // A caller arriving during close waits until the old handle is fully
    // closed; it must never receive a connection that is about to be closed.
    final closing = _closingDatabase;
    if (closing != null) await closing.future;

    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    final pending = _openingDatabase;
    if (pending != null) return pending;

    final opening = _openDatabase();
    _openingDatabase = opening;
    try {
      final opened = await opening;
      _database = opened;
      return opened;
    } finally {
      if (identical(_openingDatabase, opening)) _openingDatabase = null;
    }
  }

  Future<Database> _openDatabase() async {
    final databaseDirectory = await _databasesPathProvider();
    final databasePath = path.join(databaseDirectory, databaseFileName);
    final legacyPath =
        path.join(databaseDirectory, legacyPlaintextDatabaseFileName);

    if (await File(legacyPath).exists()) {
      throw StateError(
        'A legacy unencrypted Padalab database exists. It has been preserved; '
        'the encrypted release will not ignore or overwrite it. Run the '
        'approved one-time migration before opening this database.',
      );
    }

    final key = await _keyProvider.getOrCreate(
      databaseAlreadyExists: await File(databasePath).exists(),
    );

    return _databaseFactory.openDatabase(
      databasePath,
      options: sqlcipher_api.SqlCipherOpenDatabaseOptions(
        password: key,
        version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA secure_delete = ON');
        await db.execute('PRAGMA cipher_memory_security = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _onUpgrade,
        onDowngrade: (db, oldVersion, newVersion) async {
          throw StateError(
            'Database downgrade is not supported. Restore a compatible signed '
            'application or follow the institution-approved recovery procedure.',
          );
        },
      ),
    );
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    throw StateError(
      'No migration path exists from database version $oldVersion to '
      '$newVersion. The database has not been modified.',
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE children (
        child_id TEXT PRIMARY KEY,
        child_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE assessors (
        assessor_id TEXT PRIMARY KEY,
        last_used_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        session_uuid TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        assessor_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        session_no INTEGER NOT NULL CHECK (session_no BETWEEN 1 AND 6),
        session_date TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        status TEXT NOT NULL CHECK (
          status IN ('in_progress', 'interrupted', 'completed', 'abandoned')
        ),
        is_repeat INTEGER NOT NULL DEFAULT 0 CHECK (is_repeat IN (0, 1)),
        is_restart INTEGER NOT NULL DEFAULT 0 CHECK (is_restart IN (0, 1)),
        protocol_version TEXT NOT NULL,
        protocol_approval_reference TEXT NOT NULL,
        allocation_approval_reference TEXT NOT NULL,
        app_version TEXT NOT NULL,
        items_file_version TEXT NOT NULL,
        items_file_sha256 TEXT NOT NULL,
        next_ordinal INTEGER NOT NULL DEFAULT 1 CHECK (next_ordinal > 0),
        coins_so_far INTEGER NOT NULL DEFAULT 0 CHECK (coins_so_far >= 0),
        FOREIGN KEY (child_id) REFERENCES children(child_id),
        FOREIGN KEY (assessor_id) REFERENCES assessors(assessor_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_child_date
      ON sessions(child_id, session_date, started_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_resume
      ON sessions(status, child_id, session_no)
    ''');

    await db.execute('''
      CREATE TABLE session_manifest_items (
        session_uuid TEXT NOT NULL,
        ordinal INTEGER NOT NULL CHECK (ordinal > 0),
        phase TEXT NOT NULL CHECK (phase IN ('practice', 'test')),
        phase_trial_no INTEGER NOT NULL CHECK (phase_trial_no > 0),
        item_id TEXT NOT NULL,
        item_text TEXT NOT NULL,
        item_type TEXT NOT NULL CHECK (item_type IN ('word', 'nonword')),
        nonword_method TEXT,
        PRIMARY KEY (session_uuid, ordinal),
        UNIQUE (session_uuid, phase, phase_trial_no),
        UNIQUE (session_uuid, item_id),
        FOREIGN KEY (session_uuid) REFERENCES sessions(session_uuid)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE trials (
        trial_uuid TEXT PRIMARY KEY,
        session_uuid TEXT NOT NULL,
        ordinal INTEGER NOT NULL CHECK (ordinal > 0),
        phase TEXT NOT NULL CHECK (phase IN ('practice', 'test')),
        trial_no INTEGER NOT NULL CHECK (trial_no > 0),
        item_id TEXT NOT NULL,
        item_text TEXT NOT NULL,
        item_type TEXT NOT NULL CHECK (item_type IN ('word', 'nonword')),
        nonword_method TEXT,
        response TEXT CHECK (
          response IS NULL OR response IN ('word', 'nonword', 'none')
        ),
        correct INTEGER CHECK (correct IS NULL OR correct IN (0, 1)),
        rt_ms INTEGER CHECK (rt_ms IS NULL OR rt_ms >= 0),
        shown_at TEXT NOT NULL,
        answered_at TEXT,
        status TEXT NOT NULL CHECK (
          status IN ('presented', 'answered', 'no_response')
        ),
        coins_so_far INTEGER NOT NULL DEFAULT 0 CHECK (coins_so_far >= 0),
        app_version TEXT NOT NULL,
        items_file_version TEXT NOT NULL,
        UNIQUE (session_uuid, ordinal),
        UNIQUE (session_uuid, phase, trial_no),
        FOREIGN KEY (session_uuid) REFERENCES sessions(session_uuid)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_trials_session_phase
      ON trials(session_uuid, phase, trial_no)
    ''');

    await db.execute('''
      CREATE TABLE item_bank_metadata (
        version TEXT PRIMARY KEY,
        sha256 TEXT NOT NULL,
        approved_by TEXT NOT NULL,
        approval_reference TEXT NOT NULL,
        imported_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE TABLE exports (
        export_id TEXT PRIMARY KEY,
        exported_at TEXT NOT NULL,
        trials_file_name TEXT NOT NULL,
        sessions_file_name TEXT NOT NULL,
        include_names INTEGER NOT NULL DEFAULT 0 CHECK (include_names IN (0, 1)),
        row_count_trials INTEGER NOT NULL CHECK (row_count_trials >= 0),
        row_count_sessions INTEGER NOT NULL CHECK (row_count_sessions >= 0),
        app_version TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_metadata (
        metadata_key TEXT PRIMARY KEY,
        metadata_value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Creates a child/session and freezes the complete item order in SQLite.
  ///
  /// This cannot run until a real signed approval manifest is injected. The
  /// app currently has no such manifest, so participant session creation
  /// remains disabled by default.
  Future<String> createSession({
    required String childId,
    String? childName,
    required String assessorId,
    required String deviceId,
    required DateTime sessionDate,
    required String appVersion,
    required SessionAllocation manifest,
    required StudyItemBank itemBank,
    bool isRepeat = false,
    bool isRestart = false,
  }) async {
    if (!_releaseGate.isOpen) {
      throw StateError(
        'Participant session creation is locked: '
        '${_releaseGate.blockers.join(' ')}',
      );
    }

    manifest.validateAgainst(itemBank);
    if (childId.trim().isEmpty ||
        assessorId.trim().isEmpty ||
        deviceId.trim().isEmpty ||
        appVersion.trim().isEmpty) {
      throw ArgumentError('Child, assessor, device and app IDs are required.');
    }
    if (isRepeat && isRestart) {
      throw ArgumentError('A session cannot be both a repeat and a restart.');
    }
    if (isRepeat || isRestart) {
      throw StateError(
        'Repeat/restart is disabled until a trusted supervisor authorization '
        'verifier is implemented. A caller-supplied boolean is not proof of '
        'authorization.',
      );
    }

    final db = await database;
    final now = DateTime.now();
    final createdAt = _timestamp(now);
    final sessionUuid = _uuid.v4();

    return db.transaction((txn) async {
      await txn.insert(
        'children',
        <String, Object?>{
          'child_id': childId.trim(),
          'child_name': childName?.trim().isEmpty == true ? null : childName?.trim(),
          'created_at': createdAt,
          'updated_at': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (childName != null && childName.trim().isNotEmpty) {
        await txn.update(
          'children',
          <String, Object?>{
            'child_name': childName.trim(),
            'updated_at': createdAt,
          },
          where: 'child_id = ?',
          whereArgs: <Object?>[childId.trim()],
        );
      }

      await txn.insert(
        'assessors',
        <String, Object?>{
          'assessor_id': assessorId.trim(),
          'last_used_at': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await txn.update(
        'assessors',
        <String, Object?>{'last_used_at': createdAt},
        where: 'assessor_id = ?',
        whereArgs: <Object?>[assessorId.trim()],
      );

      final sameSession = await txn.query(
        'sessions',
        columns: <String>['session_uuid', 'status'],
        where: 'child_id = ? AND session_no = ?',
        whereArgs: <Object?>[childId.trim(), manifest.sessionNumber],
      );

      if (sameSession.isNotEmpty) {
        throw StateError(
          'This session number already has a record. Repeat/restart remains '
          'disabled until a trusted supervisor authorization verifier and '
          'the signed study policy are implemented.',
        );
      }

      final storedBankRows = await txn.query(
        'item_bank_metadata',
        where: 'version = ?',
        whereArgs: <Object?>[itemBank.version],
        limit: 1,
      );
      if (storedBankRows.isNotEmpty &&
          storedBankRows.single['sha256'] != itemBank.sha256) {
        throw StateError(
          'An item-bank version already exists with a different checksum.',
        );
      }
      await txn.update(
        'item_bank_metadata',
        <String, Object?>{'is_active': 0},
        where: 'is_active = ?',
        whereArgs: <Object?>[1],
      );
      if (storedBankRows.isEmpty) {
        await txn.insert(
          'item_bank_metadata',
          <String, Object?>{
            'version': itemBank.version,
            'sha256': itemBank.sha256,
            'approved_by': itemBank.approvedBy,
            'approval_reference': itemBank.approvalReference,
            'imported_at': createdAt,
            'is_active': 1,
          },
        );
      } else {
        await txn.update(
          'item_bank_metadata',
          <String, Object?>{'is_active': 1},
          where: 'version = ?',
          whereArgs: <Object?>[itemBank.version],
        );
      }

      final dayKey = _dateKey(sessionDate);
      final sameDay = await txn.query(
        'sessions',
        columns: <String>['session_uuid'],
        where: 'child_id = ? AND session_date = ?',
        whereArgs: <Object?>[childId.trim(), dayKey],
        limit: 1,
      );
      if (sameDay.isNotEmpty) {
        throw StateError(
          'This child already has a session recorded on this date. '
          'The study team must define the same-day exception policy.',
        );
      }

      await txn.insert(
        'sessions',
        <String, Object?>{
          'session_uuid': sessionUuid,
          'child_id': childId.trim(),
          'assessor_id': assessorId.trim(),
          'device_id': deviceId.trim(),
          'session_no': manifest.sessionNumber,
          'session_date': dayKey,
          'started_at': createdAt,
          'completed_at': null,
          'status': 'in_progress',
          'is_repeat': isRepeat ? 1 : 0,
          'is_restart': isRestart ? 1 : 0,
          'protocol_version': manifest.protocolVersion,
          'protocol_approval_reference': manifest.protocolApprovalReference,
          'allocation_approval_reference': manifest.allocationApprovalReference,
          'app_version': appVersion,
          'items_file_version': manifest.itemBankVersion,
          'items_file_sha256': manifest.itemBankSha256,
          'next_ordinal': 1,
          'coins_so_far': 0,
        },
      );

      final batch = txn.batch();
      for (final trial in manifest.orderedTrials) {
        batch.insert(
          'session_manifest_items',
          <String, Object?>{
            'session_uuid': sessionUuid,
            'ordinal': trial.ordinal,
            'phase': trial.phase.storageValue,
            'phase_trial_no': trial.phaseTrialNumber,
            'item_id': trial.item.id,
            'item_text': trial.item.text,
            'item_type': trial.item.type.storageValue,
            'nonword_method': trial.item.nonWordMethod,
          },
        );
      }
      await batch.commit(noResult: true);

      return sessionUuid;
    });
  }

  Future<ActiveSessionSnapshot?> loadSession(String sessionUuid) async {
    final db = await database;
    final sessionRows = await db.query(
      'sessions',
      where: 'session_uuid = ?',
      whereArgs: <Object?>[sessionUuid],
      limit: 1,
    );
    if (sessionRows.isEmpty) return null;

    final session = sessionRows.single;
    final ordinal = session['next_ordinal'] as int;
    final manifestRows = await db.query(
      'session_manifest_items',
      where: 'session_uuid = ? AND ordinal = ?',
      whereArgs: <Object?>[sessionUuid, ordinal],
      limit: 1,
    );
    final presentedRows = await db.query(
      'trials',
      columns: <String>['trial_uuid', 'shown_at'],
      where: 'session_uuid = ? AND ordinal = ? AND status = ?',
      whereArgs: <Object?>[sessionUuid, ordinal, 'presented'],
      limit: 1,
    );

    return ActiveSessionSnapshot(
      sessionUuid: sessionUuid,
      childId: session['child_id'] as String,
      assessorId: session['assessor_id'] as String,
      sessionNumber: session['session_no'] as int,
      status: session['status'] as String,
      nextOrdinal: ordinal,
      coinsSoFar: session['coins_so_far'] as int,
      nextTrial: manifestRows.isEmpty
          ? null
          : _plannedTrialFromRow(manifestRows.single),
      presentedTrialUuid:
          presentedRows.isEmpty ? null : presentedRows.single['trial_uuid'] as String,
      presentedAt:
          presentedRows.isEmpty ? null : presentedRows.single['shown_at'] as String,
    );
  }

  /// Performs a read-only consistency audit against the immutable session
  /// manifest. All three reads share one SQLite transaction snapshot so a
  /// concurrent response commit cannot produce a mixed-state report.
  ///
  /// Returns null when the session UUID does not exist.
  Future<SessionIntegrityReport?> auditSession(String sessionUuid) async {
    if (sessionUuid.trim().isEmpty) {
      throw ArgumentError.value(sessionUuid, 'sessionUuid');
    }

    final db = await database;
    return db.transaction((txn) async {
      final sessions = await txn.query(
        'sessions',
        where: 'session_uuid = ?',
        whereArgs: <Object?>[sessionUuid],
        limit: 1,
      );
      if (sessions.isEmpty) return null;

      final manifestItems = await txn.query(
        'session_manifest_items',
        where: 'session_uuid = ?',
        whereArgs: <Object?>[sessionUuid],
        orderBy: 'ordinal ASC',
      );
      final trials = await txn.query(
        'trials',
        where: 'session_uuid = ?',
        whereArgs: <Object?>[sessionUuid],
        orderBy: 'ordinal ASC',
      );

      return SessionIntegrityAudit.inspect(
        session: sessions.single,
        manifestItems: manifestItems,
        trials: trials,
      );
    });
  }

  Future<List<Map<String, Object?>>> getChildSessionHistory(
    String childId,
  ) async {
    final db = await database;
    return db.query(
      'sessions',
      where: 'child_id = ?',
      whereArgs: <Object?>[childId],
      orderBy: 'session_date DESC, started_at DESC',
    );
  }

  /// Writes the "presented" event before enabling child response controls.
  Future<String> beginTrial({
    required String sessionUuid,
    required PlannedTrial plannedTrial,
    required DateTime shownAt,
    required String appVersion,
    required String itemBankVersion,
  }) async {
    if (!_releaseGate.isOpen) {
      throw StateError(
        'Trial presentation is locked until the signed field-release '
        'authorization is verified: ${_releaseGate.blockers.join(' ')}',
      );
    }
    final db = await database;
    final trialUuid = _uuid.v4();

    await db.transaction((txn) async {
      if (appVersion.trim().isEmpty || itemBankVersion.trim().isEmpty) {
        throw ArgumentError('App and item-bank versions are required.');
      }

      final sessionRows = await txn.query(
        'sessions',
        columns: <String>[
          'status',
          'next_ordinal',
          'coins_so_far',
          'items_file_version',
        ],
        where: 'session_uuid = ?',
        whereArgs: <Object?>[sessionUuid],
        limit: 1,
      );
      if (sessionRows.isEmpty || sessionRows.single['status'] != 'in_progress') {
        throw StateError('The session is not available for a new trial.');
      }
      if (sessionRows.single['items_file_version'] != itemBankVersion) {
        throw StateError(
          'The trial item-bank version does not match the frozen session manifest.',
        );
      }

      final pendingPresentedTrials = await txn.query(
        'trials',
        columns: <String>['trial_uuid'],
        where: 'session_uuid = ? AND status = ?',
        whereArgs: <Object?>[sessionUuid, 'presented'],
        limit: 1,
      );
      if (pendingPresentedTrials.isNotEmpty) {
        throw StateError(
          'A previously presented trial has no committed response. The app '
          'will not present a second stimulus until the study-approved '
          'recovery procedure resolves the original presentation.',
        );
      }

      final expectedOrdinal = sessionRows.single['next_ordinal'] as int;
      if (plannedTrial.ordinal != expectedOrdinal) {
        throw StateError('The trial is not the next frozen manifest item.');
      }

      final manifestRows = await txn.query(
        'session_manifest_items',
        where: 'session_uuid = ? AND ordinal = ?',
        whereArgs: <Object?>[sessionUuid, expectedOrdinal],
        limit: 1,
      );
      if (manifestRows.isEmpty) {
        throw StateError('The frozen session manifest is incomplete.');
      }
      final frozen = manifestRows.single;
      if (frozen['item_id'] != plannedTrial.item.id ||
          frozen['item_text'] != plannedTrial.item.text ||
          frozen['item_type'] != plannedTrial.item.type.storageValue ||
          frozen['nonword_method'] != plannedTrial.item.nonWordMethod ||
          frozen['phase'] != plannedTrial.phase.storageValue ||
          frozen['phase_trial_no'] != plannedTrial.phaseTrialNumber) {
        throw StateError(
          'The displayed trial does not exactly match the frozen manifest.',
        );
      }

      await txn.insert(
        'trials',
        <String, Object?>{
          'trial_uuid': trialUuid,
          'session_uuid': sessionUuid,
          'ordinal': plannedTrial.ordinal,
          'phase': plannedTrial.phase.storageValue,
          'trial_no': plannedTrial.phaseTrialNumber,
          'item_id': plannedTrial.item.id,
          'item_text': plannedTrial.item.text,
          'item_type': plannedTrial.item.type.storageValue,
          'nonword_method': plannedTrial.item.nonWordMethod,
          'response': null,
          'correct': null,
          'rt_ms': null,
          'shown_at': _timestamp(shownAt),
          'answered_at': null,
          'status': 'presented',
          'coins_so_far': sessionRows.single['coins_so_far'] as int,
          'app_version': appVersion,
          'items_file_version': itemBankVersion,
        },
      );
    });

    return trialUuid;
  }

  /// Saves the response and moves the session cursor in one atomic transaction.
  Future<void> completeTrial({
    required String trialUuid,
    required String response,
    required int? reactionTimeMs,
    required DateTime? answeredAt,
  }) async {
    if (!_releaseGate.isOpen) {
      throw StateError(
        'Trial response persistence is locked until the signed field-release '
        'authorization is verified: ${_releaseGate.blockers.join(' ')}',
      );
    }
    if (response != 'word' && response != 'nonword' && response != 'none') {
      throw ArgumentError.value(response, 'response');
    }
    if (response == 'none' &&
        (reactionTimeMs != null || answeredAt != null)) {
      throw ArgumentError(
        'A no-response trial must keep RT and answer time blank.',
      );
    }
    if (response != 'none' &&
        (reactionTimeMs == null || answeredAt == null)) {
      throw ArgumentError(
        'Answered trials require RT and answer timestamp.',
      );
    }
    if (reactionTimeMs != null && reactionTimeMs < 0) {
      throw ArgumentError.value(reactionTimeMs, 'reactionTimeMs');
    }
    final db = await database;
    await db.transaction((txn) async {
      final trialRows = await txn.query(
        'trials',
        where: 'trial_uuid = ?',
        whereArgs: <Object?>[trialUuid],
        limit: 1,
      );
      if (trialRows.isEmpty) throw StateError('Presented trial not found.');

      final trial = trialRows.single;
      if (trial['status'] != 'presented' || trial['response'] != null) {
        throw StateError('This trial response has already been committed.');
      }

      final shownAtRaw = trial['shown_at'];
      if (shownAtRaw is! String) {
        throw StateError('The presented trial has no valid presentation timestamp.');
      }
      final shownAt = DateTime.tryParse(shownAtRaw);
      if (shownAt == null) {
        throw StateError('The presented trial timestamp could not be parsed.');
      }
      TrialResponseValidation.validate(
        response: response,
        reactionTimeMs: reactionTimeMs,
        shownAt: shownAt,
        answeredAt: answeredAt,
      );

      final sessionUuid = trial['session_uuid'] as String;
      final ordinal = trial['ordinal'] as int;
      final sessionRows = await txn.query(
        'sessions',
        columns: <String>['status', 'next_ordinal', 'coins_so_far'],
        where: 'session_uuid = ?',
        whereArgs: <Object?>[sessionUuid],
        limit: 1,
      );
      if (sessionRows.isEmpty ||
          sessionRows.single['status'] != 'in_progress' ||
          sessionRows.single['next_ordinal'] != ordinal) {
        throw StateError('The session cursor no longer matches this trial.');
      }
      // Reward state is read from committed storage, never accepted from the
      // child UI. The exact reward policy remains disabled pending PI approval.
      final storedCoins = sessionRows.single['coins_so_far'] as int;

      final expectedType = trial['item_type'] as String;
      final correct = response == 'none'
          ? null
          : response == expectedType;
      final newStatus = response == 'none' ? 'no_response' : 'answered';
      final trialUpdates = await txn.update(
        'trials',
        <String, Object?>{
          'response': response,
          'correct': correct == null ? null : (correct ? 1 : 0),
          'rt_ms': reactionTimeMs,
          'answered_at': answeredAt == null ? null : _timestamp(answeredAt),
          'status': newStatus,
          'coins_so_far': storedCoins,
        },
        where: 'trial_uuid = ? AND status = ?',
        whereArgs: <Object?>[trialUuid, 'presented'],
      );
      if (trialUpdates != 1) {
        throw StateError('The trial response could not be committed exactly once.');
      }

      final nextOrdinal = ordinal + 1;
      final remaining = await txn.query(
        'session_manifest_items',
        columns: <String>['ordinal'],
        where: 'session_uuid = ? AND ordinal >= ?',
        whereArgs: <Object?>[sessionUuid, nextOrdinal],
        limit: 1,
      );
      final completed = remaining.isEmpty;

      final sessionUpdates = await txn.update(
        'sessions',
        <String, Object?>{
          'next_ordinal': nextOrdinal,
          'status': completed ? 'completed' : 'in_progress',
          'completed_at': completed ? _timestamp(DateTime.now()) : null,
        },
        where: 'session_uuid = ? AND next_ordinal = ?',
        whereArgs: <Object?>[sessionUuid, ordinal],
      );
      if (sessionUpdates != 1) {
        throw StateError('The session cursor could not be advanced exactly once.');
      }
    });
  }

  Future<void> markInterrupted(String sessionUuid) async {
    if (!_releaseGate.isOpen) {
      throw StateError(
        'Session interruption persistence is locked until the signed '
        'field-release authorization is verified: '
        '${_releaseGate.blockers.join(' ')}',
      );
    }
    final db = await database;
    final updated = await db.update(
      'sessions',
      <String, Object?>{'status': 'interrupted'},
      where: 'session_uuid = ? AND status = ?',
      whereArgs: <Object?>[sessionUuid, 'in_progress'],
    );
    if (updated != 1) {
      throw StateError(
        'The session was not in progress and could not be marked interrupted.',
      );
    }
  }

  Future<void> markResumed(String sessionUuid) async {
    if (!_releaseGate.isOpen) {
      throw StateError(
        'Session resume is locked until interruption handling has approved '
        'references: ${_releaseGate.blockers.join(' ')}',
      );
    }
    final db = await database;
    await db.transaction((txn) async {
      final sessionRows = await txn.query(
        'sessions',
        columns: <String>['status'],
        where: 'session_uuid = ?',
        whereArgs: <Object?>[sessionUuid],
        limit: 1,
      );
      if (sessionRows.isEmpty) {
        throw StateError('The interrupted session could not be found.');
      }

      final pendingPresentedTrials = await txn.query(
        'trials',
        columns: <String>['trial_uuid'],
        where: 'session_uuid = ? AND status = ?',
        whereArgs: <Object?>[sessionUuid, 'presented'],
        limit: 1,
      );
      final disposition = SessionRecoveryPolicy.evaluate(
        sessionStatus: sessionRows.single['status'] as String,
        hasUnansweredPresentedTrial: pendingPresentedTrials.isNotEmpty,
      );
      switch (disposition) {
        case SessionRecoveryDisposition.notInterrupted:
          throw StateError('Only an interrupted session can be resumed.');
        case SessionRecoveryDisposition.requiresSupervisorReview:
          throw StateError(
            'This session contains a presented trial without a committed '
            'response. Resume is blocked until the study team approves and '
            'implements its handling; the original trial record is preserved.',
          );
        case SessionRecoveryDisposition.readyToResume:
          break;
      }

      final updated = await txn.update(
        'sessions',
        <String, Object?>{'status': 'in_progress'},
        where: 'session_uuid = ? AND status = ?',
        whereArgs: <Object?>[sessionUuid, 'interrupted'],
      );
      if (updated != 1) {
        throw StateError(
          'The session was not interrupted and could not be resumed.',
        );
      }
    });
  }

  Future<void> close() {
    final closing = _closingDatabase;
    if (closing != null) return closing.future;

    final completer = Completer<void>();
    _closingDatabase = completer;
    _performClose(completer);
    return completer.future;
  }

  Future<void> _performClose(Completer<void> completer) async {
    try {
      // A close racing initialisation must wait for the single-flight open and
      // close that handle as well. Otherwise the database could be left open
      // after the caller believes close() has completed.
      final opening = _openingDatabase;
      Database? opened;
      if (opening != null) {
        try {
          opened = await opening;
        } catch (_) {
          // The database did not open; there is no handle to close. Preserve
          // the original open error for the caller that initiated the open.
        }
      }

      final db = _database ?? opened;
      if (db != null && db.isOpen) await db.close();
      // Retain the handle when close fails so a later caller can retry rather
      // than losing the only reference to an open database connection.
      if (identical(_database, db)) _database = null;
      if (identical(_openingDatabase, opening)) _openingDatabase = null;
      if (!completer.isCompleted) completer.complete();
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    } finally {
      if (identical(_closingDatabase, completer)) _closingDatabase = null;
    }
  }

  PlannedTrial _plannedTrialFromRow(Map<String, Object?> row) {
    final phase = row['phase'] as String;
    final type = row['item_type'] as String;
    return PlannedTrial(
      ordinal: row['ordinal'] as int,
      phase: phase == 'practice' ? TrialPhase.practice : TrialPhase.test,
      phaseTrialNumber: row['phase_trial_no'] as int,
      item: StudyItem(
        id: row['item_id'] as String,
        text: row['item_text'] as String,
        type: type == 'word' ? StudyItemType.realWord : StudyItemType.nonWord,
        nonWordMethod: row['nonword_method'] as String?,
      ),
    );
  }

  String _timestamp(DateTime value) => LocalTimestamp.format(value);

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
