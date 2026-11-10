# ಪದLab — Kannada Word Reading Assessment

**Application:** Flutter / Dart  
**Online target:** interactive Flutter workspace on Vercel  
**Offline target:** downloadable Android APK for tablets  
**Current branch:** `main`  
**Release state:** engineering candidate; participant release gate remains closed

## Product architecture

PadLab has one Flutter application codebase. Android and Web are separate build targets from the same source commit.

| Target | Intended role | Data boundary |
|---|---|---|
| Flutter Web | Independent browser application on Vercel | Browser-local, non-sensitive workspace preferences only; no participant identifiers or research records |
| Android APK | Downloadable offline Android application | Intended field platform; encrypted local storage foundations, with participant use locked until approvals and end-to-end acceptance |

Vercel is the working online workspace: users can inspect the bundled Kannada catalogue, review release readiness, configure available settings and run the interactive non-participant Task preview. The Web and Android applications share Flutter UI/domain code but use independent local data stores. The browser stores only non-sensitive workspace preferences; it does not accept or store participant identifiers or research responses. The Android APK is the downloadable offline build from the same Flutter source. It bundles the application and content so the app shell and review features work without a network connection after installation. No cloud database, remote participant API, analytics, telemetry, automatic upload or cross-device synchronization is part of the current architecture.

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
# CI and Vercel builds fail if dependency resolution changes pubspec.lock.
dart format lib test
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter run
```

The normal application entry point is the assessor workspace. There is no build flag that switches the application into a synthetic assessment flow.

Run the online workspace locally with:

```bash
flutter run -d chrome
```

Build the Vercel online workspace with:

```bash
flutter build web --release --base-href /
bash scripts/deploy/configure_flutter_web.sh build/web
```

## Vercel deployment

Vercel is the primary online destination for the interactive Flutter workspace.

- Project: `kannada-word-reading-platform`
- Git repository: `MuhammadMinhaj229/kannada-word-reading-platform`
- Production branch: `main`
- Root directory: repository root
- Framework preset: none
- Install command: `bash scripts/deploy/install_flutter.sh`
- Build command: `bash scripts/deploy/build_flutter_web.sh`
- Output directory: `build/web`
- Flutter SDK: pinned in `.flutter-version`

The live website is [PadLab on Vercel](https://kannada-word-reading-platform.vercel.app/). It is the interactive online workspace for item-bank review, Settings, release-readiness information and the non-participant Task preview. The Flutter Web build is installable as a PWA and caches the application shell and bundled assets after its first successful online load. The user-triggered **Refresh app** control checks for an updated deployment; it does not force-reload an active session.

The website is not the participant data-collection target. Participant identifiers and research responses remain disabled in the browser. The Android APK is the offline tablet build. Keep the Vercel project’s deployment access controls enabled while institutional research approvals are pending.

## Web workspace and offline Android APK

The Vercel website provides the interactive online workspace. It includes the responsive assessor workspace, supplied item catalogue, Settings, release-readiness information and the child-facing non-participant Task preview. The PWA service worker caches the Flutter shell and bundled static assets after the first successful online load. It does not store participant data.

The website header includes **Download offline APK**, which opens the stable ARM64 Android engineering build:

[Download the latest ARM64 offline Android APK](https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/download/padalab-preview/padalab-android-arm64-debug.apk)

The current APK is debug-signed and is for engineering review only; it is not an approved participant field release. After installation, the application shell and bundled content are available offline. Android private storage and native device services are separate from the Vercel website. Web refresh updates the website only; it does not update an installed APK.

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
