# Repository and field-readiness status — 8 November 2026

## Branch, merge and deployment

- `main` is the default branch and the source of truth for the active Flutter application.
- Flutter assessor application migration merged through PR #2 on 7 November 2026.
- Merge commit: `85a05c229be430a9bc53d600d9db79c18a3bcddf`.
- Latest main commit inspected during this audit: `f841e8439057df394622e54f4d836b189c62408b`.
- The latest Vercel status check for that commit was successful. The configured Vercel target is an SSO-protected, no-index, read-only review surface; the status check is not a substitute for manual browser/device acceptance.
- GitHub Actions run #42457963394: the Flutter validation job completed successfully (formatting, analysis, tests, Android ARM64 debug APK, Flutter Web output and artifact uploads). The subsequent preview-release job failed while updating a missing Git tag: GitHub returned HTTP 422, but the workflow handled only HTTP 404. The failure and remediation are tracked in the production-readiness branch.
- The repository had no open pull requests at the time of this audit. The previous status entry referring to Dependabot PRs #3–#6 was stale.
- Historical Next.js archives are retained. The two merged feature branches and old mobile-review branch are cleanup candidates, but should only be removed after their unique content is confirmed preserved on `main`.
- The engineering-preview GitHub Release was not present at the time of inspection. Do not assume the README's APK link is currently downloadable until the publication workflow succeeds and the release assets are verified.

## Implemented engineering foundation

- Flutter application shell and responsive assessor workspace.
- 270 supplied real Kannada words parsed and validated for required source columns, uniqueness and expected row count.
- 270 non-word candidates structurally catalogued; none approved for participant use.
- Offline audio service and approval manifest; device text-to-speech fallback is not permitted.
- SQLCipher database foundation, Android secure-key storage integration, session-manifest persistence and transactional trial APIs.
- Flutter Web review build and service-worker cache fingerprinting.
- CI validation for Dart formatting, static analysis, tests, Android ARM64 debug APK and Flutter Web.
- Separate signed-APK workflow requiring institution-owned signing secrets.

## Protocol and content blockers

- **Protocol not frozen.** The requirements transcription describes six sessions with 90 total presentations per session (five practice + 85 test). A separate study baseline describes 90 scored items per block (45 real + 45 non-word), while an earlier 77-scored proposal is planning-only. Reward cadence also conflicts (every 10 answers versus every 5 completed scored trials). No implementation should select among these interpretations without written PI/statistician approval. See [protocol sign-off register](protocol-decisions.md).
- **Non-word bank not approved.** All 270 candidates remain Pending (0/270 approved). Native Kannada review and attributable written study-team approval are required.
- **Instruction audio not approved.** The supplied source recording still needs transcription, segmentation, native-speaker recording/QA, clip packaging and written approval references.
- **Participant workflow is incomplete and disabled.** The assessor/session UI is not wired end-to-end to SQLCipher persistence, trusted authorization, frozen allocation, child trial presentation, monotonic timing, recovery and audit.
- **Governance/export work is incomplete.** Protected CSV/XLSX export, signed data dictionary and REDCap mapping, backup/restore, retention/deletion and audit review are not accepted.
- **Target tablet acceptance is pending.** Actual-device offline cold-launch, SQLCipher/Keystore, Kannada glyph shaping, audio, touch, timing, interruption/recovery, update and battery tests remain.
- **Institutional Android release signing is pending.** The downloadable engineering preview, when published, is debug-signed and must not be distributed as a field release. Package identifier, signing owner and protected release credentials require institutional confirmation.

## Safety disposition

PadLab is an engineering candidate and browser review deployment, not an approved research instrument. Do not enter participant identifiers or administer the task. Do not distribute a debug APK as a field release. Keep participant data entry closed until protocol, item bank, audio, ethics/data governance, session workflow, export, target-device acceptance and institutional signing evidence are complete.

A successful CI build proves code checks and buildability only; it does not establish research validity, linguistic/audio approval, ethics approval, security certification or field readiness.
