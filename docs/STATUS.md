# Repository status — 7 November 2026

## Active application

- Production `main` is still the Next.js PWA; PR #1 (two-tab Game / Settings, Kannada voice preview and browser tests) is merged. The Flutter replacement remains in draft PR #2. A recovery branch, `archive/nextjs-pwa-before-flutter-migration`, preserves the post-PR-1 PWA tree.
- The Flutter branch uses shared Game / Settings screens on Android and Web, with platform-specific storage and update adapters.
- The current Flutter branch has a synthetic Game demo and Settings status view only. It is not a participant assessment workflow.
- The Flutter Web branch generates a versioned service worker to cache the app build after the first successful online load; a manual Refresh updates control activates new versions while idle.
- The earlier Next.js PWA remains recoverable from `archive/nextjs-pwa-before-flutter-migration`.
- Native Android is generated in CI using the pinned Flutter SDK and hardened by `scripts/deploy/configure_android_project.sh`; the Android/Web host directories are not yet committed to the repository.
- Vercel is the only Web host. The public production branch remains `main`; the Flutter migration is still draft PR #2.

## Implemented engineering work

- Explicit build-time demo mode. Normal and release builds default to a participant-safe locked assessor screen; only review builds pass `PADALAB_DEMO_MODE=true`.
- Four-step synthetic child interaction demo remains available in Web preview and debug APK only.
- Formal requirements baseline is encoded as six sessions, 90 presentations/session, 5 practice + 85 test, 270 real-word + 270 non-word pool, 10-second stimulus display and reward interval of 10 answers.
- Removed the unapproved 45-real + 32-non-word random allocator. Runtime now accepts only a frozen 90-trial session manifest with written protocol/allocation references and a bank checksum.
- Fail-closed release gate lists missing approvals, item-bank review, assets, ethics/data governance, recovery/repeat rules, device acceptance, export schema, supervisor credential and signed release.
- SQLCipher database and Android secure-storage key provider foundation. A missing key for an existing encrypted database causes a hard failure; legacy plaintext database detection preserves the file and refuses to silently migrate it. Key/database initialization is single-flight to avoid concurrent creation races.
- Session schema stores an immutable trial manifest. API foundations create a session transactionally, persist a presented-trial event, verify the full item content against the frozen manifest, compute correctness from the frozen item, and commit response plus session-cursor advancement atomically. Host SQLite FFI tests cover schema/foreign keys, concurrent opens, legacy DB preservation, key-loss handling, tamper rejection, response idempotency, response/cursor atomicity and close/open race handling.
- Caller-supplied supervisor booleans were removed; repeat/restart remains disabled until a trusted supervisor-authorization verifier is implemented. Caller-supplied reward counters were removed from response commits pending a PI-approved reward policy.
- The GitHub Actions debug APK is targeted at ARM64 tablets, with ABI-content validation, Android signature verification and a SHA-256 checksum. The previous run failed because SQLCipher's AAR still packaged `armeabi-v7a` and `x86_64`; Gradle packaging exclusions have been added and require a fresh passing CI run.
- CI validates the Vercel static-security contract (security headers, no-index, SPA fallback and revalidation cache rules). A Dependabot configuration for Dart/pub and GitHub Actions is included in this draft PR; GitHub activates it only after the configuration reaches the default branch.
- Vercel SSO protection is configured for all deployment targets, including attached project domains.
- Android hardening script applies API 26 minimum, landscape orientation, Internet permission for Play updates, disables Android backup and cleartext traffic, configures R8 release shrinking and SQLCipher keep rules, and creates machine-local Flutter SDK properties at build time.
- Responsive widget coverage includes phone, tablet portrait/landscape and desktop Web viewports.
- Unit tests cover the approval gate, secure key storage failure cases, approved manifest structure, and child demo interactions.

## Not yet field-ready

- The repository does not contain the study team's approved 270 real-word + 270 non-word package. The uploaded non-word workbook has 270 structurally audited candidates, but all remain pending native Kannada review; Suganya's written approval is absent.
- The requirements document says the session schedule is to be finalised after discussion. The exact practice-item sourcing, trial ordering, timeout/no-response behavior, and reward treatment need written confirmation.
- SQLCipher APIs are not yet wired to the assessor/child screen workflow. Flutter Web has no browser-local participant-data adapter yet. The current Web preview is an offline shell and must not be used to collect participant data.
- `flutter_tts` is available for device Kannada speech preview on Web and Android, but this is not the approved locally bundled recording. No approved Kannada audio recordings or bundled Kannada font have been added; device-level conjunct rendering and audio review are open. Do not synthesize or substitute a voice recording: the study team must approve the native Kannada instruction script and recordings. Scored stimuli remain silent unless the PI explicitly approves a protocol change.
- Supervisor PIN provisioning, export implementation/CSV dictionary/audit, backup/restore and retention process remain incomplete.
- The Android host scaffold is generated from pinned Flutter 3.47.9 at build time and hardened in CI; it is not yet committed as a stable native platform tree. The generated scaffold is uploaded as a short-lived CI artifact for inspection.
- No production signing keystore or signed release APK exists in protected GitHub secrets. The current app ID and the institution-owned signing identity also require written confirmation. The ARM64 debug APK is a signed engineering artifact, not a field release.
- No actual device acceptance is recorded: model, Android version, landscape/full-screen, screen-awake behavior, cold offline launch, SQLCipher/Keystore, audio, timing, Unicode, power loss and Play update tests.
- The release gate remains closed. The browser preview and synthetic debug APK are not approved for participants.

## Build status

CI performs dependency resolution, Android host generation/hardening, shell and Vercel configuration validation, Dart formatting, static analysis, unit/widget tests, ARM64 Android debug and release-mode builds, APK ABI/signature/checksum verification, and Flutter Web release build. The latest run must be checked on PR #2; do not rely on previous run results after source changes.

## Update behavior

- A refreshed/reopened Flutter Web preview can receive the latest Vercel deployment; an already running tab is not hot-replaced.
- Vercel does not update an installed APK.
- Android release code exposes **Refresh updates** only from the idle assessor home screen. It checks Google Play on demand; high-priority releases use the immediate flow and normal releases use the flexible flow. Sideloaded APKs cannot use Play In-App Updates. No Play Console track, signing key or device policy is configured yet.
- See `docs/security-audit.md` for the current controls, CI evidence and remaining blockers.

**Current state: hardened engineering preview, not a production research instrument.**
