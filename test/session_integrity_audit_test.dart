import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/services/session_integrity_audit.dart';

void main() {
  const sessionUuid = 'session-001';

  Map<String, Object?> session({
    String status = 'in_progress',
    int nextOrdinal = 1,
    String? completedAt,
  }) => <String, Object?>{
        'session_uuid': sessionUuid,
        'status': status,
        'next_ordinal': nextOrdinal,
        'completed_at': completedAt,
      };

  Map<String, Object?> manifest(
    int ordinal, {
    String phase = 'test',
    int? phaseTrialNo,
    String itemId = 'W001',
    String text = 'ಮನೆ',
    String type = 'word',
  }) =>
      <String, Object?>{
        'session_uuid': sessionUuid,
        'ordinal': ordinal,
        'phase': phase,
        'phase_trial_no': phaseTrialNo ?? ordinal,
        'item_id': itemId,
        'item_text': text,
        'item_type': type,
        'nonword_method': null,
      };

  Map<String, Object?> trial(
    int ordinal, {
    String status = 'presented',
    String? response,
    Object? correct,
    Object? reactionTime,
    String? answeredAt,
    String itemId = 'W001',
    String text = 'ಮನೆ',
    String type = 'word',
    String phase = 'test',
    int? phaseTrialNo,
  }) =>
      <String, Object?>{
        'trial_uuid': 'trial-$ordinal',
        'session_uuid': sessionUuid,
        'ordinal': ordinal,
        'phase': phase,
        'trial_no': phaseTrialNo ?? ordinal,
        'item_id': itemId,
        'item_text': text,
        'item_type': type,
        'nonword_method': null,
        'response': response,
        'correct': correct,
        'rt_ms': reactionTime,
        'shown_at': '2026-11-11T10:00:00Z',
        'answered_at': answeredAt,
        'status': status,
      };

  test('accepts a new session with no presented trials yet', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(),
      manifestItems: <Map<String, Object?>>[manifest(1)],
      trials: const <Map<String, Object?>>[],
    );

    expect(report.isValid, isTrue, reason: report.errors.join('\n'));
  });

  test('accepts a committed earlier trial and a pending presentation at the cursor', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(nextOrdinal: 2),
      manifestItems: <Map<String, Object?>>[
        manifest(1),
        manifest(2, itemId: 'W002', text: 'ಮರ'),
      ],
      trials: <Map<String, Object?>>[
        trial(
          1,
          status: 'answered',
          response: 'word',
          correct: 1,
          reactionTime: 820,
          answeredAt: '2026-11-11T10:00:00.820Z',
        ),
        trial(2, itemId: 'W002', text: 'ಮರ'),
      ],
    );

    expect(report.isValid, isTrue, reason: report.errors.join('\n'));
  });

  test('accepts a completed session only when all manifest trials are terminal', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(
        status: 'completed',
        nextOrdinal: 3,
        completedAt: '2026-11-11T10:02:00Z',
      ),
      manifestItems: <Map<String, Object?>>[
        manifest(1, phase: 'practice', phaseTrialNo: 1),
        manifest(2, itemId: 'W002', text: 'ಮರ', phaseTrialNo: 1),
      ],
      trials: <Map<String, Object?>>[
        trial(
          1,
          phase: 'practice',
          phaseTrialNo: 1,
          status: 'answered',
          response: 'word',
          correct: 1,
          reactionTime: 820,
          answeredAt: '2026-11-11T10:00:00.820Z',
        ),
        trial(
          2,
          itemId: 'W002',
          text: 'ಮರ',
          phaseTrialNo: 1,
          status: 'no_response',
          response: 'none',
        ),
      ],
    );

    expect(report.isValid, isTrue, reason: report.errors.join('\n'));
  });

  test('detects a trial that differs from its frozen manifest item', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(nextOrdinal: 2),
      manifestItems: <Map<String, Object?>>[
        manifest(1),
        manifest(2, itemId: 'W002', text: 'ಮರ'),
      ],
      trials: <Map<String, Object?>>[
        trial(
          1,
          status: 'answered',
          response: 'word',
          correct: 1,
          reactionTime: 820,
          answeredAt: '2026-11-11T10:00:00.820Z',
          itemId: 'WRONG',
        ),
      ],
    );

    expect(report.isValid, isFalse);
    expect(report.errors, contains(
      'Trial at ordinal 1 does not match manifest field item_id.',
    ));
  });

  test('detects missing committed trials before the cursor', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(nextOrdinal: 2),
      manifestItems: <Map<String, Object?>>[
        manifest(1),
        manifest(2, itemId: 'W002', text: 'ಮರ'),
      ],
      trials: const <Map<String, Object?>>[],
    );

    expect(report.isValid, isFalse);
    expect(
      report.errors,
      contains('Completed cursor position 1 has no persisted trial.'),
    );
  });

  test('detects trials ahead of the current cursor', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(),
      manifestItems: <Map<String, Object?>>[
        manifest(1),
        manifest(2, itemId: 'W002', text: 'ಮರ'),
      ],
      trials: <Map<String, Object?>>[
        trial(2, itemId: 'W002', text: 'ಮರ'),
      ],
    );

    expect(report.isValid, isFalse);
    expect(report.errors, contains('Trial ordinal 2 is ahead of the session cursor.'));
  });

  test('detects an answered trial whose answer predates its stimulus', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(nextOrdinal: 2),
      manifestItems: <Map<String, Object?>>[
        manifest(1),
      ],
      trials: <Map<String, Object?>>[
        trial(
          1,
          status: 'answered',
          response: 'word',
          correct: 1,
          reactionTime: 820,
          answeredAt: '2026-11-11T09:59:59Z',
        ),
      ],
    );

    expect(report.isValid, isFalse);
    expect(
      report.errors,
      contains('Answered trial at ordinal 1 has an invalid answer timestamp.'),
    );
  });

  test('detects inconsistent no-response records', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(nextOrdinal: 2),
      manifestItems: <Map<String, Object?>>[manifest(1)],
      trials: <Map<String, Object?>>[
        trial(1, status: 'no_response', response: 'word'),
      ],
    );

    expect(report.isValid, isFalse);
    expect(
      report.errors,
      contains('No-response trial at ordinal 1 contains inconsistent response data.'),
    );
  });

  test('detects completed state before the end of the manifest', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(
        status: 'completed',
        nextOrdinal: 2,
        completedAt: '2026-11-11T10:02:00Z',
      ),
      manifestItems: <Map<String, Object?>>[
        manifest(1),
        manifest(2, itemId: 'W002', text: 'ಮರ'),
      ],
      trials: <Map<String, Object?>>[
        trial(
          1,
          status: 'answered',
          response: 'word',
          correct: 1,
          reactionTime: 820,
          answeredAt: '2026-11-11T10:00:00.820Z',
        ),
      ],
    );

    expect(report.isValid, isFalse);
    expect(
      report.errors,
      contains('Completed session cursor does not follow the final manifest item.'),
    );
  });

  test('rejects an unanswered presented trial before the session cursor', () {
    final report = SessionIntegrityAudit.inspect(
      session: session(nextOrdinal: 2),
      manifestItems: <Map<String, Object?>>[
        manifest(1),
        manifest(2, itemId: 'W002', text: 'ಮರ'),
      ],
      trials: <Map<String, Object?>>[
        trial(1),
      ],
    );

    expect(report.isValid, isFalse);
    expect(
      report.errors,
      contains('Cursor position 1 is not in a terminal trial state.'),
    );
  });
}
