# PadLab architecture

## Product decision

The field product is a native Flutter/Dart Android application for assessor-operated tablets. It must function without Wi-Fi or mobile data and retain research records inside the application's private encrypted storage.

The Flutter Web target is a read-only browser review of the same application screens, hosted on Vercel. It must not accept participant identifiers or collect research records. The earlier Next.js/PWA code is preserved on the archive branch and is not part of the active Flutter source tree.

## Application structure

```
Flutter / Dart application
├── App shell and responsive navigation
│   ├── Assessment workspace
│   └── Settings and item-bank review
├── Assessor workflow
│   ├── participant identity and session selection
│   ├── session history and resume
│   └── summary and protected export
├── Child assessment experience
│   ├── approved Kannada recorded instructions
│   ├── practice presentation
│   ├── fixed scored-trial presentation
│   └── protocol-approved progress/reward behavior
├── Assessment domain
│   ├── protocol and release verification
│   ├── immutable session allocation manifest
│   ├── response and correctness rules
│   ├── monotonic reaction-time capture
│   └── session metrics
├── Data boundary
│   ├── application repositories
│   ├── SQLCipher in private Android storage
│   ├── migrations and transactions
│   └── append-only export audit
└── Bundled assets
    ├── supplied 270-word source list
    ├── approved 270 non-word list after review
    ├── signed session allocations
    ├── approved Kannada instruction recordings
    └── bundled Kannada font and licensed visual assets

Flutter Web review build
└── same presentation system
    ├── bundled source-word and review metadata
    ├── read-only browser interface
    └── no participant identifier or record storage
```

## Separation of responsibilities

- **Views** render the assessor and child experiences; they do not allocate stimuli, calculate scores or execute SQL.
- **Controllers/view models** coordinate actions and expose state.
- **Domain services** enforce the approved protocol, trial transitions, scoring and reaction-time rules.
- **Repositories** are the only application-facing path to persisted study data.
- **SQLCipher services** own schema, migrations, transactions and integrity constraints on Android.
- **Platform adapters** own recorded audio, screen-awake/fullscreen behavior, file creation and Android share-sheet interactions.
- **Approval verifier** validates a signed, versioned study package before the participant workflow can be enabled.

## Trial lifecycle

1. Load the immutable session manifest and restore the exact next ordinal.
2. Persist the stimulus-presented event before enabling response controls.
3. Start a monotonic stopwatch when the stimulus is presented.
4. Capture the configured response and stop the monotonic timer.
5. Calculate reaction time in milliseconds; use wall-clock timestamps only for audit chronology.
6. Persist response, correctness, reaction time and the session cursor in one awaited database transaction.
7. Advance only after the transaction succeeds. On write failure, preserve the current stimulus and show an assessor-safe recovery state.

No-response timeout, repeat/restart and reward behavior must follow the signed protocol; the application must not infer those rules.

## Item-bank integrity

- The supplied real-word CSV is included unchanged and validated as 270 unique words.
- W001–W270 are assigned in source order for stable internal references.
- The 270 non-word candidates remain Pending until native Kannada review and written approval.
- The final item bank must carry an immutable version, SHA-256 checksum, approval references and reviewed item content.
- Each participant session stores a frozen ordered trial manifest. Resume must never reshuffle its order.

## Data protection

- Android assessment data remains in private application storage protected by SQLCipher.
- Database keys are stored using Android secure storage/Keystore integration.
- No participant sync, analytics, crash telemetry or remote research API is configured.
- Browser review is read-only and must not contain participant records.
- CSV exports must use the signed data dictionary, UTF-8 BOM and formula-injection-safe cell encoding; names are excluded by default.

## Deployment boundary

- GitHub Actions validates Flutter, builds the Android review artifact and builds the Flutter Web output.
- Vercel hosts the static Flutter Web review target.
- The signed ARM64 Android APK is built through the protected release workflow and distributed through the study-approved channel.
- Web deployment never updates an already installed APK.
