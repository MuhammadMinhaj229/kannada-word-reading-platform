import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/data/bundled_item_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('loads the complete supplied 270-word Kannada source list', () async {
    final catalog = await BundledItemCatalog.load();

    expect(catalog.realWords, hasLength(270));
    expect(catalog.realWords.map((item) => item.text).toSet(), hasLength(270));
    expect(catalog.realWords.first.id, 'W001');
    expect(catalog.realWords.last.id, 'W270');
    expect(catalog.hasCompleteRealWordPool, isTrue);
  });

  test('retains the supplied non-word construction proportions and pending state',
      () async {
    final catalog = await BundledItemCatalog.load();

    expect(catalog.nonWordCandidateCount, 270);
    expect(catalog.approvedNonWordCount, 0);
    expect(catalog.hasApprovedNonWordPool, isFalse);
    expect(catalog.nonWordMethodCounts, <String, int>{
      'A_vowel': 68,
      'B_consonant': 68,
      'C_suffix_prefix': 67,
      'D_prefix_suffix': 67,
    });
  });



  test('loads all 193 supplied candidates and keeps them pending', () async {
    final catalog = await BundledItemCatalog.load();

    expect(catalog.suppliedNonWordCandidates, hasLength(193));
    expect(catalog.suppliedNonWordCount, 193);
    expect(catalog.pendingSuppliedNonWordCount, 193);
    expect(
      catalog.suppliedNonWordCandidates.map((item) => item.id).toSet(),
      hasLength(193),
    );
    expect(catalog.suppliedNonWordCandidates.last.sourceRow, 193);
    expect(catalog.suppliedNonWordCandidates.last.id, 'N270');
    expect(catalog.suppliedNonWordCandidates.last.isApproved, isFalse);
  });

  test('validates non-word source references and keeps them distinct from real words',
      () async {
    final catalog = await BundledItemCatalog.load();
    final realWords = catalog.realWords.map((item) => item.text).toSet();

    expect(
      catalog.suppliedNonWordCandidates
          .where((item) => realWords.contains(item.text)),
      isEmpty,
    );
    expect(
      catalog.suppliedNonWordCandidates
          .where((item) => item.method == 'C_suffix_prefix' ||
              item.method == 'D_prefix_suffix')
          .every((item) => item.sourceWord2 != null && item.sourceId2 != null),
      isTrue,
    );
  });

  test('rejects duplicate source-word column names', () async {
    final source = await rootBundle.loadString(BundledItemCatalog.realWordsAsset);
    final summary = await rootBundle.loadString(BundledItemCatalog.nonWordSummaryAsset);
    final candidates = await rootBundle.loadString(BundledItemCatalog.suppliedNonWordCandidatesAsset);
    final duplicateHeader = source.replaceFirst('"transcription"', '"word"');

    expect(
      () => BundledItemCatalog.parse(
        csvText: duplicateHeader,
        nonWordSummaryJson: summary,
        nonWordCandidatesCsv: candidates,
      ),
      throwsFormatException,
    );
  });

  test('rejects missing required metadata in an otherwise valid row', () async {
    final source = await rootBundle.loadString(BundledItemCatalog.realWordsAsset);
    final summary = await rootBundle.loadString(BundledItemCatalog.nonWordSummaryAsset);
    final candidates = await rootBundle.loadString(BundledItemCatalog.suppliedNonWordCandidatesAsset);
    final missingTranscription = source.replaceFirst(
      '"ಹೂ","huu","flower","noun"',
      '"ಹೂ","","flower","noun"',
    );

    expect(
      () => BundledItemCatalog.parse(
        csvText: missingTranscription,
        nonWordSummaryJson: summary,
        nonWordCandidatesCsv: candidates,
      ),
      throwsFormatException,
    );
  });

  test('rejects malformed numeric source metadata instead of dropping it', () async {
    final source = await rootBundle.loadString(BundledItemCatalog.realWordsAsset);
    final summary = await rootBundle.loadString(BundledItemCatalog.nonWordSummaryAsset);
    final candidates = await rootBundle.loadString(BundledItemCatalog.suppliedNonWordCandidatesAsset);
    final malformedAoA = source.replaceFirst(',2.12,1,2,1', ',not-a-number,1,2,1');

    expect(
      () => BundledItemCatalog.parse(
        csvText: malformedAoA,
        nonWordSummaryJson: summary,
        nonWordCandidatesCsv: candidates,
      ),
      throwsFormatException,
    );
  });

  test('retains the source word metadata distributions', () async {
    final catalog = await BundledItemCatalog.load();

    expect(catalog.distributionBy((item) => item.partOfSpeech), <String, int>{
      'noun': 96,
      'verb': 97,
      'adverb': 34,
      'adjective': 43,
    });
    expect(catalog.distributionBy((item) => item.ageBand), <String, int>{
      '2-3 years': 66,
      '0-1 year': 7,
      '4-5 years': 77,
      '6-7 years': 83,
      '8-9 years': 37,
    });
  });
}
