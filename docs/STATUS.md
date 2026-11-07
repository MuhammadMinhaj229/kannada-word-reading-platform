# Repository status — 7 November 2026

## Branch and deployment state

- Production `main` remains the Next.js PWA until the Flutter migration PR is reviewed and merged.
- The Flutter implementation is on `feat/flutter-android-foundation`, proposed by draft PR #2.
- The post-PR-1 PWA is preserved on `archive/nextjs-pwa-before-flutter-migration`.
- Vercel is configured for the repository-root Flutter Web output at `build/web`. The Vercel browser build is read-only for participant information.
- The latest repository commits have not yet been verified by a fresh full GitHub Actions run or a successful Vercel preview. Previous Vercel checks hit an account deployment/build-rate limit.

## Implemented on the Flutter branch

- The active Flutter application has no synthetic assessment path or demo build flag.
- Responsive assessor workspace: NavigationRail on wide tablet/desktop layouts and bottom navigation on narrow screens.
- Assessment landing page shows actual study content status and keeps participant entry unavailable until signed release approvals are present.
- The supplied 270-word CSV is bundled unchanged and parsed into 270 unique source entries with W001–W270 IDs and source metadata.
- The non-word summary preserves the supplied 68 / 68 / 67 / 67 method proportions. All 270 candidates remain Pending and cannot be used as stimuli.
- Settings includes a searchable view of the supplied word bank, metadata distributions, non-word review state, audio package state, local-storage status and release blockers.
- Device TTS implementation was removed. A bundled-audio player service requires an approved audio manifest and local clips.
- SQLCipher, secure-key storage, frozen manifests and transactional response APIs remain in the data layer.
- Responsive workspace tests cover 15 phone, tablet and desktop viewport sizes.
- The Web service-worker cache fingerprint now includes actual asset bytes, not only URL paths.
- Ordinary CI no longer uploads the generated Android scaffold. A separate signed APK workflow requires protected institution-owned signing secrets and uploads only the APK and checksum.

## Supplied content audit

| Content | Repository state |
|---|---|
| Real Kannada words | 270 source rows bundled and validated |
| Source metadata | Transcription, meaning, POS, age band, AoA, syllables, phonemes, morphemes and akshara type retained |
| Non-word candidates | 270 candidates in the supplied workbook; not included as active stimuli |
| Method A — vowel replacement | 68 |
| Method B — consonant replacement | 68 |
| Method C — suffix + prefix | 67 |
| Method D — prefix + suffix | 67 |
| Non-word approval | 0 / 270 marked approved in the source supplied to us |
| Kannada instruction audio | Source recording supplied; not yet reviewed, segmented or approved as the application clips |

## Current gaps

- Participant entry/session controls are presented but remain inactive while the release gate is closed.
- The SQLCipher APIs are not yet wired end-to-end to the assessor and child assessment screens.
- Session history, exact resume/restart, supervisor PIN, session summary, audit and protected CSV/XLSX export remain to be integrated and tested.
- The final signed item bank and six approved session-allocation manifests have not been supplied.
- The visit schedule, trial ordering, timeout/no-response, practice-item sourcing, reward treatment, repeat and same-day rules require study-team confirmation.
- Approved Kannada instruction clips and written audio approval are not packaged. No synthetic speech fallback is used.
- Actual Android SQLCipher/Keystore, offline cold launch, reaction time, audio, Unicode rendering, power-loss and update behavior require target-tablet validation.
- No institution-owned signing identity or protected release keystore is currently confirmed. The signed APK workflow will fail closed until all four signing secrets are configured.
- Vercel must produce a fresh successful preview after the documented deployment limit clears.

## Safety disposition

The application is an engineering candidate, not an approved research instrument. Do not enter participant identifiers or administer the task until protocol, item bank, audio, ethics/data governance, supervisor, export and target-device acceptance evidence is complete. Do not merge the Flutter PR to production or distribute an engineering/debug APK as a field release.
