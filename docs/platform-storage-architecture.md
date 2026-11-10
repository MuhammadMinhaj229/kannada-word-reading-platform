# Platform storage architecture — Option C

**Decision status:** Accepted as the product architecture on 10 November 2026  
**Implementation status:** Partially implemented; browser-local persistence adapter and end-to-end platform integration remain engineering work  
**Scope:** PadLab Flutter Web on Vercel and PadLab Android APK

## Decision

PadLab remains one Flutter/Dart application with two independently operating platform targets. The targets share UI, domain rules, bundled content and validation code, but they do not share a data store and do not synchronize records.

| Concern | Flutter Web | Android |
|---|---|---|
| Hosting/distribution | Vercel static hosting | Downloadable APK; signed institutional release later |
| Local persistence target | Browser-local storage, preferably IndexedDB for structured records | SQLCipher encrypted SQLite in app-private storage |
| Key management | Browser origin/profile boundary; no claim of equivalent protection to Android Keystore | Random SQLCipher key protected by Android Keystore-backed secure storage |
| Network required for normal local work | First visit/update requires network; cached shell/assets can support later launch where browser storage permits | No network required for core assessment operation |
| Data transfer | None | None |
| Cloud database/API | None | None |
| Cross-device sync | Not supported | Not supported |

## Data separation invariants

1. A Web deployment must never read, write, upload, import, or synchronize Android participant records.
2. An Android build must never depend on Vercel being reachable to create, present, or persist a field session.
3. Web and Android must not silently exchange records through a shared API, cloud database, analytics provider, file share, or browser-to-device bridge.
4. Platform storage adapters must be selected explicitly by platform. A Web build must not import or initialize the SQLCipher/Android Keystore implementation.
5. App versions, item-bank versions, session allocations and audit records are local to the installation that created them.
6. A Vercel deployment updates only the Web application. It does not update installed APKs.
7. The APK download link on the Web site is a distribution link only; it is not a data channel.

## Browser-local storage boundary

The Web application may persist non-sensitive local workspace data and, after a separate governance decision, approved Web-local records in the user's browser profile. IndexedDB is the intended structured-storage mechanism; localStorage is reserved for small, non-sensitive preferences only.

Browser-local storage is not equivalent to SQLCipher or Android Keystore protection. It can be cleared by the user or browser, is scoped to an origin/profile, may be unavailable in private browsing or under quota pressure, and is exposed to same-origin script execution. It must not be described as encrypted or tamper-proof unless a separately reviewed cryptographic design is implemented and tested.

**Current release restriction:** participant identifiers, child names, trial responses and research session records remain disabled in the Web build. The existing browser target is a review/QA surface until the institution explicitly approves browser-based collection, its threat model, access controls, retention, export, deletion and device-sharing procedures. The browser must not collect participant data merely because local storage is available.

## Android local-storage boundary

Android remains the canonical offline field target. Participant records, when authorized, belong in SQLCipher within app-private storage. The SQLCipher key is stored using Android secure storage backed by Android Keystore. Missing or invalid keys for an existing database must fail closed; do not generate a replacement key or overwrite records.

Core field operations must not require a network connection. Network access is limited to explicit update/distribution actions and must not be used for participant record upload.

## Shared code and platform adapters

Shared code may include:
- presentation and navigation;
- protocol model and validation;
- item-bank parsing and approval checks;
- trial state machine and timing interfaces;
- export schema definitions;
- release-readiness checks.

Platform-specific code must include:
- Web IndexedDB adapter and browser lifecycle/quota handling;
- Android SQLCipher adapter and Keystore-backed key provider;
- Web service-worker update handling;
- Android package/update handling.

Use conditional imports or a narrow storage interface so unsupported platform libraries are not imported into the other target. Keep platform selection at the composition root, not scattered through UI widgets.

## Web offline behavior

The Vercel Web app is a static Flutter Web application. On first use, it needs a network connection to load and cache the application shell and bundled assets. Subsequent offline launch is best-effort subject to browser service-worker support, cache quota and user settings. Browser storage may be evicted. The Web app must display clear offline and persistence status and must never promise the same durability as Android private storage.

## Release and test acceptance criteria

### Web
- Vercel production deploy is built from main and exposes the release manifest.
- Browser-local storage is isolated by origin and does not make network requests to a participant API.
- Reload preserves only explicitly supported Web-local data.
- Clearing site data has a documented, user-visible effect.
- Offline cold launch, update waiting/activation and cache recovery are tested in supported browsers.
- No participant data collection is enabled until the separate governance approval is recorded.

### Android
- APK launches and completes core local operations with network disabled.
- SQLCipher database and key survive normal app restarts.
- Missing/corrupt key fails closed without overwriting the database.
- Trial writes and session cursor advancement are atomic.
- Actual target-tablet tests cover cold launch, power loss, storage pressure, recovery, audio, Kannada shaping and updates.

### Shared
- CI builds Web and ARM64 Android from the same commit.
- Platform-specific storage tests run independently.
- No synchronization code or remote participant endpoint is present.
- Release manifests clearly identify platform, version, commit, signing state and participant readiness.

## Explicit non-goals

- No Supabase, Firebase, MongoDB, or other cloud participant database.
- No automatic sync, background upload, cross-device merge or conflict resolution.
- No analytics, remote logging, crash telemetry or hidden network collection.
- No claim that a Vercel deployment updates an installed Android APK.
- No enabling participant collection based only on engineering completion.

## Current blockers

The scientific protocol, non-word approval, Kannada instruction recordings, ethics/data-governance approvals, participant workflow integration, exports, actual tablet acceptance and institution-owned Android signing remain separate release gates. This architecture decision does not waive or satisfy those gates.
