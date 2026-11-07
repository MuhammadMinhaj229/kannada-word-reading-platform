# ಪದLab — Kannada Word Reading Assessment

**Application:** Flutter / Dart  
**Field target:** offline-first Android tablets  
**Browser target:** read-only review build on Vercel  
**Current branch:** `feat/flutter-android-foundation`  
**Release state:** engineering candidate; participant release gate remains closed

## Product architecture

PadLab has one Flutter application codebase. Android and Web are separate build targets from the same source commit.

| Target | Intended role | Data boundary |
|---|---|---|
| Android APK | Assessor-operated field application | Encrypted SQLite in private device storage |
| Flutter Web | Interface and bundled-content review on Vercel | Read-only; no participant identifiers or records |

The browser build is not a participant data-collection target. Vercel serves the Flutter Web output; GitHub Actions builds the Android package. No cloud database, remote participant API, analytics or telemetry service is part of the current architecture.

## Supplied study content

### Real Kannada word list

The supplied `assets/item_bank/selected_words_list_v1.csv` is bundled unchanged. It contains 270 unique real Kannada word entries and the associated source metadata:

- Kannada word and transcription
- Meaning and part of speech
- Age band and mean age of acquisition
- Syllable, phoneme and morpheme counts
- Akshara type

The application assigns stable internal IDs `W001` through `W270` in the supplied source order. The asset parser rejects missing columns, duplicate words or a row count other than 270.

### Non-word candidates

The supplied workbook contains 270 candidates with the requested construction proportions:

| Method | Count |
|---|---:|
| A — Vowel replacement | 68 |
| B — Consonant replacement | 68 |
| C — Suffix + prefix blend | 67 |
| D — Prefix + suffix blend | 67 |
| **Total** | **270** |

The source workbook marks all 270 candidates as Pending. The app stores the method counts and review state in `assets/item_bank/nonword_candidate_summary_v1.json`; pending candidates are not loaded as usable assessment stimuli. Written native Kannada review and study-team approval are required before these items enter a signed item bank.

## Repository layout

```
lib/
  app/                 App composition and design system
  core/                Protocol, audio, security and update services
  data/                Encrypted Android persistence boundary
  features/
    assessment/        Item catalog, allocation and trial domain
    assessor/          Assessor workspace and settings
assets/
  item_bank/           Supplied real words and non-word review summary
  audio/               Approved offline recording manifest
test/                  Unit, widget and responsive-layout coverage
docs/                  Architecture, approvals, privacy and release checks
scripts/deploy/        Pinned Flutter SDK and platform setup
.github/workflows/     CI, Web validation and signed APK release
vercel.json            Static Flutter Web hosting and security headers
```

## Local development

Install Flutter stable **3.47.9**, Java 17 and the Android SDK.

```bash
flutter create . --platforms=android,web --org org.phfi.cdlr --project-name padalab_android --no-pub
bash scripts/deploy/configure_android_project.sh
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter run
```

The normal application entry point is the assessor workspace. There is no build flag that switches the application into a synthetic assessment flow.

Run the browser review target with:

```bash
flutter run -d chrome
```

Build the Vercel review output with:

```bash
flutter build web --release --base-href /
bash scripts/deploy/configure_flutter_web.sh build/web
```

## Vercel deployment

- Root directory: repository root
- Framework preset: none
- Install command: `bash scripts/deploy/install_flutter.sh`
- Build command: `bash scripts/deploy/build_flutter_web.sh`
- Output directory: `build/web`
- Flutter SDK: pinned in `.flutter-version`

Feature-branch pushes create Vercel previews. The configured production branch remains `main`; the Flutter migration is still under PR #2 and has not been promoted to production. The service-worker cache identity is derived from both asset paths and file contents. The web build is no-index and does not accept participant details.

## Android APK distribution

The current native target is Android 8.0 (API 26) or later on ARM64 (`arm64-v8a`) tablets. Device compatibility must be confirmed on the actual study tablet; a single APK cannot be guaranteed on every vendor, architecture or Android release.

The signed release workflow is `.github/workflows/release-apk.yml`. It requires these protected repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

Create a reviewed tag such as `padalab-v0.1.0` to publish a signed APK and SHA-256 checksum. The workflow never uploads the keystore or `android/key.properties`. Debug APKs from the validation workflow are for engineering review, not field distribution.

See [Android installation and compatibility](docs/android-installation.md).

## Research protocol baseline

The requirements baseline records:

- 270 real words and 270 non-word candidates
- Six sessions
- 90 presentations per session: five practice and 85 test
- Ten-second stimulus display
- Reward interval specified as every ten answers

The source requirements say the visit schedule must be finalised with the study team. The final allocation/order, timeout/no-response rule, practice-item sourcing, reward behavior, repeat/restart rules and same-day policy must be approved in writing. The application must not infer these rules.

## Kannada instruction audio

The application uses bundled, offline recordings only. Device text-to-speech is not used as a participant fallback. The supplied 12-minute source recording has not yet been transcribed, segmented into the required instruction clips and linked to a written PHFI/CDLR approval reference. The app's audio manifest therefore remains closed until approved clips are added and validated on the target tablet.

See [audio asset requirements](assets/audio/README.md).

## Current engineering status

Implemented on this branch: Flutter application shell, responsive navigation, supplied real-word asset and parser, non-word method/review summary, offline audio player service and approval manifest, SQLCipher/database foundations, responsive layout tests, Web service-worker content fingerprinting, and protected signed-APK workflow.

Not yet complete: assessor/session UI wiring to SQLCipher, child trial presentation and recovery, session history and repeat authorization, approved 540-item bank/allocation manifest, approved Kannada audio clips, protected export/REDCap mapping, tablet integration/acceptance and institution signing-key provisioning.

**The participant release gate intentionally remains closed.** Passing CI or building an APK does not establish ethics approval, linguistic validity, audio approval, data-integrity acceptance or field readiness.
