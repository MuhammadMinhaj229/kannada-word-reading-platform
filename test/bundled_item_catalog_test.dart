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
