import 'dart:math';

import '../../../../core/config/study_protocol.dart';
import '../models/session_allocation.dart';
import '../models/study_item.dart';

/// Creates a reproducible six-session allocation from an approved bank.
///
/// Persist the resulting ordered lists before a participant starts. A
/// resumed session must restore its saved order instead of allocating again.
/// This seeded random strategy is a foundation; protocol-required
/// stratification must be agreed and validated before field activation.
class SessionAllocator {
  const SessionAllocator();

  List<SessionAllocation> allocate({
    required List<StudyItem> realWords,
    required List<StudyItem> nonWords,
    required int seed,
  }) {
    _validatePool(
      realWords,
      expectedCount: StudyProtocol.realWordPoolCount,
      expectedType: StudyItemType.realWord,
      label: 'real-word',
    );
    _validatePool(
      nonWords,
      expectedCount: StudyProtocol.plannedNonWordPoolCount,
      expectedType: StudyItemType.nonWord,
      label: 'non-word',
    );
    _validateUniqueAcrossPools(realWords, nonWords);

    final shuffledWords = List<StudyItem>.of(realWords)
      ..shuffle(Random(seed ^ 0x51A7));
    final shuffledNonWords = List<StudyItem>.of(nonWords)
      ..shuffle(Random(seed ^ 0xA715));

    final allocations = <SessionAllocation>[];

    for (var session = 1; session <= StudyProtocol.sessionCount; session += 1) {
      final wordStart = (session - 1) * StudyProtocol.realWordsPerSession;
      final nonWordStart = (session - 1) * StudyProtocol.nonWordsPerSession;

      final sessionWords = shuffledWords
          .skip(wordStart)
          .take(StudyProtocol.realWordsPerSession)
          .toList(growable: false);
      final sessionNonWords = shuffledNonWords
          .skip(nonWordStart)
          .take(StudyProtocol.nonWordsPerSession)
          .toList(growable: false);

      final ordered = <StudyItem>[
        ...sessionWords,
        ...sessionNonWords,
      ]..shuffle(Random(seed + session * 7919));

      allocations.add(
        SessionAllocation(
          sessionNumber: session,
          realWords: sessionWords,
          nonWords: sessionNonWords,
          orderedItems: ordered,
        ),
      );
    }

    return List<SessionAllocation>.unmodifiable(allocations);
  }

  void _validatePool(
    List<StudyItem> items, {
    required int expectedCount,
    required StudyItemType expectedType,
    required String label,
  }) {
    if (items.length != expectedCount) {
      throw ArgumentError(
        'Expected $expectedCount $label items, received ${items.length}.',
      );
    }

    final ids = <String>{};
    final texts = <String>{};
    for (final item in items) {
      item.validate();
      if (item.type != expectedType) {
        throw ArgumentError(
          'Item ${item.id} is not of type ${expectedType.storageValue}.',
        );
      }
      if (!ids.add(item.id)) {
        throw ArgumentError('Duplicate item ID: ${item.id}.');
      }
      if (!texts.add(item.text)) {
        throw ArgumentError('Duplicate item text in $label pool.');
      }
    }
  }

  void _validateUniqueAcrossPools(
    List<StudyItem> realWords,
    List<StudyItem> nonWords,
  ) {
    final wordIds = realWords.map((item) => item.id).toSet();
    final nonWordIds = nonWords.map((item) => item.id).toSet();
    final wordTexts = realWords.map((item) => item.text).toSet();
    final nonWordTexts = nonWords.map((item) => item.text).toSet();

    if (wordIds.intersection(nonWordIds).isNotEmpty) {
      throw ArgumentError('An item ID occurs in both stimulus pools.');
    }
    if (wordTexts.intersection(nonWordTexts).isNotEmpty) {
      throw ArgumentError('An item text occurs in both stimulus pools.');
    }
  }
}
