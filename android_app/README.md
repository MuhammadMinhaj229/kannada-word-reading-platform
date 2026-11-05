# ಪದLab Android

Flutter/Dart implementation track for the PHFI Kannada Word Reading Assessment. The Android deliverable is a native, offline-first tablet APK. The Next.js PWA at the repository root is retained as a design/reference prototype and Vercel preview; it is not the field application.

## Current status

**Foundation preview only — not approved for participant use.**

The current Flutter branch contains an initial app shell, assessor-to-child preview navigation, a provisional session allocator, a first SQLite schema, trial serialization and a GitHub Actions Android quality workflow.

It does not yet contain a live assessment engine, persisted child/session workflow, participant trials, approved item-bank assets, Kannada audio, final reports/exports, supervisor PIN flow, or signed release APK.

## Source and protocol status

The requirements DOCX specifies a 270-real-word + 270-non-word pool, six sessions of 90 presentations (5 practice + 85 test), a 10-second item display, Kannada recorded instructions, and a coin reward after every 10 answers.

The latest uploaded files audited on 5 November 2026 contain:
- 270 unique real-word entries.
- 270 unique non-word candidates in `nonwords_v1.xlsm`.
- Non-word method distribution: A_vowel 68, B_consonant 68, C_suffix_prefix 67, D_prefix_suffix 67.
- All 270 non-word candidates are marked `Pending` review; reviewer notes are blank. No candidate is approved for app use.
- 270 source-word IDs and references are structurally present. These checks do not establish Kannada lexical validity.

A separate 194-non-word / 45-real + 32-nonword / 77-scored-items-per-session allocation was discussed as a working proposal. It conflicts with the formal requirements document and is not approved. The Flutter constants and allocator currently represent that proposal for isolated engineering tests only; they must not be used to administer an assessment or load stimuli until the study team confirms the protocol in writing.

See [the working allocation note](../docs/protocol/working-allocation-v1.md) and [the architecture decision](../docs/architecture.md).

## Technical baseline

- Flutter/Dart Android app; Android 8.0 (API 26) or newer.
- Landscape orientation; immersive child assessment; screen kept awake only while a session is active.
- SQLite in private app storage. No server, cloud sync, analytics, remote logging or crash telemetry.
- Approved, versioned item bank and pre-recorded Kannada audio bundled locally only after written approval.
- Kannada font bundled and tested against the required conjuncts on the actual field tablet.
- Signed release APK; the signing keystore must never be committed to Git.
- Vercel remains for the existing PWA preview and does not produce the Flutter APK.

## Local development

Install the Flutter stable SDK and Android SDK (Android Studio is recommended). The Android host project is generated in CI from the pinned Flutter toolchain.

From this directory:

```bash
flutter create . --platforms=android --org org.phfi.cdlr --project-name padalab_android --no-pub
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test --reporter expanded
flutter run
```

## Project structure

```
lib/
  app/                 App composition, navigation and design system
  core/config/         Provisional protocol constants and build configuration
  data/database/       Local SQLite schema and migrations
  features/
    assessor/          Participant entry and assessor workflow
    child/             Child-facing experience
    assessment/
      domain/          Items, trial records, allocation and assessment rules

test/                  Unit and widget tests
```

## Research and data safeguards

- Do not use this preview with children.
- Do not bundle candidate non-words until native Kannada review and written study approval are recorded.
- Do not place participant data, names, exports, approved bank files, audio recordings or signing keys in Git.
- Do not use browser speech synthesis or network-hosted audio for field sessions.
- Persist each response before moving to the next stimulus. A failed write must keep the current item visible.
- Resume must restore the stored trial sequence; it must never re-randomise an interrupted session.
- Export must be non-destructive and include all on-device records; names are excluded by default.
- CI success is not evidence of offline, reaction-time, audio, data-integrity or field-pilot readiness.

## Next milestones

1. Resolve protocol differences with the PI/statistician and document the approved schedule, practice/test counts, reward rule, timeout and no-response handling.
2. Finish persistent child/session registration, immutable session allocations, recovery and database migrations.
3. Implement trial state machine, monotonic reaction-time capture and write-before-next-stimulus semantics.
4. Integrate approved Kannada text/audio, font assets, visual assets and rewards.
5. Build session summaries, daily/child reports, UTF-8-BOM CSV exports, Downloads/share-sheet flow and PIN protection.
6. Add automated integration and device-level offline testing; verify on the actual tablet.
7. Create a signed release APK, installation guide and field-pilot checklist after approval.
