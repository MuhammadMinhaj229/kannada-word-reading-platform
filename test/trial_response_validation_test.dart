import 'package:flutter_test/flutter_test.dart';
import 'package:padalab_android/features/assessment/domain/services/trial_response_validation.dart';

void main() {
  group('TrialResponseValidation', () {
    final shownAt = DateTime.utc(2026, 11, 11, 10);

    test('accepts a valid answered trial', () {
      expect(
        () => TrialResponseValidation.validate(
          response: 'word',
          reactionTimeMs: 812,
          shownAt: shownAt,
          answeredAt: shownAt.add(const Duration(milliseconds: 812)),
        ),
        returnsNormally,
      );
    });

    test('accepts a no-response trial only with null timing fields', () {
      expect(
        () => TrialResponseValidation.validate(
          response: 'none',
          reactionTimeMs: null,
          shownAt: shownAt,
          answeredAt: null,
        ),
        returnsNormally,
      );
    });

    test('rejects an answer timestamp before presentation', () {
      expect(
        () => TrialResponseValidation.validate(
          response: 'nonword',
          reactionTimeMs: 10,
          shownAt: shownAt,
          answeredAt: shownAt.subtract(const Duration(milliseconds: 1)),
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative reaction time', () {
      expect(
        () => TrialResponseValidation.validate(
          response: 'word',
          reactionTimeMs: -1,
          shownAt: shownAt,
          answeredAt: shownAt.add(const Duration(milliseconds: 1)),
        ),
        throwsArgumentError,
      );
    });

    test('rejects timing metadata for no-response trials', () {
      expect(
        () => TrialResponseValidation.validate(
          response: 'none',
          reactionTimeMs: 1,
          shownAt: shownAt,
          answeredAt: shownAt.add(const Duration(milliseconds: 1)),
        ),
        throwsArgumentError,
      );
    });

    test('rejects missing timing metadata for answered trials', () {
      expect(
        () => TrialResponseValidation.validate(
          response: 'word',
          reactionTimeMs: null,
          shownAt: shownAt,
          answeredAt: null,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid response values', () {
      expect(
        () => TrialResponseValidation.validate(
          response: 'maybe',
          reactionTimeMs: null,
          shownAt: shownAt,
          answeredAt: null,
        ),
        throwsArgumentError,
      );
    });
  });
}
