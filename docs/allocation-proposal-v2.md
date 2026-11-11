# PadLab allocation proposal v2

**Status:** engineering draft only — not approved for participant use.

## Confirmed engineering target

The latest user-confirmed ratio is six sessions, each containing 45 real words and 32 non-words.

- 6 × 45 = 270 real words.
- 6 × 32 = 192 non-words.
- 45 + 32 = 77 scored items per session.
- 6 × 77 = 462 scored items overall.
- The supplied non-word CSV contains 193 candidates. Source row 193 (N270) is retained as an unallocated reserve.

The 77-item scored target does not include practice items. The practice count and policy remain unspecified and must not be inferred from the earlier 5-practice/85-test requirements draft.

## Data provenance and status

- The real-word CSV contains 270 unique entries.
- The supplied non-word CSV contains 193 unique entries, with no exact text overlap against the 270 real-word strings.
- The companion non-word workbook contains 270 candidates, all marked Pending.
- The 193-row CSV does not carry reviewer approval. All candidates remain pending native Kannada review.
- The engineering allocation uses the first 192 CSV rows in source order and retains row 193 (N270) as reserve. This is a deterministic engineering partition, not a randomized study sequence.

## Safety gate

Do not create participant sessions, collect scored responses, or export participant data from this proposal until the PI/statistician approves the allocation, a native Kannada reviewer approves the selected items, practice policy and trial order are signed off, and the approved item-bank checksum is recorded.

## Cross-platform release invariant

Web and Android must ship the same source commit, catalogue assets, protocol proposal version, and SHA-256 values. Platform-specific storage adapters may differ; assessment and allocation logic must not.
