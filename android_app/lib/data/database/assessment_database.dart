import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../features/assessment/domain/models/trial_record.dart';

/// Local-only SQLite boundary.
///
/// The assessment controller must await [persistTrial] before it presents
/// the next stimulus. A failed write must keep the current item on screen.
class AssessmentDatabase {
  AssessmentDatabase._();

  static final AssessmentDatabase instance = AssessmentDatabase._();

  static const int schemaVersion = 1;
  static const String databaseFileName = 'padalab_assessment.db';

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    final databasePath = path.join(
      await getDatabasesPath(),
      databaseFileName,
    );

    final opened = await openDatabase(
      databasePath,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: _createSchema,
    );

    _database = opened;
    return opened;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE children (
        child_id TEXT PRIMARY KEY,
        child_name TEXT,
        created_at TEXT NOT NULL
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
        app_version TEXT NOT NULL,
        items_file_version TEXT NOT NULL,
        FOREIGN KEY (child_id) REFERENCES children(child_id),
        FOREIGN KEY (assessor_id) REFERENCES assessors(assessor_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_child_date
      ON sessions(child_id, session_date)
    ''');

    await db.execute('''
      CREATE TABLE trials (
        trial_uuid TEXT PRIMARY KEY,
        session_uuid TEXT NOT NULL,
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
        rt_ms INTEGER,
        shown_at TEXT NOT NULL,
        answered_at TEXT,
        coins_so_far INTEGER NOT NULL DEFAULT 0,
        app_version TEXT NOT NULL,
        items_file_version TEXT NOT NULL,
        UNIQUE(session_uuid, phase, trial_no),
        FOREIGN KEY (session_uuid) REFERENCES sessions(session_uuid)
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
        row_count_trials INTEGER NOT NULL,
        row_count_sessions INTEGER NOT NULL,
        app_version TEXT NOT NULL
      )
    ''');
  }

  Future<void> persistTrial(TrialRecord trial) async {
    final db = await database;
    await db.insert(
      'trials',
      trial.toDatabaseMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
