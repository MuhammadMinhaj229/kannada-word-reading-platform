import 'dart:convert';

enum ItemBankDraftType { realWord, nonWord }

/// Local, non-approved content edit. Drafts never become playable stimuli.
class ItemBankDraft {
  ItemBankDraft({
    required this.id,
    required this.type,
    required this.text,
    required Map<String, String> metadata,
    this.revision = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : metadata = Map<String, String>.unmodifiable(metadata),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final ItemBankDraftType type;
  final String text;
  final Map<String, String> metadata;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get typeValue => type == ItemBankDraftType.realWord ? 'word' : 'nonword';

  void validate() {
    if (id.trim().isEmpty || text.trim().isEmpty) {
      throw ArgumentError('Draft item ID and Kannada text are required.');
    }
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision');
    }
    if (type == ItemBankDraftType.nonWord) {
      for (final key in const ['method', 'source_word_1', 'source_id_1', 'transformation']) {
        if ((metadata[key] ?? '').trim().isEmpty) {
          throw ArgumentError('Non-word draft requires $key.');
        }
      }
      final method = metadata['method'];
      if (!const <String>{
        'A_vowel',
        'B_consonant',
        'C_suffix_prefix',
        'D_prefix_suffix',
      }.contains(method)) {
        throw ArgumentError('Non-word draft has an unknown construction method.');
      }
      if (method == 'C_suffix_prefix' || method == 'D_prefix_suffix') {
        if ((metadata['source_word_2'] ?? '').trim().isEmpty ||
            (metadata['source_id_2'] ?? '').trim().isEmpty) {
          throw ArgumentError('This non-word method requires a second source word.');
        }
      }
    }
    for (final entry in metadata.entries) {
      if (entry.key.trim().isEmpty || entry.key.length > 80 ||
          entry.value.length > 4000) {
        throw ArgumentError('Draft metadata contains an invalid field.');
      }
    }
  }

  ItemBankDraft copyWith({
    String? text,
    Map<String, String>? metadata,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ItemBankDraft(
    id: id,
    type: type,
    text: text ?? this.text,
    metadata: metadata ?? this.metadata,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': 1,
    'id': id,
    'type': typeValue,
    'text': text,
    'metadata': metadata,
    'revision': revision,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());

  factory ItemBankDraft.fromJson(Map<String, Object?> json) {
    if (json['schema_version'] != 1) {
      throw const FormatException('Unsupported content-draft schema.');
    }
    final rawType = json['type'];
    if (rawType != 'word' && rawType != 'nonword') {
      throw const FormatException('Unknown content-draft item type.');
    }
    final rawMetadata = json['metadata'];
    if (rawMetadata is! Map) {
      throw const FormatException('Content-draft metadata must be an object.');
    }
    final metadata = <String, String>{};
    for (final entry in rawMetadata.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('Content-draft metadata values must be text.');
      }
      metadata[entry.key as String] = entry.value as String;
    }
    final item = ItemBankDraft(
      id: json['id'] as String? ?? '',
      type: rawType == 'word'
          ? ItemBankDraftType.realWord
          : ItemBankDraftType.nonWord,
      text: json['text'] as String? ?? '',
      metadata: metadata,
      revision: json['revision'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    item.validate();
    return item;
  }
}
