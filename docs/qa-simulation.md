# Child task QA preview

The **Task preview** navigation entry opens the current child-facing, non-participant game preview implemented in `lib/features/assessor/presentation/child_task_simulation_screen.dart`.

## Run it

- On the Vercel workspace, open PadLab and select **Task preview** from the bottom navigation on phones or the navigation rail on wider screens.
- On Android, install the engineering APK, open **Task preview**, and tap **ಪ್ರಾರಂಭಿಸೋಣ**.
- The preview presents five supplied real words as practice.
- It then presents ten QA cards, alternating five further supplied real words with the first five supplied non-word candidates.
- Select **ಪದ** or **ಪದವಲ್ಲ** on each card.
- A neutral milestone appears after ten total responses; continue to complete the remaining cards.
- The completion view shows counts of Word and Not Word selections and a **ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ** action resets the preview.

## What the preview actually records

- The preview uses the bundled real-word CSV and the bundled 193-row non-word candidate CSV.
- The non-word candidates remain pending native Kannada review. They are displayed only to exercise the reviewer-facing task interface and are not approved stimuli.
- Each response is retained in memory only for the current preview run. The completion summary counts the selected response categories and practice/task phase.
- The preview does not calculate correctness, research scores or reaction time.
- No child ID, participant ID, assessor ID or other personal information is requested.
- No SQLCipher database, session manifest, participant export or network endpoint is called.
- Leaving the preview or backgrounding the application interrupts the current run. Restart the preview to begin again.
- The preview does not write responses to localStorage, IndexedDB or the Android assessment database.

## What this preview can validate

It is suitable for checking the child-facing navigation, Kannada font rendering, touch targets, response-button progression, neutral milestone, completion display and narrow-screen layout.

It is **not** suitable for cognitive piloting, reaction-time validation, linguistic validation, protocol validation, participant data collection or producing research results.

## Separate assessor content drafts

The Settings screen now contains a content-draft workspace. It can create and edit local drafts for supplied Real Words and Non-Words, preserve draft revisions and download a JSON backup. Drafts remain separate from the bundled catalogue and do not affect this preview. Web drafts are stored in the browser's IndexedDB and are not encrypted; Android drafts are stored in the SQLCipher database. Do not enter child information, participant records or reviewer personal information.

## Before a field assessment can be enabled

The PI/statistician must approve the final protocol and allocation; a native Kannada linguistic lead must approve every non-word stimulus and the instruction/audio package; and institutional ethics, consent, data governance, retention, export, supervisor authorization, recovery, target-tablet acceptance and institutional signing requirements must be completed.

See [protocol decisions](protocol-decisions.md), [working allocation proposal v2](protocol/working-allocation-v2.md), [privacy and data handling](privacy-and-data.md) and [field readiness status](STATUS.md).
