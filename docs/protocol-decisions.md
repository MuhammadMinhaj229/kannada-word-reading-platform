# Protocol decisions and PI/statistician sign-off

**Status: BLOCKED — written study-team approval required.**  
**Requirements transcription:** `KWR-REQ-2026-11-02`  
**Application source of truth:** `lib/core/config/study_protocol.dart`  
**Do not infer a final protocol from the current constants or the working allocation proposal.**

This document records unresolved contradictions so the research team can approve one authoritative protocol. Until a dated, attributable written approval is attached or linked here, the participant workflow must remain disabled and no final allocation manifest may be generated.

## 1. Conflicting structures that must be reconciled

| Source / interpretation | Per block/session | Six-block total | Status |
|---|---|---:|---|
| Requirements transcription in `StudyProtocol` | 90 presentations = 5 practice + 85 test | 540 presentations = 30 practice + 510 test | Transcribed; not approved |
| 90-scored-item interpretation recorded in project discussions | 90 scored = 45 real + 45 non-word; practice may be additional | 540 scored, plus practice if additional | Requires confirmation against signed source protocol |
| Earlier `working-allocation-v1.md` | 77 scored = 45 real + 32 non-word, 5 provisional practice additional; 194 candidates in that draft | 462 scored + 30 provisional practice | Superseded planning draft; not approved |
| Latest engineering proposal v2 | 77 scored = 45 real + 32 non-word; practice treatment unspecified | 462 scored = 270 real + 192 non-word; one supplied candidate reserved | User-confirmed engineering target only; not PI/statistician approval |

The item-bank source contains 270 real words and 270 non-word candidates. The arithmetic differs materially across the interpretations above. The research team must state whether every candidate is intended to be administered, whether the practice stimuli are drawn from or additional to the 540-item bank, and whether “session”, “block” and “visit” refer to the same or different units.

The latest supplied assets add a separate reconciliation issue: the original workbook summary records 270 non-word candidates (A/B/C/D = 68/68/67/67), while the review CSV currently bundled in the app contains 193 rows (A/B/C/D = 34/46/65/48), all pending. A previously stated total of 464 is also not reproducible from the current file counts: 270 real-word rows + 193 supplied non-word candidate rows = 463 source entries; proposal v2 allocates 270 + 192 = 462 and reserves one candidate.

## 2. Decisions required

### A. Visit, block and trial counts
- [ ] Confirm the visit schedule: number of visits and blocks per visit (including whether the intended structure is 3 visits × 2 blocks).
- [ ] Define the terms **visit**, **block** and **session** and map them to app navigation and stored records.
- [ ] Confirm scored presentations per block: 85, 90, 77, or another explicitly stated number.
- [ ] Confirm whether five practice trials are included in the stated presentation count or are additional.
- [ ] Confirm the real-word/non-word ratio per block and total bank coverage (including whether all 270 + 270 items are used exactly once).
- [ ] Define the source, content and reuse rules for practice items.

### B. Timing, response and scoring
- [ ] Confirm whether the stimulus display is exactly 10 seconds and what starts/stops that timer.
- [ ] Define response window, timeout, no-response recording and automatic advancement.
- [ ] Define the response event that determines reaction time, accuracy and completion.
- [ ] Define pause, resume, interruption, restart and power-loss recovery behavior.
- [ ] Define whether a trial can be repeated, by whom, and how the repeat is recorded.

### C. Rewards and instructions
- [ ] Resolve the reward cadence: every 10 answers in the requirements transcription versus every 5 completed scored trials in an earlier decision note.
- [ ] State whether reward cadence is based on attempted trials, completed trials, responses, or correct responses.
- [ ] Approve reward text/behavior and practice feedback.
- [ ] Confirm whether any item is spoken during scored trials and whether stimulus audio must remain silent.
- [ ] Approve the Kannada instruction script, labels and exact audio clip sequence.

### D. Allocation and counterbalancing
- [ ] Approve fixed versus random/counterbalanced ordering.
- [ ] Define balancing constraints (e.g. age of acquisition, POS, syllable/phoneme structure, akshara type), if any.
- [ ] Define random seed, reproducibility, allocation versioning and how frozen allocations are assigned to participants.
- [ ] Confirm whether non-words are paired with source words or matched on any linguistic properties.
- [ ] Confirm non-word candidate review criteria, reviewer roles and written approval evidence.

### E. Visits and governance rules
- [ ] Confirm permitted interval between visits, one-session-per-day policy and same-day restrictions.
- [ ] Define participant and assessor identifier formats.
- [ ] Define supervisor authorization for missed, repeated, resumed or restarted visits.
- [ ] Confirm retention, export authorization, device-loss response and approved REDCap mapping.

## 3. Current engineering constants — not approved protocol

The current Dart constants are:

- `sessionCount = 6`
- `presentationsPerSession = 90`
- `practicePresentationsPerSession = 5`
- `testPresentationsPerSession = 85`
- `stimulusDisplayDuration = 10 seconds`
- `rewardIntervalAnswers = 10`
- `sessionScheduleApproved = false`
- `approvedNonWordCount = 0`
- `participantWorkflowEnabled = false`

Do not change these constants merely to make the app appear internally consistent. Once the PI/statistician signs the decisions above, update the protocol model, allocation generator, tests, UI labels and study documentation together in one reviewed change.

## 4. Approval record

| Role | Name | Decision / document reference | Date | Status |
|---|---|---|---|---|
| Principal Investigator | Pending | Pending | Pending | Awaiting |
| Study statistician | Pending | Pending | Pending | Awaiting |
| Study / linguistic lead | Pending | Pending | Pending | Awaiting |
| Data governance / ethics delegate (where applicable) | Pending | Pending | Pending | Awaiting |

**Approval evidence location:** Pending. Attach or link the signed protocol/amendment or attributable written approval. Record the exact version/date; a verbal discussion or a code change is not approval.

## 5. Release gate

The protocol gate stays closed until the approved record is complete. Engineering may prepare test harnesses and non-participant simulations, but must not enable participant identifiers, real assessment trials, official allocations or field deployment while any required decision remains unresolved.

Related planning records: [working allocation v1 (superseded)](protocol/working-allocation-v1.md) and [working allocation v2](protocol/working-allocation-v2.md).
