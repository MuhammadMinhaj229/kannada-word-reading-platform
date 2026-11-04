# Working allocation baseline — not yet approved

**Status:** implementation planning baseline only. Do not administer this allocation until the study team confirms it in writing.

## Intended pool and six-session split

The current working instruction is 270 real Kannada words and 194 non-words across six sessions, with 45 real words and 32 non-words in each session (77 scored items).

| Session | Real words | Non-words | Scored items |
|---|---:|---:|---:|
| 1 | 45 | 32 | 77 |
| 2 | 45 | 32 | 77 |
| 3 | 45 | 32 | 77 |
| 4 | 45 | 32 | 77 |
| 5 | 45 | 32 | 77 |
| 6 | 45 | 32 | 77 |
| **Total** | **270** | **192** | **462** |

Two of the intended 194 non-words remain in reserve and are not silently appended to sessions.

## Source-file discrepancy

The uploaded `non word list.csv` contains 193 data rows, one fewer than the intended 194. The intended pool is 464 items, while the currently uploaded files contain 463 entries. One additional candidate is required, then all items must follow the native Kannada review and written approval process.

No stimulus text is committed by this foundation change.

## Practice-item interpretation

The original requirements describe five practice items plus 85 test items in a 90-item session. This working baseline treats five practice items as additional to the revised 77 scored items, making 82 presentations. The study team must confirm this interpretation before protocol freeze.

## Allocation implementation

The initial allocator is seeded and deterministic. The same approved bank and seed produce the same six ordered session lists. Persist those allocations before a participant starts; a resumed session must use its saved sequence, not allocate again.

The initial algorithm is seeded random allocation. If the final protocol requires stratification by age of acquisition, syllable count, phoneme structure, akshara type or another item characteristic, implement and validate that method before the field bank is enabled.
