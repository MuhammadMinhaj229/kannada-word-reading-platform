# Repository and delivery status — 10 November 2026

## Delivery model

- **Vercel is the working online website** for the interactive Flutter workspace: bundled Kannada item-bank review, Settings, release-readiness information and the non-participant Task preview.
- **The Android APK is the downloadable offline version** built from the same Flutter source. The installed application shell and bundled content are available without a network connection.
- The Vercel PWA caches its shell and bundled static assets after the first successful online load. It does not persist participant data.
- Browser participant identifiers and research responses remain disabled. Participant data collection is intended for the Android application only, after every study approval and field-acceptance requirement is completed.
- Live website: https://kannada-word-reading-platform.vercel.app/
- Stable Android engineering APK: https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/tag/padalab-preview

## Option C platform storage

- Web and Android are independent local applications built from one Flutter/Dart codebase; there is no shared participant database, API, import/export bridge or cross-device synchronization.
- Web uses browser-local storage only for small, non-sensitive workspace preferences. Participant identifiers, child names, trial responses and research records remain disabled on Web.
- Android retains SQLCipher in app-private storage with its Android Keystore-backed key foundation; field collection remains locked until study, governance, workflow and tablet-acceptance gates pass.
- The current Web adapter persists only the selected workspace tab. Structured IndexedDB persistence is not implemented; do not describe the Web app as a participant data-collection system.
- Vercel deployments update Web assets only. Android APK delivery and updates remain separate.

## Source, pull requests and CI

- `main` is the production source branch; Vercel is linked to this repository.
- PR #11 security and data-integrity hardening is merged.
- PR #15 child-facing Task QA preview is merged. It remains synthetic and stores responses in memory only.
- Dependabot PRs #12, #13 and #14 are merged: `actions/download-artifact@v8`, `actions/github-script@v9` and `softprops/action-gh-release@v3`.
- Dependency lockfile drift discovered after those merges is being corrected by committing the resolved transitive versions and enforcing the lock in CI, Vercel and signed-release builds.
- The validation workflow covers Dart formatting, static analysis, unit/widget tests, Android ARM64 debug packaging, Flutter Web build, metadata checks and artifact verification.
- Ordinary CI publishes a debug-signed engineering APK and checksum. It is not a signed field release.

## Implemented engineering foundations

- One Flutter/Dart application codebase for Android and Web.
- Responsive assessor workspace with Assessment, Task preview and Settings navigation.
- 270 supplied real Kannada words bundled and parsed with source metadata.
- 270 non-word candidates catalogued in the required 68 / 68 / 67 / 67 construction proportions; all remain pending native Kannada approval.
- Interactive non-participant Task preview: five practice cards and ten synthetic QA cards, in-memory responses, reaction-time logic, assessor-only results and lifecycle interruption handling.
- Offline audio service that plays only bundled approved recordings; no device TTS fallback.
- SQLCipher and Android secure-key foundations, frozen session-manifest persistence and transactional trial APIs.
- PWA service worker with content-derived cache identity and user-triggered refresh.
- Separate Android signed-release workflow requiring institution-owned signing credentials and a verified release authorization gate.

## Research and release blockers

- **Protocol not frozen.** Conflicting study interpretations remain unresolved, including trial counts, practice inclusion, reward cadence, visit/session structure, timing and interruption rules. PI/statistician written approval is required.
- **Non-word bank not approved.** 0/270 candidates are approved. Native Kannada review and written study-team approval are required.
- **Instruction audio not approved.** The supplied recording still needs transcription, segmentation, approved clips and approval references.
- **Participant workflow not complete.** Assessor/session/child workflow, supervisor authorization, end-to-end SQLCipher integration, session history/resume/recovery and audit still need completion.
- **Governance and export work incomplete.** Ethics/consent, retention and device-loss procedures, export dictionary, REDCap mapping, backup/restore and deletion process need institutional sign-off.
- **Target tablet acceptance pending.** Offline cold launch, Kannada shaping, audio, touch, reaction timing, SQLCipher/Keystore, power-loss recovery, battery and update behavior must be tested on the actual tablet.
- **Production Android signing pending.** Institution must approve the permanent package identity and own/provision the signing key and protected GitHub secrets. The currently published APK is debug-signed.

## Safety disposition

PadLab is an engineering candidate, not yet an approved research instrument. Keep the participant release gate closed. Do not collect participant identifiers or administer study trials until the PI/statistician protocol, linguistic review, audio, ethics/data-governance, session workflow, export, device acceptance and institutional signing evidence are complete. A green CI run or a Vercel deployment does not establish field readiness.
