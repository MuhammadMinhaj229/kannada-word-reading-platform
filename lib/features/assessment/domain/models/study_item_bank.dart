import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import 'study_item.dart';

/// Immutable, versioned set of the exact stimuli approved by the study team.
///
/// The canonical checksum is calculated from the version and sorted item
/// content, not copied from a caller-supplied value. The application must
/// reject an item bank if the count, item metadata or SHA-256 does not match.
class StudyItemBank {
  StudyItemBank({
    required this.version,
    required this.approvedBy,
    required this.approvalReference,
    required this.kannadaReviewReference,
    required List<StudyItem> items,
  }) : items = List<StudyItem>.unmodifiable(items);

  static const int schemaVersion = 1;
  static const int requiredRealWordCount = 270;
  static const int requiredNonWordCount = 270;

  final String version;
  final String approvedBy;
  final String approvalReference;
  final String kannadaReviewReference;
  final List<StudyItem> items;

  int get realWordCount =>
      items.where((item) => item.type == StudyItemType.realWord).length;

  int get nonWordCount =>
      items.where((item) => item.type == StudyItemType.nonWord).length;

  String get sha256 => sha256OfCanonicalContent();

  String sha256OfCanonicalContent() {
    final sortedItems = List<StudyItem>.of(items)
      ..sort((a, b) => a.id.compareTo(b.id));
    final canonical = <String, Object?>{
      'schema_version': schemaVersion,
      'version': version,
      'items': sortedItems
          .map(
            (item) => <String, Object?>{
              'id': item.id,
              'text': item.text,
              'type': item.type.storageValue,
              'non_word_method': item.nonWordMethod,
            },
          )
          .toList(growable: false),
    };
    final bytes = utf8.encode(jsonEncode(canonical));
    return crypto.sha256.convert(bytes).toString();
  }

  void validate() {
    if (version.trim().isEmpty) {
      throw ArgumentError('Item-bank version is required.');
    }
    if (approvedBy.trim().isEmpty ||
        approvalReference.trim().isEmpty ||
        kannadaReviewReference.trim().isEmpty) {
      throw ArgumentError(
        'Item-bank approval and native Kannada review references are required.',
      );
    }
    if (items.length != requiredRealWordCount + requiredNonWordCount) {
      throw ArgumentError(
        'Expected ${requiredRealWordCount + requiredNonWordCount} approved '
        'items; received ${items.length}.',
      );
    }
    if (realWordCount != requiredRealWordCount ||
        nonWordCount != requiredNonWordCount) {
      throw ArgumentError(
        'Item bank must contain exactly $requiredRealWordCount real words '
        'and $requiredNonWordCount non-words.',
      );
    }

    final ids = <String>{};
    final texts = <String>{};
    for (final item in items) {
      item.validate();
      if (!ids.add(item.id) || !texts.add(item.text)) {
        throw ArgumentError('Item IDs and stimulus text must be unique.');
      }
    }
  }

  void validateChecksum(String expectedSha256) {
    validate();
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(expectedSha256) ||
        sha256 != expectedSha256.toLowerCase()) {
      throw StateError(
        'The approved item-bank SHA-256 does not match its contents.',
      );
    }
  }

  void validateTrialItem(StudyItem trialItem) {
    final matches = items.where((item) => item.id == trialItem.id);
    if (matches.length != 1) {
      throw StateError(
        'Item ${trialItem.id} is not present exactly once in the approved bank.',
      );
    }
    final approved = matches.single;
    if (approved.text != trialItem.text ||
        approved.type != trialItem.type ||
        approved.nonWordMethod != trialItem.nonWordMethod) {
      throw StateError(
        'Trial item ${trialItem.id} differs from the approved item-bank entry.',
      );
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schema_version': schemaVersion,
        'version': version,
        'approved_by': approvedBy,
        'approval_reference': approvalReference,
        'kannada_review_reference': kannadaReviewReference,
        'sha256': sha256,
        'items': items
            .map(
              (item) => <String, Object?>{
                'id': item.id,
                'text': item.text,
                'type': item.type.storageValue,
                'non_word_method': item.nonWordMethod,
              },
            )
            .toList(growable: false),
      };

  factory StudyItemBank.fromJson(Map<String, Object?> json) {
    if (json['schema_version'] != schemaVersion) {
      throw const FormatException('Unsupported item-bank schema version.');
    }
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Item-bank items must be a list.');
    }

    final items = rawItems.map((value) {
      if (value is! Map) {
        throw const FormatException('Each item-bank row must be an object.');
      }
      final row = Map<String, Object?>.from(value);
      final type = row['type'];
      if (type != 'word' && type != 'nonword') {
        throw const FormatException('Unknown item type in item bank.');
      }
      return StudyItem(
        id: row['id'] as String? ?? '',
        text: row['text'] as String? ?? '',
        type: type == 'word' ? StudyItemType.realWord : StudyItemType.nonWord,
        nonWordMethod: row['non_word_method'] as String?,
      );
    }).toList(growable: false);

    final bank = StudyItemBank(
      version: json['version'] as String? ?? '',
      approvedBy: json['approved_by'] as String? ?? '',
      approvalReference: json['approval_reference'] as String? ?? '',
      kannadaReviewReference: json['kannada_review_reference'] as String? ?? '',
      items: items,
    );
    final providedHash = json['sha256'];
    if (providedHash is! String) {
      throw const FormatException('Item-bank SHA-256 is required.');
    }
    bank.validateChecksum(providedHash);
    return bank;
  }
}
