# ಪದLab — Kannada Word Reading Assessment

**One application codebase:** Flutter/Dart under `lib/`, shared by Android and Web.  
**Primary field target:** offline-first Android tablet application.  
**Web target:** browser-based review of the same Flutter screens, hosted on Vercel.  
**Current maturity:** engineering preview; not approved for participant use.

## What this repository builds

| Target | Purpose | Delivery |
|---|---|---|
| Android | Field assessment on assessor tablets; local SQLite; offline operation | Debug APK in CI; signed release package after release gates |
| Web | Browser review of the same Flutter screens | Vercel branch previews and production deployment from `main` |

The browser preview is not the research instrument. It does not certify Android behavior, SQLite persistence, offline operation, audio, reaction-time accuracy, or tablet compatibility. Never enter participant information in the web preview.

## Repository layout

```
lib/
  app/                 App composition, navigation and design system
  core/                Protocol configuration and platform-independent utilities
  data/                Local persistence boundary (Android SQLite)
  features/
    assessment/        Stimulus, allocation, trial and scoring domain
    assessor/          Assessor workspace and participant workflow
    child/             Child-facing assessment experience
test/                  Unit/widget tests, including responsive viewport coverage
docs/                  Architecture, protocol gates, privacy and release checks
scripts/deploy/        Reproducible Flutter SDK and Web metadata scripts
.github/workflows/     Flutter validation and Android/Web build workflow
vercel.json            Vercel static hosting, routing and response headers
```

The former Next.js/PWA implementation is preserved on branch `archive/nextjs-prototype-before-flutter-root`. It is no longer part of the active application or deployment pipeline.

## Local setup

Install Flutter stable **3.47.9** and the Android SDK. Then run from the repository root:

```bash
flutter create . --platforms=android,web --org org.phfi.cdlr --project-name padalab_android --no-pub
bash scripts/deploy/configure_android_project.sh
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter run
```

To run the browser preview:

```bash
flutter run -d chrome
```

To build both targets:

```bash
flutter build apk --debug --dart-define=PADALAB_DEMO_MODE=true
flutter build apk --release --dart-define=PADALAB_DEMO_MODE=false
flutter build web --release --dart-define=PADALAB_DEMO_MODE=true
bash scripts/deploy/configure_flutter_web.sh build/web
```

The generated Android and Web host directories are created from the pinned Flutter SDK in CI/deployment. Keep platform-specific changes documented and committed deliberately.

## One Flutter codebase and one release path

A push or pull request runs one GitHub Actions workflow: formatting, static analysis, unit/widget tests, an Android debug build and a Flutter Web build. The Vercel Git integration automatically creates a preview deployment for the feature branch. When a reviewed change is merged into `main`, Vercel builds and publishes the production Web deployment.

- CI workflow: `.github/workflows/flutter-android.yml`
- Vercel project settings: `vercel.json`
- Web build script: `scripts/deploy/build_flutter_web.sh`
- Deployment and release policy: `docs/deployment.md`

The Android APK and Web output are different platform packages generated from the same Flutter source commit. This is not a separate React/Next.js website. Vercel hosts the Web build; GitHub Actions builds the Android APK. No Cloudflare credentials or second web host are required. Android release builds include an assessor-controlled **Refresh updates** action that checks Google Play; it works only for packages installed from a configured Play testing/managed track, not sideloaded APKs. See `docs/android-update-policy.md`.

The Web target is for synthetic-data review only. Native SQLite, Android system UI, power management, local persistence and field-device acceptance must be tested on Android tablets. Never enter real participant information in the browser preview.

## Study protocol and item-bank gates

The supplied requirements DOCX specifies 270 real Kannada words + 270 non-words, six sessions, five practice items + 85 test items per session, a 10-second stimulus display, Kannada recorded instruction audio and a gold coin after every 10 answers.

A separate 194-non-word / 45-real + 32-nonword / 77-scored-item proposal was discussed later. It conflicts with the formal requirements document and is not approved. Engineering tests may exercise provisional arithmetic, but these values must not be administered or treated as final until the PI/statistician confirms the protocol in writing.

The latest workbook audit found 270 non-word candidates, all marked Pending. No non-word is approved for use. Native Kannada review and written approval are required before any candidate item is packaged.

See:
- `docs/protocol-decisions.md`
- `docs/protocol/working-allocation-v1.md`
- `docs/architecture.md`

## Data protection and research integrity

- Android assessment data remains in private on-device storage.
- No backend, cloud database, analytics, crash telemetry, or automatic upload is part of the field app.
- Never commit participant data, names, trial exports, item-bank source files, audio recordings, or signing keys.
- Persist each accepted response before advancing to another stimulus.
- Resume must restore the exact frozen trial order; never reshuffle an interrupted session.
- Keep child names out of exports by default.
- CI success is not evidence of ethics approval, linguistic validity, offline readiness or field acceptance.

## Current implementation status

The current branch is a hardened engineering preview: Flutter Android/Web presentation, an explicitly enabled synthetic demo, a fail-closed participant release gate, a checksum-verified 540-item bank model, a frozen-session manifest validator, an encrypted SQLCipher database boundary, Android secure-key storage, transactional trial APIs, host SQLite integration tests, responsive screen tests and a guarded Google Play update coordinator. The persistence APIs are not yet wired to assessor/child screens; no approved stimulus bank or participant session is available in this branch.

Still required: signed PI/statistician protocol and allocation approval, all 270 real-word and 270 non-word source items with Suganya's written Kannada review, bundled approved Kannada font/audio, assessor/session UI and repository integration, supervisor PIN, approved interruption/repeat/timeout policies, session summary, protected CSV export and audit, durable migration/backup/restore procedure, written confirmation of the permanent Android package ID and signing owner, protected release keystore, Play/Managed Play publication, and cold-offline/timing/audio/Unicode/SQLCipher/Keystore acceptance on the actual tablets.

**Do not use this preview with children or for data collection.**
