# Repository and field-readiness status — 10 November 2026

## Source, CI and deployments

- `main` is the production source branch.
- Main branch was subsequently advanced by reviewed Dependabot merges; the 10 November base commit for the Option C architecture branch is `68415f9aa1bb2d0a7231d5fed72403f7086fc53a`.
- PR #9 merged on 8 November 2026: [Fix engineering preview publication and protocol readiness UX](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/pull/9).
- PR #11 merged on 9 November 2026: [Harden trial persistence, item-bank validation and signed release gate](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/pull/11). The database authorization boundary is now bound to the private, fail-closed release gate; item-bank/trial validation and Gradle checksum pinning were added.
- Main-branch workflow run #42473020877 completed successfully. Formatting, static analysis, all 65 unit/widget tests, ARM64 Android debug build, Flutter Web build, Web metadata checks, APK verification and both validation artifact uploads passed.
- The workflow published/updated the stable prerelease tag `padalab-preview` at the same commit as `main`.
- [Stable Android engineering-preview release](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/tag/padalab-preview) contains `padalab-android-arm64-debug.apk` and its `.sha256` checksum.
- The release APK is debug-signed and is not a production/field APK. It is for controlled engineering review only.
- Vercel production deployment `dpl_9S6PVz3GW214tpvmJqHLfp6trNsC` reached `READY` from the same main commit. Canonical review URL: https://kannada-word-reading-platform.vercel.app/.
- The deployed `app-release.json` identifies the channel as `engineering-preview`, with `participantReady: false` and `participantDataSync: false`.
- Vercel Web is an independent Flutter application with a browser-local storage target. Android uses its own SQLCipher/Keystore-backed storage. There is no synchronization or shared participant backend. Participant data entry remains disabled on Web pending separate institutional approval.

## Accepted platform architecture — Option C (10 November 2026)

- One Flutter/Dart source codebase builds the Vercel Web application and Android APK.
- Web and Android have independent local data stores: browser-local storage for Web and SQLCipher in Android private storage for Android.
- No cross-device synchronization, cloud participant database, remote participant API, background upload or data bridge is permitted.
- Vercel deployment updates Web assets only; Android APK distribution remains a separate release process.
- The decision and acceptance criteria are recorded in [platform storage architecture](platform-storage-architecture.md).
- **Implementation gap:** the current Web target remains a review/QA surface and does not yet have a structured IndexedDB persistence adapter. This architecture decision is accepted but does not claim that browser persistence has been implemented.

## Implemented engineering foundations

- Flutter application shell and responsive assessor workspace.
- 270 supplied real Kannada words parsed and validated with source metadata.
- 270 non-word candidates structurally catalogued; none approved for use.
- Offline audio service with an approval manifest and no device TTS fallback.
- SQLCipher and secure-key storage foundations, frozen session-manifest persistence and transactional trial APIs.
- Web review build, manual update behavior and service-worker cache fingerprinting.
- CI validation for formatting, static analysis, unit/widget tests, Android ARM64 debug APK and Flutter Web.
- Stable engineering-preview APK publication with exact tag discovery/update and checksum upload.
- Assessor UI now labels protocol figures as unapproved baselines; release blockers remain visible.
- Child-facing Task preview added for QA: 5 practice + 10 synthetic test cards, no child correctness feedback, response-time capture in memory, neutral 10-answer milestone and separate assessor-only QA results. The stopwatch starts after the stimulus is rendered; app backgrounding or leaving the preview invalidates the run and requires a restart.

## Protocol and content blockers

- **Protocol not frozen.** The requirements transcription says 6 × 90 total presentations (5 practice + 85 test); another study baseline describes 90 scored per block (45 real + 45 non-word); an older 77-scored proposal is marked planning-only. Reward cadence also conflicts (every 10 answers versus every 5 completed scored trials). See [protocol sign-off register](protocol-decisions.md).
- **Non-word bank not approved.** 270 candidates remain Pending; 0/270 approved. Native Kannada review and written study-team approval are required.
- **Instruction audio not approved.** The source recording still needs transcription, segmentation, native-speaker recording/QA and written approval references.
- **Participant workflow is disabled.** The new child-facing Task preview is a QA simulation only: synthetic fixtures and in-memory responses, with no participant identifiers or SQLCipher writes. It is isolated from the participant database and invalidates a QA run when focus is lost. The production participant flow is still not integrated with SQLCipher persistence, trusted assessor/supervisor authorization, a PI-approved frozen allocation, response/timeout rules, interruption recovery and audit.
- **Governance/export work is incomplete.** Protected CSV/XLSX export, REDCap mapping, backup/restore, retention/deletion and audit review are not yet accepted.
- **Target tablet acceptance is pending.** Actual-device offline, audio, Kannada rendering, touch, timing, pause/restart, database recovery, update and battery tests remain.
- **Institutional Android release signing is pending.** The currently published APK is debug-signed; the institution must approve package/signing ownership and provision a protected production signing key. Managed Play/internal distribution and update policy are not active.

## Safety disposition

PadLab is an engineering candidate and review deployment, not an approved research instrument. Do not enter participant identifiers or administer the task. Do not distribute the debug APK as a field release. Keep participant data entry closed until protocol, item bank, audio, ethics/data governance, session workflow, export, target-device acceptance and institutional signing evidence are complete.
