# Padalab architecture

## Product decision

**The field product is a native Flutter/Dart Android application.** The repository root is the canonical Flutter project. The application is designed for assessor-operated tablets and must continue to work with Wi-Fi and mobile data disabled.

A Flutter Web build is maintained only to review the same UI in a browser. It is not the field product and must not be used to collect participant data. The former Next.js/PWA prototype is preserved on the archive branch `archive/nextjs-prototype-before-flutter-root`; it is removed from the active application tree and deployment workflow.

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
    │   └── progress and protocol-approved rewards
    ├── Assessment domain
    │   ├── protocol configuration and approval gates
    │   ├── immutable session allocation manifest
    │   ├── response and correctness rules
    │   ├── monotonic reaction-time capture
    │   └── session metrics
    ├── Data layer
    │   ├── repositories (single application data boundary)
    │   ├── SQLite in private Android app storage
    │   ├── schema migrations and transactions
    │   └── append-only export audit
    └── Bundled assets
        ├── approved/versioned item bank
        ├── recorded Kannada audio
        ├── Kannada font
        └── licensed visual assets

Browser review build
└── Flutter Web static output
    ├── same presentation layer
    ├── synthetic/demo-only content
    └── no participant workflows or field data
```

## Separation of responsibilities

- **Views** render assessor and child experiences; they do not choose stimuli, calculate scores or write raw SQL.
- **Controllers/view models** coordinate actions and expose state to views.
- **Domain services** enforce session rules, trial transitions, scoring, reaction time and summary calculations.
- **Repositories** are the only application-facing path to stored data.
- **SQLite services** own SQL, schema migrations, transactions and integrity constraints on Android.
- **Platform adapters** own audio, screen-awake/full-screen behavior, file creation and Android share-sheet interactions.

## Critical trial lifecycle

1. Restore the exact session manifest and next trial from SQLite.
2. Record a wall-clock timestamp with local UTC offset for the export record.
3. Start a monotonic stopwatch when the stimulus becomes visible.
4. Accept only the configured response controls; distinguish wrong answers from no response.
5. Stop the monotonic clock on the accepted touch and calculate RT in milliseconds.
6. Commit response, correctness, RT, timestamps and progress in one awaited database transaction.
7. Advance only after that transaction succeeds. On write failure, preserve the current stimulus and show an assessor-safe recovery state.

Wall-clock time is for audit chronology; it must not calculate elapsed reaction time. A monotonic clock avoids clock adjustments changing the measured duration.

## Session and item-bank integrity

- Session order must be generated once, approved, versioned and persisted before administration.
- Resume restores the persisted order; it never re-shuffles.
- Every session stores protocol version, item-bank version/hash and app version.
- The packaged item bank is read-only at runtime.
- No non-word candidates are packaged until native Kannada review and written study approval are complete.
- A bank change creates a new version and controlled app release; it must not mutate existing session records.

## Local data and export

SQLite in private Android app storage is the source of truth during field use. There is no API client, cloud database, background sync, analytics, crash reporting or remote logging in the field app.

Trial and session CSV files must use the approved field dictionary, preserve Kannada via UTF-8 with BOM, exclude child names by default, include all local records, be non-destructive and be audited locally.

The browser preview is static UI review only. It is not a second source of research data and must not be extended with a browser database merely to simulate field storage.

## Android presentation constraints

- Target Android 8.0 (API 26) or newer; exact target tablet must be confirmed.
- Landscape-only assessment UI.
- Immersive/full-screen mode and screen-awake behavior only while a child session is active.
- Responsive assessor layouts for supported screen sizes and safe areas. Phone portrait is a preview/responsiveness target, not a substitute for tablet landscape protocol.
- Kannada shaping must be checked on-device for `ಕ್ಷ`, `ಸ್ತ್ರೀ`, `ಗ್ಗ` and `ಜ್ಞಾ`.

## Build and deployment

- GitHub Actions is canonical for Flutter formatting, static analysis, unit/widget tests, Android debug builds and Flutter Web preview builds.
- Vercel hosts only the static Flutter Web review bundle from `build/web`.
- Device-level integration tests must run on an emulator and the actual field tablet.
- Release signing is separate from debug builds. Keystore material is stored outside the repository and injected only through protected release secrets.
- The signed APK and installation guide are the field deliverables.

## Protocol gates

The formal requirements document and later working-allocation proposal differ. The application must not resolve those differences by guessing. The PI/statistician must confirm the item counts, session structure, practice interpretation, reward cadence, timeout/no-response handling, repeat/resume policy, ID formats, audio script and data-retention rules before the protocol is frozen.

## Quality strategy

- **Unit tests:** protocol arithmetic, item-bank validation, deterministic manifest generation, response validation, scoring, RT boundaries and summary statistics.
- **Database tests:** migrations, constraints, transaction rollback, duplicate prevention, immediate persistence, resume/restart and export queries.
- **Widget tests:** assessor entry, validation messages, child controls, responsive sizing, accessibility semantics and error states.
- **Integration tests:** complete practice/test flows, app lifecycle interruption, cold launch, audio, local storage and exports.
- **Device acceptance:** offline cold launch, landscape/full-screen, screen awake, Kannada glyph shaping, touch responsiveness, battery/power recovery, Downloads and share-sheet on the actual tablet.
