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

### Non-word source summary and bundled review subset

The repository contains two distinct non-word artifacts; they must not be treated as the same complete file:

- `assets/item_bank/nonword_candidate_summary_v1.json` records an original workbook summary of **270 candidates**, with a construction-method split of A 68, B 68, C 67 and D 67. Its approved count is zero.
- `assets/item_bank/nonword_candidates_supplied_v1.csv` contains **193 rows** actually bundled for reviewer inspection. Its method split is A 34, B 46, C 65 and D 48. All 193 rows are marked pending native Kannada review.
- The 270-row summary and 193-row CSV do not reconcile: 77 rows in the summary total are not represented in the bundled CSV. The app displays these counts separately rather than claiming the CSV is complete.
- The last row of the bundled CSV is candidate `N270`. Allocation proposal v2 retains it as one unallocated reserve candidate.

These are structural/source-file facts, not linguistic approval. No supplied non-word candidate is approved for use in participant sessions. The 270-item approved non-word pool required by the requirements baseline has not been assembled or signed off.

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

The repository's requirements transcription `KWR-REQ-2026-11-02` specifies six sessions of 90 presentations each (five practice plus 85 test), a 270-real-word plus 270-non-word pool, a 10-second stimulus display and a reward interval every ten answers. These are transcribed requirements, not evidence of PI/statistician approval.

A separate, later engineering allocation proposal v2 records the user-confirmed target of **45 real words + 32 non-words = 77 scored items per session** across six sessions: 270 real words plus 192 non-words = 462 scored items. It uses the first 192 rows in the supplied 193-row review CSV and retains `N270` as one reserve. Practice count/placement, ordering, randomisation and the relationship to the 90-presentation baseline remain unresolved. Proposal v2 is not an approved study protocol or participant manifest.

The repository therefore preserves both records and keeps participant session creation closed. The PI/statistician must reconcile the counts, session/block/visit definitions, practice treatment, timing, reward behavior, no-response rules and allocation method in writing. See [protocol decisions](docs/protocol-decisions.md) and [working allocation proposal v2](docs/protocol/working-allocation-v2.md).

## Kannada instruction audio

The application uses bundled, offline recordings only. Device text-to-speech is not used as a participant fallback. The supplied 12-minute source recording has not yet been transcribed, segmented into the required instruction clips and linked to a written PHFI/CDLR approval reference. The app's audio manifest therefore remains closed until approved clips are added and validated on the target tablet.

See [audio asset requirements](assets/audio/README.md).

## Current engineering status

Implemented: a shared Flutter Web/Android codebase; responsive assessor workspace; 270 real-word catalogue parser; 193-row pending non-word review CSV with source references; 270-row original-workbook summary; the 45+32 engineering allocation proposal; catalogue-backed non-participant Task preview; Android SQLCipher schema and transactional session/trial persistence primitives; secure-key provider; manual Web PWA updates; and a protected signed-APK workflow.

Not yet field-ready: the Android participant/session UI is not wired to the SQLCipher repository; the current approved item-bank model requires 270 approved non-words but none are approved; the study protocol and allocation conflict; practice/scoring/timing/reward/recovery decisions are unresolved; no approved Kannada instruction/word recordings are installed; exports and supervisor authorization are incomplete; target-tablet acceptance is not recorded; and institutional signing/ethics/data-governance evidence is absent.

The browser remains a review/QA surface and stores only its non-sensitive workspace preference. It does not accept participant identifiers or research responses. No cloud participant database, API or synchronization exists under the accepted Option C architecture.

**The participant release gate intentionally remains closed.** A green CI run, ready Vercel deployment or debug-signed APK does not replace research approval, local persistence integration, approved content, field validation or institution-owned signing.

## Child task QA preview

The assessor workspace provides a child-friendly, catalogue-backed Task preview. It uses five supplied real words as practice cards, then ten preview cards alternating supplied real words and pending non-word candidates. It does not record participant identifiers, research responses, reaction times or scores, and it does not reveal correctness. Pending non-words are shown only to exercise the reviewer/QA interface; they are not approved assessment stimuli.

This screen is a non-participant usability preview, not the approved research assessment. See [QA simulation instructions](docs/qa-simulation.md).

## Production readiness

The current deployment is production-ready as a protected online review workspace. The Android build remains a debug-signed engineering preview. Participant/field release is blocked pending the items in [the production-readiness matrix](docs/production-readiness-matrix.md).


## Browser and phone compatibility

The online workspace is responsive and uses the same Flutter application source as the Android build. Automated CI exercises the production Web bundle in:

- **Google Chrome Stable:** desktop browser plus Android Chrome touch/device emulation from 320 to 480 CSS pixels, including landscape.
- **Safari-compatible WebKit:** desktop browser plus iPhone-sized touch/device emulation from 320 to 430 CSS pixels, including landscape.
- **Firefox:** desktop browser with the same narrow-phone, tablet and wide-desktop viewport sweep.
- **Responsive breakpoints:** 320, 360, 390, 430, 480, 600, 768, 860, 900, 1024, 1365 and 1920 CSS pixels.

The checks cover application startup, viewport sizing, horizontal document overflow, JavaScript/console errors, bundled study assets and offline app-shell navigation. Pinch-to-zoom is not disabled. The Playwright WebKit run checks the Safari browser engine; it is not a substitute for testing on a physical iPhone. Browser/device emulation cannot guarantee every handset model, operating-system build, vendor browser, memory limit or network condition.

Flutter's current Web browser support matrix lists Chrome, Safari, Edge and Firefox on mobile and desktop. See the [Flutter Web browser FAQ](https://docs.flutter.dev/platform-integration/web/faq). Before participant field use, complete physical-device acceptance on the institution's actual Android tablet/phones and any iOS devices that will be used. The participant release gate remains closed independently of browser compatibility.
