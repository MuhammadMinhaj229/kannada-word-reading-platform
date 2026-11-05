# Working allocation proposal v1 — not approved

**Status: planning-only proposal. Do not administer it or treat it as the current study protocol.** This proposal was retained for engineering exploration but conflicts with the formal requirements DOCX. It must be replaced or explicitly approved by the study team before protocol freeze.

## Proposal discussed earlier

The unapproved proposal was:
- 270 real Kannada words.
- 194 non-words.
- Six sessions.
- 45 real words + 32 non-words = 77 scored items per session.
- 192 non-words allocated across six sessions; two kept in reserve.
- Five practice items provisionally additional to the 77 scored items.

| Session | Real words | Non-words | Scored items |
|---|---:|---:|---:|
| 1 | 45 | 32 | 77 |
| 2 | 45 | 32 | 77 |
| 3 | 45 | 32 | 77 |
| 4 | 45 | 32 | 77 |
| 5 | 45 | 32 | 77 |
| 6 | 45 | 32 | 77 |
| **Total** | **270** | **192** | **462** |

This is an alternative working proposal, not an approved allocation.

## Latest uploaded item-bank audit — 5 November 2026

The currently supplied `nonwords_v1.xlsm` contains 270 candidate non-words, not 193:
- 270 unique candidate IDs and 270 unique candidate strings.
- Method split: A_vowel 68, B_consonant 68, C_suffix_prefix 67, D_prefix_suffix 67.
- 270 source-word references are structurally present and match the supplied real-word source list.
- No exact-string overlap with the real-word list or duplicate candidate strings was found by structural validation.
- Every candidate is marked `Pending`; reviewer notes are blank.

These are structural checks only. They do not establish that a Kannada string is pronounceable, meaningless, age-appropriate or acceptable as a research stimulus. All candidates still require native Kannada review and written approval. No candidate is approved for inclusion in the app.

## Conflict with the formal requirements

The requirements DOCX specifies a pool of 270 real words + 270 non-words (540 total), and six sessions of 90 presentations each: five practice and 85 test items. It also specifies a reward after every 10 answers.

The earlier 194-nonword proposal instead gives 77 scored items per session, plus five practice items provisionally outside the scored set. These structures are not equivalent. The exact item counts and whether practice items are part of the bank must be confirmed by the PI/statistician.

## Allocation implementation status

The Flutter branch contains a seeded allocator that can create the 45 + 32 proposal for unit tests. It is not a final research allocation method. The final allocation must be agreed, generated, reviewed, versioned and frozen before administration. Every participant session must restore the saved manifest rather than re-randomising after an interruption.

If the final protocol requires balancing by age of acquisition, syllable count, phoneme structure, akshara type or another item characteristic, that method must be specified and validated before the field bank is enabled.
