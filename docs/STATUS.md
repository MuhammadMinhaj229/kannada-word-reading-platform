# Repository and field-readiness status — 9 November 2026

## Source, CI and deployments

- `main` is the production source branch.
- Latest main commit: `c25aa723ffd2fa4dbafc14c3fd7b0b4372179511`.
- PR #9 merged on 8 November 2026: [Fix engineering preview publication and protocol readiness UX](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/pull/9).
- Main-branch workflow run #42473020877 completed successfully. Formatting, static analysis, all 65 unit/widget tests, ARM64 Android debug build, Flutter Web build, Web metadata checks, APK verification and both validation artifact uploads passed.
- The workflow published/updated the stable prerelease tag `padalab-preview` at the same commit as `main`.
- [Stable Android engineering-preview release](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/tag/padalab-preview) contains `padalab-android-arm64-debug.apk` and its `.sha256` checksum.
- The release APK is debug-signed and is not a production/field APK. It is for controlled engineering review only.
- Vercel production deployment `dpl_9S6PVz3GW214tpvmJqHLfp6trNsC` reached `READY` from the same main commit. Canonical review URL: https://kannada-word-reading-platform.vercel.app/.
- The deployed `app-release.json` identifies the channel as `engineering-preview`, with `participantReady: false` and `participantDataSync: false`.
- Vercel Web is a no-index review surface, not a participant data-collection target. The Android build is the intended field platform once all approvals and acceptance gates are satisfied.

## Implemented engineering foundations

- Flutter application shell and responsive assessor workspace.
- 270 supplied real Kannada words parsed and validated with source metadata.
- 270 non-word candidates structurally catalogued; none approved for use.
- Offline audio service with an approval manifest and no device TTS fallback.
- SQLCipher and secure-key storage foundations, frozen session-manifest persistence and transactional trial APIs.
- Web review build, manual update behavior and service-worker cache fingerprinting.
- CI validation for formatting, static analysis, unit/widget tests, Android ARM64 debug APK and Flutter Web.
- Stable engineering-preview APK publication with exact tag discovery/update and checksum upload.
- Assessor UI now labels protocol figures as unapproved baselines; release blockers remain visible.\n- Child-facing Task preview added for QA: 5 practice + 10 synthetic test cards, no child correctness feedback, response-time capture in memory, neutral 10-answer milestone and separate assessor-only QA results.

## Protocol and content blockers

- **Protocol not frozen.** The requirements transcription says 6 × 90 total presentations (5 practice + 85 test); another study baseline describes 90 scored per block (45 real + 45 non-word); an older 77-scored proposal is marked planning-only. Reward cadence also conflicts (every 10 answers versus every 5 completed scored trials). See [protocol sign-off register](protocol-decisions.md).
- **Non-word bank not approved.** 270 candidates remain Pending; 0/270 approved. Native Kannada review and written study-team approval are required.
- **Instruction audio not approved.** The source recording still needs transcription, segmentation, native-speaker recording/QA and written approval references.
- **Participant workflow is disabled.** The new child-facing Task preview is a QA simulation only: synthetic fixtures and in-memory responses, with no participant identifiers or SQLCipher writes. The production participant flow is still not integrated with SQLCipher persistence, trusted assessor/supervisor authorization, a PI-approved frozen allocation, response/timeout rules, interruption recovery and audit.
- **Governance/export work is incomplete.** Protected CSV/XLSX export, REDCap mapping, backup/restore, retention/deletion and audit review are not yet accepted.
- **Target tablet acceptance is pending.** Actual-device offline, audio, Kannada rendering, touch, timing, pause/restart, database recovery, update and battery tests remain.
- **Institutional Android release signing is pending.** The currently published APK is debug-signed; the institution must approve package/signing ownership and provision a protected production signing key. Managed Play/internal distribution and update policy are not active.

## Safety disposition

PadLab is an engineering candidate and review deployment, not an approved research instrument. Do not enter participant identifiers or administer the task. Do not distribute the debug APK as a field release. Keep participant data entry closed until protocol, item bank, audio, ethics/data governance, session workflow, export, target-device acceptance and institutional signing evidence are complete.
