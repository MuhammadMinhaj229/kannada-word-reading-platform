import 'study_item.dart';

class SessionAllocation {
  SessionAllocation({
    required this.sessionNumber,
    required List<StudyItem> realWords,
    required List<StudyItem> nonWords,
    required List<StudyItem> orderedItems,
  })  : realWords = List<StudyItem>.unmodifiable(realWords),
        nonWords = List<StudyItem>.unmodifiable(nonWords),
        orderedItems = List<StudyItem>.unmodifiable(orderedItems);

  final int sessionNumber;
  final List<StudyItem> realWords;
  final List<StudyItem> nonWords;
  final List<StudyItem> orderedItems;

  int get scoredItemCount => orderedItems.length;
}
