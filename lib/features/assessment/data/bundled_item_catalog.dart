import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class KannadaSourceWord {
  const KannadaSourceWord({
    required this.id,
    required this.text,
    required this.transcription,
    required this.meaning,
    required this.partOfSpeech,
    required this.ageBand,
    required this.aksharaType,
    this.meanAgeOfAcquisition,
    this.syllables,
    this.phonemes,
    this.morphemes,
  });

  final String id;
  final String text;
  final String transcription;
  final String meaning;
  final String partOfSpeech;
  final String ageBand;
  final String aksharaType;
  final double? meanAgeOfAcquisition;
  final int? syllables;
  final int? phonemes;
  final int? morphemes;
}

class BundledItemCatalog {
  const BundledItemCatalog({
    required this.realWords,
    required this.nonWordCandidateCount,
    required this.approvedNonWordCount,
    required this.nonWordReviewStatus,
    required this.nonWordMethodCounts,
  });

  static const String realWordsAsset =
      'assets/item_bank/selected_words_list_v1.csv';
  static const String nonWordSummaryAsset =
      'assets/item_bank/nonword_candidate_summary_v1.json';

  final List<KannadaSourceWord> realWords;
  final int nonWordCandidateCount;
  final int approvedNonWordCount;
  final String nonWordReviewStatus;
  final Map<String, int> nonWordMethodCounts;

  bool get hasCompleteRealWordPool => realWords.length == 270;
  bool get hasApprovedNonWordPool =>
      nonWordCandidateCount == 270 && approvedNonWordCount == 270;
  bool get canBuildApprovedBank =>
      hasCompleteRealWordPool && hasApprovedNonWordPool;

  Map<String, int> distributionBy(String Function(KannadaSourceWord) keyOf) {
    final result = <String, int>{};
    for (final item in realWords) {
      final key = keyOf(item);
      result.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map<String, int>.unmodifiable(result);
  }

  static Future<BundledItemCatalog> load({
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final csvText = await assets.loadString(realWordsAsset);
    final summaryText = await assets.loadString(nonWordSummaryAsset);
    return parse(csvText: csvText, nonWordSummaryJson: summaryText);
  }

  static BundledItemCatalog parse({
    required String csvText,
    required String nonWordSummaryJson,
  }) {
    final rows = csv.decode(csvText);
    if (rows.length < 2) {
      throw const FormatException('The supplied Kannada source-word file is empty.');
    }

    final headers = rows.first
        .map((value) => value.toString().trim().toLowerCase())
        .toList(growable: false);
    final indexes = <String, int>{
      for (var i = 0; i < headers.length; i += 1) headers[i]: i,
    };
    const required = <String>[
      'word',
      'transcription',
      'meaning',
      'pos',
      'age band',
      'akshara type',
    ];
    final missing = required.where((name) => !indexes.containsKey(name)).toList();
    if (missing.isNotEmpty) {
      throw FormatException(
        'The supplied source-word file is missing columns: ' + missing.join(', ') + '.',
      );
    }

    String value(List<dynamic> row, String column) {
      final index = indexes[column]!;
      if (index >= row.length) return '';
      return row[index]?.toString().trim() ?? '';
    }

    int? integerValue(String raw) => int.tryParse(raw);
    double? doubleValue(String raw) => double.tryParse(raw);

    final words = <KannadaSourceWord>[];
    final uniqueWords = <String>{};
    for (final row in rows.skip(1)) {
      if (row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
        continue;
      }

      final text = value(row, 'word');
      if (text.isEmpty) {
        throw const FormatException('A source-word row has an empty Kannada word.');
      }
      if (!uniqueWords.add(text)) {
        throw FormatException('Duplicate Kannada source word: ' + text);
      }

      final ordinal = words.length + 1;
      words.add(KannadaSourceWord(
        id: 'W' + ordinal.toString().padLeft(3, '0'),
        text: text,
        transcription: value(row, 'transcription'),
        meaning: value(row, 'meaning'),
        partOfSpeech: value(row, 'pos'),
        ageBand: value(row, 'age band'),
        aksharaType: value(row, 'akshara type'),
        meanAgeOfAcquisition: doubleValue(value(row, 'mean_aoa')),
        syllables: integerValue(value(row, 'syllables')),
        phonemes: integerValue(value(row, 'phonemes')),
        morphemes: integerValue(value(row, 'morphemes')),
      ));
    }

    if (words.length != 270) {
      throw FormatException(
        'Expected 270 supplied real Kannada words; found ' + words.length.toString() + '.',
      );
    }

    final decoded = jsonDecode(nonWordSummaryJson);
    if (decoded is! Map) {
      throw const FormatException('The non-word review summary is invalid.');
    }
    final summary = Map<String, Object?>.from(decoded);
    final rawCounts = summary['construction_methods'];
    if (rawCounts is! Map) {
      throw const FormatException('The non-word construction counts are missing.');
    }
    final counts = <String, int>{};
    for (final entry in rawCounts.entries) {
      final count = entry.value;
      if (count is! int || count < 0) {
        throw const FormatException('A non-word construction count is invalid.');
      }
      counts[entry.key.toString()] = count;
    }

    const expectedCounts = <String, int>{
      'A_vowel': 68,
      'B_consonant': 68,
      'C_suffix_prefix': 67,
      'D_prefix_suffix': 67,
    };
    for (final entry in expectedCounts.entries) {
      if (counts[entry.key] != entry.value) {
        throw FormatException(
          'Unexpected ' + entry.key + ' count. Expected ' +
          entry.value.toString() + ', received ' +
          (counts[entry.key]?.toString() ?? 'null') + '.',
        );
      }
    }

    final candidateCount = summary['candidate_count'];
    final approvedCount = summary['approved_count'];
    if (candidateCount is! int || approvedCount is! int ||
        candidateCount != 270 || approvedCount < 0 || approvedCount > 270) {
      throw const FormatException('The non-word approval counts are invalid.');
    }

    return BundledItemCatalog(
      realWords: List<KannadaSourceWord>.unmodifiable(words),
      nonWordCandidateCount: candidateCount,
      approvedNonWordCount: approvedCount,
      nonWordReviewStatus: summary['review_status']?.toString() ?? 'unknown',
      nonWordMethodCounts: Map<String, int>.unmodifiable(counts),
    );
  }
}
