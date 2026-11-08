import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/core/time/local_timestamp.dart';
import 'package:padalab_android/features/assessment/domain/models/trial_record.dart';

void main() {
  final shownAt = DateTime.utc(2026, 11, 4, 12, 30);

  TrialRecord fixture({
    int ordinal = 1,
    String phase = 'test',
    String? response = 'word',
    bool? correct = true,
    int? reactionTimeMs = 742,
  }) {
    return TrialRecord(
      trialUuid: 'trial-001',
      sessionUuid: 'session-001',
      ordinal: ordinal,
      phase: phase,
      trialNumber: 1,
      itemId: 'W001',
      itemText: 'ಕಮಲ',
      itemType: 'word',
      shownAt: shownAt,
      answeredAt: response == null || response == 'none'
          ? null
          : shownAt.add(
              Duration(milliseconds: reactionTimeMs ?? 0),
            ),
      response: response,
      correct: correct,
      reactionTimeMs: reactionTimeMs,
      coinsSoFar: 0,
      appVersion: '0.1.0',
      itemBankVersion: 'pending',
    );
  }

  test('serializes correctness and reaction time using export field names', () {
    final row = fixture().toDatabaseMap();

    expect(row['item_id'], 'W001');
    expect(row['item_text'], 'ಕಮಲ');
    expect(row['ordinal'], 1);
    expect(row['phase'], 'test');
    expect(row['item_type'], 'word');
    expect(row['response'], 'word');
    expect(row['correct'], 1);
    expect(row['rt_ms'], 742);
    expect(row['status'], 'answered');
    expect(row['shown_at'], shownAt.toIso8601String());
  });

  test('keeps missing responses distinguishable from incorrect answers', () {
    final row = fixture(
      response: 'none',
      correct: null,
      reactionTimeMs: null,
    ).toDatabaseMap();

    expect(row['response'], 'none');
    expect(row['correct'], isNull);
    expect(row['rt_ms'], isNull);
    expect(row['answered_at'], isNull);
    expect(row['status'], 'no_response');
  });

  test('rejects invalid trial phases', () {
    expect(
      () => fixture(phase: 'scored').toDatabaseMap(),
      throwsArgumentError,
    );
  });


  test('serializes an unanswered presentation with the database status', () {
    final row = fixture(
      response: null,
      correct: null,
      reactionTimeMs: null,
    ).toDatabaseMap();

    expect(row['status'], 'presented');
    expect(row['response'], isNull);
    expect(row['rt_ms'], isNull);
    expect(row['answered_at'], isNull);
  });

  test('rejects an invalid global manifest ordinal', () {
    expect(
      () => fixture(ordinal: 0).toDatabaseMap(),
      throwsArgumentError,
    );
  });

  test('rejects an answer timestamp before the stimulus timestamp', () {
    final invalid = TrialRecord(
      trialUuid: 'trial-001',
      sessionUuid: 'session-001',
      ordinal: 1,
      phase: 'test',
      trialNumber: 1,
      itemId: 'W001',
      itemText: 'ಕಮಲ',
      itemType: 'word',
      shownAt: shownAt,
      answeredAt: shownAt.subtract(const Duration(milliseconds: 1)),
      response: 'word',
      correct: true,
      reactionTimeMs: 1,
      coinsSoFar: 0,
      appVersion: '0.1.0',
      itemBankVersion: 'pending',
    );

    expect(() => invalid.toDatabaseMap(), throwsArgumentError);
  });

  test('serializes local timestamps with an explicit UTC offset', () {
    final instant = DateTime.utc(2026, 11, 4, 12, 30);

    expect(
      LocalTimestamp.format(instant),
      '2026-11-04T12:30:00.000Z',
    );
    expect(
      LocalTimestamp.format(
        instant,
        offsetOverride: const Duration(minutes: 330),
      ),
      '2026-11-04T12:30:00.000+05:30',
    );
  });

  test('rejects correctness when no answer exists', () {
    expect(
      () => fixture(response: null, correct: true).toDatabaseMap(),
      throwsArgumentError,
    );
  });

  test('rejects correctness for an explicit no-response trial', () {
    expect(
      () => fixture(response: 'none', correct: false).toDatabaseMap(),
      throwsArgumentError,
    );
  });
}
