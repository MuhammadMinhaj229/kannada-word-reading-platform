import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ItemBankImportMetadata {
  const ItemBankImportMetadata({
    required this.fileName,
    required this.version,
    required this.sha256,
    required this.importedAt,
    required this.itemCount,
    required this.wordCount,
    required this.nonWordCount,
  });

  final String fileName;
  final String version;
  final String sha256;
  final String importedAt;
  final int itemCount;
  final int wordCount;
  final int nonWordCount;

  Map<String, Object?> toJson() => <String, Object?>{
        'file_name': fileName,
        'version': version,
        'sha256': sha256,
        'imported_at': importedAt,
        'item_count': itemCount,
        'word_count': wordCount,
        'non_word_count': nonWordCount,
      };

  factory ItemBankImportMetadata.fromJson(Map<String, Object?> json) =>
      ItemBankImportMetadata(
        fileName: json['file_name'] as String? ?? '',
        version: json['version'] as String? ?? '',
        sha256: json['sha256'] as String? ?? '',
        importedAt: json['imported_at'] as String? ?? '',
        itemCount: json['item_count'] as int? ?? 0,
        wordCount: json['word_count'] as int? ?? 0,
        nonWordCount: json['non_word_count'] as int? ?? 0,
      );
}

/// Saves summary metadata only. The workbook and item text are not copied to
/// preferences; the eventual field implementation must import into the
/// encrypted Android database or a separately reviewed Web database adapter.
class ItemBankImportMetadataStore {
  static const _key = 'padalab.item-bank-import-metadata.v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<ItemBankImportMetadata?> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ItemBankImportMetadata.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(ItemBankImportMetadata metadata) =>
      _preferences.setString(_key, jsonEncode(metadata.toJson()));

  Future<void> clear() => _preferences.remove(_key);
}
