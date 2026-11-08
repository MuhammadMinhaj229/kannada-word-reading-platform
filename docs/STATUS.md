# Repository and field-readiness status — 8 November 2026

## Branch, merge and deployment

- `main` is the default branch and the working source of truth.
- Flutter assessor application migration merged through PR #2 on 7 November 2026.
- Merge commit: `85a05c229be430a9bc53d600d9db79c18a3bcddf`.
- Main-branch Flutter validation run #42392937918 completed successfully: tests, ARM64 Android debug build, Flutter Web build, metadata checks, APK verification and artifact upload passed.
- The Vercel production-target deployment built from that merge commit reached `READY`. Canonical review URL: https://kannada-word-reading-platform.vercel.app/.
- Vercel Web is an SSO-protected, no-index, read-only review surface. It is not the participant assessment target.
- Non-main refs remain in GitHub. Two feature branches correspond to merged PRs, two are historical archives, one is an old mobile review branch, and four are open Dependabot branches for PRs #3–#6. Branch deletion is still outstanding; use the repository Branches page and retain only `main` after reviewing the open dependency PRs and archive value.

## Implemented

- Flutter application shell and responsive assessor workspace.
- 270 supplied real Kannada words parsed and validated with source metadata.
- 270 non-word candidates structurally catalogued; none approved for use.
- Offline audio service with approval manifest; no device TTS fallback.
- SQLCipher and secure-key storage foundations, manifests and transactional data APIs.
- Web review build and service-worker cache fingerprinting.
- CI validation for tests, Android ARM64 debug APK and Flutter Web.
- Protected signed-APK release workflow that requires institution-owned signing secrets.

## Protocol and content blockers

- **Protocol not frozen.** The requirements transcription says 6 × 90 total presentations (5 practice + 85 test); another study baseline describes 90 scored per block (45 real + 45 non-word); an older 77-scored proposal is marked planning-only. Reward cadence also conflicts (every 10 answers versus every 5 completed scored trials). See [protocol sign-off register](protocol-decisions.md).
- **Non-word bank not approved.** 270 candidates remain Pending; 0/270 approved. Native Kannada review and written study-team approval are required.
- **Instruction audio not approved.** The source recording still needs transcription, segmentation, native-speaker recording/QA, and written approval references.
- **Participant workflow is disabled.** Assessor session UI is not fully integrated with SQLCipher persistence, authorization, frozen allocation, trial timing, recovery and audit.
- **Governance/export work is incomplete.** Protected CSV/XLSX export, REDCap mapping, backup/restore, retention/deletion and audit review are not yet accepted.
- **Target tablet acceptance is pending.** Actual-device offline, audio, Kannada rendering, touch, timing, pause/restart, database recovery, update and battery tests remain.
- **Institutional Android release signing is pending.** The current downloadable debug APK is for engineering review only; package identifier and keystore ownership/secrets require confirmation.

## Safety disposition

PadLab is an engineering candidate and review deployment, not an approved research instrument. Do not enter participant identifiers or administer the task. Do not distribute the debug APK as a field release. Keep participant data entry closed until protocol, item bank, audio, ethics/data governance, session workflow, export, target-device acceptance and institutional signing evidence are complete.
