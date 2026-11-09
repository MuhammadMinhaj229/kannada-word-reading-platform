# ಪದLab — Kannada Word Reading Assessment

**Application:** Flutter / Dart  
**Field target:** offline-first Android tablets  
**Browser target:** read-only review build on Vercel  
**Current branch:** `main`  
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

The Flutter application and production-readiness fixes are merged into `main`. Latest main commit: `594c84ca535cf3c25277bf1dc0d5ecb9ea2b59cf` (PR #11 merged 9 November 2026). PR #11 hardens trial persistence, item-bank validation, release authorization and the signed Android release workflow. The earlier main CI run #42473020877 passed formatting, static analysis, all 65 unit/widget tests, ARM64 Android debug build, Flutter Web build, metadata checks and artifact verification. The merged PR #11 adds further validation and fail-closed database authorization. The Vercel production deployment from this exact commit reached `READY`; canonical review URL: https://kannada-word-reading-platform.vercel.app/. The deployed `app-release.json` is labelled `engineering-preview`, with `participantReady: false` and `participantDataSync: false`. The Vercel browser build is a no-index, read-only review surface and must not be used for participant data entry. The stable GitHub prerelease [padalab-preview](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/tag/padalab-preview) publishes a debug-signed ARM64 APK and SHA-256 checksum for engineering review only, not field use. Feature-branch previews may still be generated for controlled review. The service-worker cache identity is derived from both asset paths and file contents.

## Web offline mode and Android APK download

The Flutter Web review build is installable as a PWA and precaches the Flutter shell and bundled assets after its first successful online load. Its **Refresh app** control checks for a new deployment only when clicked; it does not use a timer or repeatedly reload the page. The **Download Android APK** control opens the stable engineering-preview release below.

[Download the latest ARM64 Android preview APK](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/download/padalab-preview/padalab-android-arm64-debug.apk)

The APK is debug-signed and for engineering review only, not participant field use. Android and Web are built from the same Flutter source commit and contain the same UI and bundled content. Android storage and device services are native; participant data remains local and is not synchronised to Vercel or GitHub. Web refresh updates Web assets only. Android in-app updates use Google Play and require a Play-installed build.

## Android APK distribution

The current native target is Android 8.0 (API 26) or later on ARM64 (`arm64-v8a`) tablets. Device compatibility must be confirmed on the actual study tablet; a single APK cannot be guaranteed on every vendor, architecture or Android release.

The signed release workflow is `.github/workflows/release-apk.yml`. It requires these protected repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

Create a reviewed tag such as `padalab-v0.1.0` to publish a signed APK and SHA-256 checksum. The workflow never uploads the keystore or `android/key.properties`. Debug APKs from the validation workflow are for engineering review, not field distribution.

See [Android installation and compatibility](docs/android-installation.md).

## Research protocol status — awaiting written sign-off

The current `StudyProtocol` constants mirror one interpretation of the 2 Nov 2026 requirements: six sessions, 90 total presentations per session (five practice + 85 test), a 10-second stimulus display and a reward interval every ten answers. These constants are a requirements transcription, **not evidence of PI/statistician approval**.

The repository also records a conflicting 90-scored-trial interpretation (45 real words + 45 non-words per block) and an older 77-scored-trial proposal (45 real + 32 non-words, plus five provisional practice items). The reward interval also appears as every five completed scored trials in an earlier decision note. No interpretation has been selected as final.

Do not change the trial engine, generate frozen session allocations or administer the task until the PI/statistician resolves the conflicts in writing. The decision register and sign-off checklist are in [protocol decisions](docs/protocol-decisions.md). The participant workflow remains disabled.
 
## Kannada instruction audio

The application uses bundled, offline recordings only. Device text-to-speech is not used as a participant fallback. The supplied 12-minute source recording has not yet been transcribed, segmented into the required instruction clips and linked to a written PHFI/CDLR approval reference. The app's audio manifest therefore remains closed until approved clips are added and validated on the target tablet.

See [audio asset requirements](assets/audio/README.md).

## Current engineering status

Implemented on this branch: Flutter application shell, responsive navigation, supplied real-word asset and parser, non-word method/review summary, offline audio player service and approval manifest, SQLCipher/database foundations, responsive layout tests, Web service-worker content fingerprinting, and protected signed-APK workflow.

Not yet complete: production assessor/session UI wiring to SQLCipher, the participant child-trial workflow and recovery, session history and repeat authorization, the PI-approved item bank/allocation manifest, approved Kannada audio clips, protected export/REDCap mapping, tablet integration/acceptance and institution signing-key provisioning. The separate Task preview is a synthetic QA simulation only; it now invalidates timing on app lifecycle or tab interruption and starts the timer after the stimulus has rendered.

**The participant release gate intentionally remains closed.** Passing CI or building an APK does not establish ethics approval, linguistic validity, audio approval, data-integrity acceptance or field readiness.


## Child task QA simulation

The assessor workspace includes a **Task preview** screen for testing the child-facing Word / Non-word interaction. It runs five practice cards and ten scored QA cards using synthetic placeholder strings, records responses and reaction times only in memory, and exposes the QA key only in the separate assessor results view. It does not use the approved item bank or write participant records. This is an interface/engineering simulation, not a validated study task. See [QA simulation instructions](docs/qa-simulation.md).

The simulation does not change the participant release gate or resolve the outstanding PI/statistician protocol decisions.
