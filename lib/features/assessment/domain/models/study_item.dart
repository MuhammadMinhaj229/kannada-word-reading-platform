enum StudyItemType {
  realWord,
  nonWord;

  String get storageValue {
    switch (this) {
      case StudyItemType.realWord:
        return 'word';
      case StudyItemType.nonWord:
        return 'nonword';
    }
  }
}

class StudyItem {
  const StudyItem({
    required this.id,
    required this.text,
    required this.type,
    this.nonWordMethod,
  });

  final String id;
  final String text;
  final StudyItemType type;
  final String? nonWordMethod;

  void validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Item ID cannot be empty.');
    }
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'Item text cannot be empty.');
    }
    if (type == StudyItemType.nonWord &&
        (nonWordMethod == null || nonWordMethod!.trim().isEmpty)) {
      throw ArgumentError.value(
        nonWordMethod,
        'nonWordMethod',
        'Non-word items must retain their generation method.',
      );
    }
    if (type == StudyItemType.realWord && nonWordMethod != null) {
      throw ArgumentError.value(
        nonWordMethod,
        'nonWordMethod',
        'Real-word items cannot have a non-word generation method.',
      );
    }
  }
}
