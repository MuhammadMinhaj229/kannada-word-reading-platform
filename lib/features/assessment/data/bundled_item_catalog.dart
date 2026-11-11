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


class KannadaNonWordCandidate {
  const KannadaNonWordCandidate({
    required this.sourceRow,
    required this.id,
    required this.text,
    required this.method,
    required this.sourceWord1,
    required this.sourceId1,
    required this.transformation,
    required this.reviewStatus,
    this.sourceWord2,
    this.sourceId2,
    this.reviewerNotes = '',
  });

  final int sourceRow;
  final String id;
  final String text;
  final String method;
  final String sourceWord1;
  final String sourceId1;
  final String? sourceWord2;
  final String? sourceId2;
  final String transformation;
  final String reviewStatus;
  final String reviewerNotes;

  bool get isApproved => reviewStatus == 'approved';
}

class BundledItemCatalog {
  const BundledItemCatalog({
    required this.realWords,
    required this.nonWordCandidateCount,
    required this.approvedNonWordCount,
    required this.nonWordReviewStatus,
    required this.nonWordMethodCounts,
    required this.suppliedNonWordCandidates,
  });

  static const String realWordsAsset =
      'assets/item_bank/selected_words_list_v1.csv';
  static const String nonWordSummaryAsset =
      'assets/item_bank/nonword_candidate_summary_v1.json';
  static const String suppliedNonWordCandidatesAsset =
      'assets/item_bank/nonword_candidates_supplied_v1.csv';

  final List<KannadaSourceWord> realWords;
  final int nonWordCandidateCount;
  final int approvedNonWordCount;
  final String nonWordReviewStatus;
  final Map<String, int> nonWordMethodCounts;
  final List<KannadaNonWordCandidate> suppliedNonWordCandidates;

  bool get hasCompleteRealWordPool => realWords.length == 270;
  bool get hasApprovedNonWordPool =>
      nonWordCandidateCount == 270 && approvedNonWordCount == 270;
  int get suppliedNonWordCount => suppliedNonWordCandidates.length;
  int get pendingSuppliedNonWordCount =>
      suppliedNonWordCandidates.where((item) => !item.isApproved).length;
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
    final candidatesText =
        await assets.loadString(suppliedNonWordCandidatesAsset);
    return parse(
      csvText: csvText,
      nonWordSummaryJson: summaryText,
      nonWordCandidatesCsv: candidatesText,
    );
  }

  static BundledItemCatalog parse({
    required String csvText,
    required String nonWordSummaryJson,
    required String nonWordCandidatesCsv,
  }) {
    final rows = csv.decode(csvText);
    if (rows.length < 2) {
      throw const FormatException('The supplied Kannada source-word file is empty.');
    }

    final headers = rows.first
        .map((value) => value.toString().trim().toLowerCase())
        .toList(growable: false);
    final indexes = <String, int>{};
    for (var i = 0; i < headers.length; i += 1) {
      final header = headers[i];
      if (header.isEmpty) {
        throw const FormatException('The source-word file contains an empty column name.');
      }
      if (indexes.containsKey(header)) {
        throw FormatException('The source-word file contains a duplicate column: ' + header + '.');
      }
      indexes[header] = i;
    }
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
      final index = indexes[column];
      if (index == null || index >= row.length) return '';
      return row[index]?.toString().trim() ?? '';
    }

    int? integerValue(String raw) => int.tryParse(raw);
    double? doubleValue(String raw) => double.tryParse(raw);

    final words = <KannadaSourceWord>[];
    final uniqueWords = <String>{};
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex += 1) {
      final row = rows[rowIndex];
      if (row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
        continue;
      }

      final rowNumber = rowIndex + 1;
      for (final column in required) {
        if (value(row, column).isEmpty) {
          throw FormatException(
            'Source-word row ' + rowNumber.toString() +
            ' is missing required metadata: ' + column + '.',
          );
        }
      }

      final text = value(row, 'word');
      if (!uniqueWords.add(text)) {
        throw FormatException('Duplicate Kannada source word: ' + text);
      }

      final meanAoARaw = value(row, 'mean_aoa');
      final syllablesRaw = value(row, 'syllables');
      final phonemesRaw = value(row, 'phonemes');
      final morphemesRaw = value(row, 'morphemes');

      final meanAoA = meanAoARaw.isEmpty ? null : doubleValue(meanAoARaw);
      final syllables = syllablesRaw.isEmpty ? null : integerValue(syllablesRaw);
      final phonemes = phonemesRaw.isEmpty ? null : integerValue(phonemesRaw);
      final morphemes = morphemesRaw.isEmpty ? null : integerValue(morphemesRaw);

      if (meanAoARaw.isNotEmpty && (meanAoA == null || meanAoA < 0)) {
        throw FormatException('Invalid mean_AoA in source-word row ' + rowNumber.toString() + '.');
      }
      for (final entry in <String, int?>{
        'syllables': syllables,
        'phonemes': phonemes,
        'morphemes': morphemes,
      }.entries) {
        if (entry.value == null && value(row, entry.key).isNotEmpty ||
            entry.value != null && entry.value! < 1) {
          throw FormatException(
            'Invalid ' + entry.key + ' value in source-word row ' +
            rowNumber.toString() + '.',
          );
        }
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
        meanAgeOfAcquisition: meanAoA,
        syllables: syllables,
        phonemes: phonemes,
        morphemes: morphemes,
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


    final candidateRows = csv.decode(nonWordCandidatesCsv);
    if (candidateRows.length != 194) {
      throw FormatException(
        'Expected 193 supplied non-word candidates plus a header; found ' +
            (candidateRows.length - 1).toString() + '.',
      );
    }
    final candidateHeaders = candidateRows.first
        .map((value) => value.toString().trim().toLowerCase())
        .toList(growable: false);
    final candidateIndexes = <String, int>{};
    for (var i = 0; i < candidateHeaders.length; i += 1) {
      final header = candidateHeaders[i];
      if (header.isEmpty || candidateIndexes.containsKey(header)) {
        throw const FormatException(
          'The non-word candidate file has an empty or duplicate column name.',
        );
      }
      candidateIndexes[header] = i;
    }
    const candidateRequired = <String>[
      'source_row',
      'nonword_id',
      'nonword',
      'method',
      'source_word_1',
      'source_id_1',
      'transformation',
      'review_status',
    ];
    final missingCandidateColumns = candidateRequired
        .where((name) => !candidateIndexes.containsKey(name))
        .toList(growable: false);
    if (missingCandidateColumns.isNotEmpty) {
      throw FormatException(
        'The supplied non-word file is missing columns: ' +
            missingCandidateColumns.join(', ') + '.',
      );
    }

    String candidateValue(List<dynamic> row, String column) {
      final index = candidateIndexes[column];
      if (index == null || index >= row.length) return '';
      return row[index]?.toString().trim() ?? '';
    }

    final sourceById = <String, KannadaSourceWord>{
      for (final word in words) word.id: word,
    };
    final candidates = <KannadaNonWordCandidate>[];
    final candidateIds = <String>{};
    final candidateTexts = <String>{};
    final realWordTexts = words.map((word) => word.text).toSet();
    const validMethods = <String>{
      'A_vowel',
      'B_consonant',
      'C_suffix_prefix',
      'D_prefix_suffix',
    };
    for (var rowIndex = 1; rowIndex < candidateRows.length; rowIndex += 1) {
      final row = candidateRows[rowIndex];
      final sourceRowRaw = candidateValue(row, 'source_row');
      final sourceRow = int.tryParse(sourceRowRaw);
      final id = candidateValue(row, 'nonword_id');
      final text = candidateValue(row, 'nonword');
      final method = candidateValue(row, 'method');
      final sourceWord1 = candidateValue(row, 'source_word_1');
      final sourceId1 = candidateValue(row, 'source_id_1');
      final sourceWord2 = candidateValue(row, 'source_word_2');
      final sourceId2 = candidateValue(row, 'source_id_2');
      final transformation = candidateValue(row, 'transformation');
      final reviewStatus = candidateValue(row, 'review_status');
      if (sourceRow == null || sourceRow != rowIndex ||
          id.isEmpty || text.isEmpty || sourceWord1.isEmpty ||
          sourceId1.isEmpty || transformation.isEmpty ||
          !validMethods.contains(method) || reviewStatus.isEmpty) {
        throw FormatException(
          'Invalid non-word candidate metadata on source row ' +
              (rowIndex + 1).toString() + '.',
        );
      }
      if (!candidateIds.add(id) || !candidateTexts.add(text)) {
        throw FormatException('Duplicate non-word candidate ID or text: ' + id);
      }
      if (realWordTexts.contains(text)) {
        throw FormatException(
          'Non-word candidate overlaps the real-word list: ' + id,
        );
      }
      final firstSource = sourceById[sourceId1];
      if (firstSource == null || firstSource.text != sourceWord1) {
        throw FormatException(
          'Non-word candidate ' + id + ' has an invalid first source reference.',
        );
      }
      if (method == 'C_suffix_prefix' || method == 'D_prefix_suffix') {
        final secondSource = sourceById[sourceId2];
        if (sourceWord2.isEmpty || secondSource == null ||
            secondSource.text != sourceWord2) {
          throw FormatException(
            'Non-word candidate ' + id + ' has an invalid second source reference.',
          );
        }
      } else if (sourceWord2.isNotEmpty || sourceId2.isNotEmpty) {
        throw FormatException(
          'Single-source candidate ' + id + ' must not include a second source.',
        );
      }
      candidates.add(KannadaNonWordCandidate(
        sourceRow: sourceRow,
        id: id,
        text: text,
        method: method,
        sourceWord1: sourceWord1,
        sourceId1: sourceId1,
        sourceWord2: sourceWord2.isEmpty ? null : sourceWord2,
        sourceId2: sourceId2.isEmpty ? null : sourceId2,
        transformation: transformation,
        reviewStatus: reviewStatus,
        reviewerNotes: candidateValue(row, 'reviewer_notes'),
      ));
    }
    if (candidates.length != 193 ||
        candidates.where((item) => item.isApproved).isNotEmpty) {
      throw const FormatException(
        'The supplied non-word set must contain 193 pending candidates only.',
      );
    }

    return BundledItemCatalog(
      realWords: List<KannadaSourceWord>.unmodifiable(words),
      nonWordCandidateCount: candidateCount,
      approvedNonWordCount: approvedCount,
      nonWordReviewStatus: summary['review_status']?.toString() ?? 'unknown',
      nonWordMethodCounts: Map<String, int>.unmodifiable(counts),
      suppliedNonWordCandidates:
          List<KannadaNonWordCandidate>.unmodifiable(candidates),
    );
  }
}
