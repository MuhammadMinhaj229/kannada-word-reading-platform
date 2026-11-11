# Working allocation proposal v2 — not approved

**Status:** user-confirmed engineering target; not a signed PI/statistician protocol. Do not administer this sequence.

## Counts represented by the latest engineering target

- Six sessions.
- 45 real words and 32 non-words per session.
- 77 scored items per session.
- 270 real words and 192 non-words allocated overall.
- 462 scored presentations overall.
- 193 non-word candidate rows are supplied in the bundled review CSV. The 193rd source row, candidate ID `N270`, is held as one unallocated reserve.

| Session | Real words | Non-words | Scored items |
|---|---:|---:|---:|
| 1 | 45 | 32 | 77 |
| 2 | 45 | 32 | 77 |
| 3 | 45 | 32 | 77 |
| 4 | 45 | 32 | 77 |
| 5 | 45 | 32 | 77 |
| 6 | 45 | 32 | 77 |
| **Total** | **270** | **192** | **462** |

Practice items are not included in these 77 scored items. The number, placement, source and feedback policy for practice items are unresolved.

## Supplied candidate-file audit

The application bundles:
- 270 real Kannada words in `selected_words_list_v1.csv`.
- 193 non-word review rows in `nonword_candidates_supplied_v1.csv`, with all rows pending native Kannada review.
- A separate original-workbook summary reporting 270 non-word candidates and method counts 68/68/67/67.

The bundled 193-row CSV has method counts 34/46/65/48. Its count differs from the original workbook summary by 77 rows. Do not assume the two artifacts are the same candidate pool. Candidate text/structure validation is not Kannada linguistic approval.

## Conflict with the requirements baseline

`StudyProtocol` still reflects the requirements transcription `KWR-REQ-2026-11-02`: 90 presentations per session (five practice + 85 test), six sessions, and a 270+270 bank. The item-bank importer also requires 540 approved rows arranged as six 90-item blocks with 45 real and 45 non-word entries each. That is materially different from 77 scored items per session.

The current artifacts sum to 463 source entries (270 real words + 193 non-word candidate rows), not 464. The v2 allocation accounts for 462 and reserves one candidate.

## Allocation policy and release gates

The machine-readable `assets/item_bank/allocation_proposal_v2.json` uses the first 192 candidate rows in CSV source order for a deterministic engineering partition and reserves row 193 (`N270`). This is not a randomised, balanced or approved study sequence. Do not create frozen participant manifests from it.

Before any participant session can be enabled, the study team must approve in writing:
1. The final scored-item and practice counts and their relationship to the 540-item baseline.
2. Session/block/visit definitions and the allocation method.
3. Native Kannada approval for every non-word stimulus to be used.
4. The reserve/replacement policy and item-bank checksum.
5. Trial timing, no-response, rewards, interruption, resume and repeat behavior.
6. Ethics/consent, data governance, retention and export/REDCap requirements.

The participant release gate therefore remains closed.
