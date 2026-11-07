# Repository status — 7 November 2026

## Active application

- Flutter/Dart under `lib/` is the single application codebase.
- Android is the intended offline field target; Web is a synthetic-data browser review target only.
- The former Next.js implementation remains preserved on `archive/nextjs-prototype-before-flutter-root`.
- Native Android is generated in CI using the pinned Flutter SDK and hardened by `scripts/deploy/configure_android_project.sh`; the Android/Web host directories are not yet committed to the repository.
- Vercel is the only Web host. The public production branch remains `main`; the Flutter migration is still draft PR #2.

## Implemented engineering work

- Explicit build-time demo mode. Normal and release builds default to a participant-safe locked assessor screen; only review builds pass `PADALAB_DEMO_MODE=true`.
- Four-step synthetic child interaction demo remains available in Web preview and debug APK only.
- Formal requirements baseline is encoded as six sessions, 90 presentations/session, 5 practice + 85 test, 270 real-word + 270 non-word pool, 10-second stimulus display and reward interval of 10 answers.
- Removed the unapproved 45-real + 32-non-word random allocator. Runtime now accepts only a frozen 90-trial session manifest with written protocol/allocation references and a bank checksum.
- Fail-closed release gate lists missing approvals, item-bank review, assets, ethics/data governance, recovery/repeat rules, device acceptance, export schema, supervisor credential and signed release.
- SQLCipher database and Android secure-storage key provider foundation. A missing key for an existing encrypted database causes a hard failure; legacy plaintext database detection preserves the file and refuses to silently migrate it. Key/database initialization is single-flight to avoid concurrent creation races.
- Session schema stores an immutable trial manifest. API foundations create a session transactionally, persist a presented-trial event, verify the full item content against the frozen manifest, compute correctness from the frozen item, and commit response plus session-cursor advancement atomically. Host SQLite FFI tests cover schema/foreign keys, concurrent opens, legacy DB preservation, key-loss handling, tamper rejection and response/cursor atomicity.
- Android hardening script applies API 26 minimum, landscape orientation, Internet permission for Play updates, disables Android backup and cleartext traffic, configures R8 release shrinking and SQLCipher keep rules, and creates machine-local Flutter SDK properties at build time.
- Responsive widget coverage includes phone, tablet portrait/landscape and desktop Web viewports.
- Unit tests cover the approval gate, secure key storage failure cases, approved manifest structure, and child demo interactions.

## Not yet field-ready

- The repository does not contain the study team's approved 270 real-word + 270 non-word package. The uploaded non-word workbook has 270 structurally audited candidates, but all remain pending native Kannada review; Suganya's written approval is absent.
- The requirements document says the session schedule is to be finalised after discussion. The exact practice-item sourcing, trial ordering, timeout/no-response behavior, and reward treatment need written confirmation.
- SQLCipher APIs are not yet wired to the assessor/child screen workflow. Integration tests for real database transactions, interruption recovery and failed-write behavior remain to be completed on Android.
- No approved Kannada audio recordings or bundled Kannada font have been added; device-level conjunct rendering and audio review are open.
- Supervisor PIN provisioning, export implementation/CSV dictionary/audit, backup/restore and retention process remain incomplete.
- The Android host scaffold is generated from pinned Flutter 3.47.9 at build time and hardened in CI; it is not yet committed as a stable native platform tree. The generated scaffold is uploaded as a short-lived CI artifact for inspection.
- No production signing keystore or signed release APK exists in protected GitHub secrets. The current app ID and the institution-owned signing identity also require written confirmation.
- No actual device acceptance is recorded: model, Android version, landscape/full-screen, screen-awake behavior, cold offline launch, SQLCipher/Keystore, audio, timing, Unicode, power loss and Play update tests.
- The release gate remains closed. The browser preview and synthetic debug APK are not approved for participants.

## Build status

CI performs dependency resolution, Android host generation/hardening, Dart formatting, static analysis, unit/widget tests, Android debug build, a release-mode safety build and Flutter Web release build. The latest run must be checked on PR #2; do not rely on previous run results after source changes.

## Update behavior

- A refreshed/reopened Flutter Web preview can receive the latest Vercel deployment; an already running tab is not hot-replaced.
- Vercel does not update an installed APK.
- Android release code includes a guarded Google Play in-app update coordinator for Play-installed release builds. It skips debug and Web; high-priority Play updates use the immediate flow, while normal updates use the flexible flow. Managed Google Play/device policy is still required for automatic updates on field tablets. No Play Console track or device policy is configured yet.

**Current state: hardened engineering preview, not a production research instrument.**
