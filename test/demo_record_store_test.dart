import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padalab_android/data/demo/demo_record_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('persists and reloads only synthetic demo response records', () async {
    final store = DemoRecordStore.instance;
    await store.clear();

    await store.append(const DemoTrialRecord(
      sessionId: 'demo-session-1',
      ordinal: 1,
      phase: 'practice',
      itemId: 'PRACTICE-01',
      stimulus: 'ಮನೆ',
      itemKind: 'word',
      response: 'word',
      correct: true,
      reactionTimeMs: 412,
      respondedAt: '2026-11-07T10:00:00.000Z',
    ));

    final rows = await store.readAll();
    expect(rows, hasLength(1));
    expect(rows.single.sessionId, 'demo-session-1');
    expect(rows.single.stimulus, 'ಮನೆ');
    expect(rows.single.correct, isTrue);

    await store.clear();
    expect(await store.readAll(), isEmpty);
  });
}
