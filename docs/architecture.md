# Padalab architecture

## Product decision

**The field product is a native Flutter/Dart Android application.** It is designed for assessor-operated tablets and must continue to work with Wi-Fi and mobile data switched off.

The existing Next.js PWA remains in the repository as a design and behaviour reference. Vercel previews that web prototype; Vercel deployment status is not evidence that the Android app has compiled, installed or passed tablet acceptance testing.

## Runtime architecture

```text
Signed Android APK
└── Flutter application
    ├── Assessor workspace
    │   ├── child identification and history
    │   ├── assessor identity
    │   ├── session selection / resume / restart
    │   └── reports and protected export
    ├── Child assessment experience
    │   ├── Kannada instructions and bundled audio
    │   ├── practice flow
    │   ├── fixed scored-trial presentation
    │   └── progress and approved rewards
    ├── Assessment domain
    │   ├── protocol configuration and gates
    │   ├── immutable session allocation manifest
    │   ├── response and correctness rules
    │   ├── monotonic reaction-time capture
    │   └── session metrics
    ├── Data layer
    │   ├── repositories (single application data boundary)
    │   ├── SQLite in private app storage
    │   ├── schema migrations and transactions
    │   └── append-only export audit
    └── Bundled assets
        ├── approved/versioned item bank
        ├── recorded Kannada audio
        ├── Kannada font
        └── licensed visual assets
```

## Separation of responsibilities

- **Views** render assessor and child experiences; they do not choose stimuli, calculate scores or write raw SQL.
- **View models/controllers** coordinate user actions and expose state to views.
- **Domain services** enforce session rules, trial transitions, scoring, reaction time and summary calculations.
- **Repositories** are the only application-facing path to stored data.
- **SQLite services** own SQL, schema migrations, transactions and integrity constraints.
- **Platform adapters** own audio, screen-awake/full-screen behaviour, file creation and Android share-sheet interactions.

This separation keeps the assessment rules independent of presentation and persistence details. It also lets unit tests exercise the scoring and trial logic without launching the UI.

## Critical trial lifecycle

1. Restore the exact session manifest and next trial from SQLite.
2. Record a wall-clock timestamp with local UTC offset for the export record.
3. Start a monotonic stopwatch at the moment the stimulus becomes visible.
4. Accept only the configured response controls; distinguish a wrong answer from no response.
5. Stop the monotonic clock on the accepted touch and calculate RT in milliseconds.
6. Commit the response, correctness, RT, timestamps and updated progress in one awaited database transaction.
7. Advance only after the transaction succeeds. On a write error, preserve the current stimulus and show an assessor-safe recovery state.

Wall-clock time is for audit chronology; it must not be used to calculate elapsed reaction time. A monotonic clock avoids clock adjustments changing the measured duration.

## Session and item-bank integrity

- Session order must be generated once, approved, versioned and persisted before administration.
- Resume restores the persisted order; it never shuffles again.
- Every session stores protocol version, item-bank version/hash and app version.
- The packaged item bank is read-only at runtime.
- No non-word candidates are packaged until native Kannada review and written approval are complete.
- A bank change creates a new version and requires a controlled app release; it must not mutate existing session records.

## Local data and export

SQLite in the app's private directory is the sole source of truth during field use. There is no API client, cloud database, background sync, analytics, crash-reporting or remote logging in this release.

Trial and session CSV files must:
- use the approved field dictionary;
- preserve Kannada via UTF-8 with BOM;
- exclude child names by default;
- include all local records, not only the current child/session;
- be non-destructive and audited locally;
- be saved through Android's supported document/storage flow and shared by the native Android share sheet.

The two export files remain the specified raw-data deliverables. Additional child-level or daily summaries are derived reports and must not replace them.

## Android presentation constraints

- Target Android 8.0 (API 26) or newer; actual target tablet must be confirmed.
- Landscape-only assessment UI as required by the study.
- Immersive/full-screen mode and screen-awake behaviour only while a child session is active.
- Responsive assessor layouts for supported screen sizes and safe areas. Phone portrait support is not a substitute for the tablet landscape protocol.
- Kannada shaping must be checked on-device for `ಕ್ಷ`, `ಸ್ತ್ರೀ`, `ಗ್ಗ` and `ಜ್ಞಾ`.

## Build and deployment

- GitHub Actions is the canonical place for Flutter formatting, static analysis, unit/widget tests and Android debug builds.
- Device-level integration tests must run on an emulator and the actual field tablet.
- Release signing is separate from debug builds. Keystore material is stored outside the repository and only injected through protected release secrets.
- The signed APK and installation guide are the field deliverables.
- Vercel is used only for the existing PWA/reference preview and documentation site; it is not the Android release pipeline.

## Protocol gates

The formal requirements document and the later working-allocation proposal differ. The application must not resolve those differences by guessing. The PI/statistician must confirm the item counts, session structure, practice interpretation, reward cadence, timeout/no-response handling, repeat/resume policy, ID formats, audio script and data-retention rules before the protocol is frozen.

## Quality strategy

- **Unit tests:** protocol arithmetic, item-bank validation, deterministic manifest generation, response validation, scoring, RT boundaries and summary statistics.
- **Database tests:** migrations, constraints, transaction rollback, duplicate prevention, immediate persistence, resume/restart and export queries.
- **Widget tests:** assessor entry, validation messages, child controls, responsive sizing, accessibility semantics and error states.
- **Integration tests:** complete practice/test flows, app lifecycle interruption, cold launch, audio playback, local storage and exports.
- **Device acceptance:** offline cold launch, landscape/full-screen, screen awake, Kannada glyph shaping, touch responsiveness, battery/power recovery, Downloads and share-sheet on the actual tablet.
