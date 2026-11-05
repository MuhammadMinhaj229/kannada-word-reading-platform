import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item.dart';
import 'package:padalab_android/features/assessment/domain/services/session_allocator.dart';

void main() {
  const allocator = SessionAllocator();

  List<StudyItem> makeWords(int count) => List<StudyItem>.generate(
        count,
        (index) => StudyItem(
          id: 'W${(index + 1).toString().padLeft(3, '0')}',
          text: 'ಪದ${index + 1}',
          type: StudyItemType.realWord,
        ),
        growable: false,
      );

  List<StudyItem> makeNonWords(int count) => List<StudyItem>.generate(
        count,
        (index) => StudyItem(
          id: 'N${(index + 1).toString().padLeft(3, '0')}',
          text: 'ಕಲ್ಪಿತ${index + 1}',
          type: StudyItemType.nonWord,
          nonWordMethod: 'test_fixture',
        ),
        growable: false,
      );

  test('allocates six unique sessions with 45 real and 32 non-words', () {
    final sessions = allocator.allocate(
      realWords: makeWords(270),
      nonWords: makeNonWords(194),
      seed: 20261104,
    );

    expect(sessions, hasLength(6));
    for (var index = 0; index < sessions.length; index += 1) {
      final session = sessions[index];
      expect(session.sessionNumber, index + 1);
      expect(session.realWords, hasLength(45));
      expect(session.nonWords, hasLength(32));
      expect(session.orderedItems, hasLength(77));
      expect(
        session.orderedItems.map((item) => item.id).toSet(),
        hasLength(77),
      );
    }
  });

  test('retains exactly two non-words outside the six sessions', () {
    final sessions = allocator.allocate(
      realWords: makeWords(270),
      nonWords: makeNonWords(194),
      seed: 42,
    );

    final allocated = sessions
        .expand((session) => session.nonWords)
        .map((item) => item.id)
        .toSet();

    expect(allocated, hasLength(192));
    expect(
      makeNonWords(194).map((item) => item.id).toSet().difference(allocated),
      hasLength(2),
    );
  });

  test('same seed produces the same item ordering', () {
    final words = makeWords(270);
    final nonWords = makeNonWords(194);

    final first = allocator.allocate(
      realWords: words,
      nonWords: nonWords,
      seed: 77,
    );
    final second = allocator.allocate(
      realWords: words,
      nonWords: nonWords,
      seed: 77,
    );

    for (var index = 0; index < first.length; index += 1) {
      expect(
        first[index].orderedItems.map((item) => item.id).toList(),
        second[index].orderedItems.map((item) => item.id).toList(),
      );
    }
  });

  test('rejects the current incomplete non-word upload', () {
    expect(
      () => allocator.allocate(
        realWords: makeWords(270),
        nonWords: makeNonWords(193),
        seed: 1,
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate stimulus identifiers', () {
    final words = makeWords(270).toList();
    words[1] = StudyItem(
      id: words[0].id,
      text: 'ಬೇರೆಪದ',
      type: StudyItemType.realWord,
    );

    expect(
      () => allocator.allocate(
        realWords: words,
        nonWords: makeNonWords(194),
        seed: 1,
      ),
      throwsArgumentError,
    );
  });
}
