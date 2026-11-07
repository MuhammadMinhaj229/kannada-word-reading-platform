import 'package:padalab_android/features/assessment/domain/models/study_item.dart';
import 'package:padalab_android/features/assessment/domain/models/study_item_bank.dart';

StudyItemBank createValidTestItemBank({
  int realWordCount = 270,
  int nonWordCount = 270,
  String version = 'test-bank-v1',
}) {
  final items = <StudyItem>[
    for (var index = 1; index <= realWordCount; index += 1)
      StudyItem(
        id: 'R${index.toString().padLeft(3, '0')}',
        text: 'fixture-real-word-$index',
        type: StudyItemType.realWord,
      ),
    for (var index = 1; index <= nonWordCount; index += 1)
      StudyItem(
        id: 'N${index.toString().padLeft(3, '0')}',
        text: 'fixture-non-word-$index',
        type: StudyItemType.nonWord,
        nonWordMethod: 'test_fixture_only',
      ),
  ];

  return StudyItemBank(
    version: version,
    approvedBy: 'TEST-FIXTURE-ONLY',
    approvalReference: 'TEST-APPROVAL-NOT-FOR-USE',
    kannadaReviewReference: 'TEST-LINGUISTIC-REVIEW-NOT-FOR-USE',
    items: items,
  );
}
