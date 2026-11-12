import 'dart:convert';
import 'dart:typed_data';

import '../domain/models/item_bank_draft.dart';

/// Portable backup format for non-approved assessor content drafts.
///
/// A backup is a transfer mechanism between the Web and Android local stores;
/// it is not an approved item bank and must never unlock participant sessions.
abstract final class ItemBankDraftBackup {
  static const int schemaVersion = 1;
  static const int maxBytes = 5 * 1024 * 1024;
  static const int maxItems = 500;
  static const String applicationName = 'PadLab content drafts';

  static Uint8List encode(
    Iterable<ItemBankDraft> drafts, {
    DateTime? exportedAt,
  }) {
    final items = drafts.toList(growable: false);
    if (items.length > maxItems) {
      throw ArgumentError('A draft backup cannot contain more than $maxItems items.');
    }

    final ids = <String>{};
    for (final draft in items) {
      draft.validate();
      if (!ids.add(draft.id)) {
        throw ArgumentError('Duplicate draft ID in backup: ${draft.id}.');
      }
    }

    final payload = <String, Object?>{
      'schema_version': schemaVersion,
      'application': applicationName,
      'exported_at': (exportedAt ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
      'approved_for_gameplay': false,
      'items': items.map((draft) => draft.toJson()).toList(growable: false),
    };
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (bytes.lengthInBytes > maxBytes) {
      throw ArgumentError('Draft backup exceeds the 5 MB safety limit.');
    }
    return bytes;
  }

  static List<ItemBankDraft> decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('The selected draft backup is empty.');
    }
    if (bytes.lengthInBytes > maxBytes) {
      throw const FormatException('Draft backup exceeds the 5 MB safety limit.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Draft backup is not valid UTF-8 JSON: $error');
    }

    if (decoded is! Map ||
        decoded['schema_version'] != schemaVersion ||
        decoded['application'] != applicationName ||
        decoded['approved_for_gameplay'] != false) {
      throw const FormatException(
        'This is not a supported PadLab non-approved content-draft backup.',
      );
    }
    final rawItems = decoded['items'];
    if (rawItems is! List) {
      throw const FormatException('Draft backup is missing its items list.');
    }
    if (rawItems.length > maxItems) {
      throw FormatException('Draft backup exceeds the $maxItems-item limit.');
    }

    final ids = <String>{};
    final drafts = <ItemBankDraft>[];
    for (final raw in rawItems) {
      if (raw is! Map) {
        throw const FormatException('A draft backup item is not an object.');
      }
      final draft = ItemBankDraft.fromJson(
        Map<String, Object?>.from(raw),
      );
      draft.validate();
      if (!ids.add(draft.id)) {
        throw FormatException('Duplicate draft ID in backup: ${draft.id}.');
      }
      drafts.add(draft);
    }
    return List<ItemBankDraft>.unmodifiable(drafts);
  }
}
