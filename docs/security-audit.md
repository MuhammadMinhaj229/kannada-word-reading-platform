# Security and release audit

**Audit date:** 7 November 2026  
**Scope:** Flutter Android/Web implementation on `feat/flutter-android-foundation`, pull request #2, generated Android host, GitHub Actions build, and Vercel project settings.  
**Disposition:** Engineering hardening in progress. **Not approved for research participant use.**

This is a code/configuration review and CI evidence summary. It is not a third-party penetration test, institutional security approval, or real-device acceptance certificate.

## Verified controls

### Android build and platform hardening

- The Android host is generated from the pinned Flutter SDK and hardened by `scripts/deploy/configure_android_project.sh`.
- Minimum Android API is 26; orientation is landscape.
- Android backup is disabled and cleartext network traffic is disabled.
- R8 code/resource shrinking is configured for release builds, with SQLCipher keep rules.
- The only declared Internet permission is used for the explicit Google Play update path; no research API, cloud database, analytics or telemetry service is configured in the Flutter application.
- The CI debug APK is built for **ARM64 only** and is checked for unexpected 32-bit/x86 native libraries. CI verifies its Android signature with `apksigner` and emits a SHA-256 checksum.

### Local data protection foundation

- Assessment storage uses SQLCipher rather than plaintext SQLite on Android.
- A 32-byte cryptographically random database key is generated with `Random.secure()` and stored through `flutter_secure_storage` (Android secure-storage/Keystore integration).
- The key provider validates the stored key format and reads it back after creation.
- If the encrypted database exists but its key is missing or unreadable, the app fails closed rather than generating a replacement key.
- A legacy plaintext database is detected and preserved; it is never silently overwritten or ignored.
- SQLite foreign keys, WAL, secure delete and SQLCipher memory security are configured.
- Session creation freezes the ordered trial manifest in one transaction. Trial display verifies every stimulus field against that frozen manifest. Response persistence and session-cursor advancement are atomic and exactly-once guarded.
- Database open/close races are covered by a test; state-transition methods fail when the requested session transition did not occur.
- The completion API no longer accepts a UI-supplied reward counter. Repeat/restart is disabled until an actual trusted supervisor-authorization verifier exists.

### Web hosting and Vercel

- Vercel serves a static Flutter Web review build; it is not the Android research data store.
- Security response headers and no-index headers are configured in `vercel.json`.
- Vercel SSO protection is now configured for **all deployment targets**, including attached project domains. This closes the prior `all_except_custom_domains` gap.
- No Vercel environment variables or application secrets are required by the current offline review app.
- The production branch remains `main`; the Flutter migration is still a draft PR and has not been merged into production.

### Automated checks

- The draft branch includes a Dependabot update configuration for Dart/pub and GitHub Actions. GitHub reads `.github/dependabot.yml` from the default branch; scheduled update PRs will not start until this configuration is merged to `main`.

The GitHub Actions workflow runs dependency resolution, shell-script validation, canonical Dart formatting, `flutter analyze --fatal-infos`, unit/widget tests, Android debug and release-mode builds, and the Flutter Web release build. The current workflow additionally checks the ARM64 debug APK contents and verifies its signing certificate.

Host-side database tests use SQLite FFI. They verify schema/foreign keys, concurrent opens, legacy plaintext refusal, missing-key behavior, manifest tamper rejection, atomic response/cursor updates, idempotent response commits and close/open race behavior.

## Security issues addressed during this audit

| Finding | Change | State |
|---|---|---|
| Database handle could remain open if `close()` raced initialization | Serialize close with the single-flight open and make later callers wait | Implemented; CI verification pending |
| Caller-supplied boolean could claim supervisor authorization | Remove the boolean trust path; disable repeat/restart until a verifier exists | Implemented; CI verification pending |
| UI could supply arbitrary reward totals | Remove reward counter from response API; retain only the database value pending PI-approved reward logic | Implemented; CI verification pending |
| Failed session status transitions could be silently ignored | Require exactly one row to change for interrupt/resume | Implemented; CI verification pending |
| APK contained all ABIs and was unnecessarily large | Build ARM64-only tablet APK, verify ABI contents, signature and SHA-256 | Implemented; CI verification pending |
| Vercel SSO excluded attached project domains | Set SSO protection to all deployment targets | Applied; verify project settings after update |

## Release blockers — must remain closed

1. **Research protocol:** PI/statistician approval is required for session count/order, practice/scored-item interpretation, response timeout/no-response, rewards, repeat/restart and same-day handling.
2. **Approved content:** the approved 270-real-word + 270-non-word item bank, native-speaker linguistic sign-off, final checksum, Kannada font and instruction recordings are not yet supplied.
3. **Supervisor authentication:** no supervisor PIN provisioning, rate limiting, lockout, audit trail or trusted authorization verifier is implemented. Repeat/restart is therefore disabled.
4. **Complete application workflow:** the SQLCipher repository is a foundation and is not yet connected to a full assessor/participant/session UI, interruption recovery, approved export dictionary, protected export, REDCap mapping or retention/deletion workflow.
5. **Native encryption validation:** FFI tests do not execute the Android SQLCipher plugin or Android Keystore. An Android emulator/device integration test and real tablet acceptance are still required.
6. **Offline and audio acceptance:** no approved voice recordings or bundled Kannada font exist. Cold offline launch, glyph shaping, timing, touch, power-loss recovery and local audio must be tested on the actual tablet.
7. **Production signing and distribution:** there is no institution-owned signing identity or protected release keystore in GitHub secrets; no Play Console/Managed Google Play track or device-management policy is configured. The CI debug APK is for engineering review only; the release-mode candidate is not a signed distribution package.
8. **Vercel deployment:** the Hobby account hit the daily deployment limit. The current source changes need a fresh Vercel preview build after the rate limit resets; no production deployment should be promoted from this draft.

## Required release decision

Keep the participant workflow fail-closed. Do not enter real child data, merge PR #2 to `main`, or distribute the debug APK as a field application until the blockers above are closed with recorded evidence and approvals.

**Passing CI is evidence of code analysis and buildability, not evidence of research validity, security certification, offline acceptance or production readiness.**
