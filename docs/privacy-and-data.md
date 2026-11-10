# Privacy and data handling

## Field application data boundary

- The intended field source of truth is encrypted SQLite (SQLCipher) in the Android app's private database directory.
- The SQLCipher key is generated locally and stored through Android secure storage backed by the Android Keystore.
- If an encrypted database exists but its key is missing or malformed, the app fails closed. It must not silently create a replacement key or overwrite the existing database.
- A legacy plaintext database is detected and preserved; automatic deletion or unreviewed migration is not performed.
- No cloud database, API client, analytics, crash telemetry, remote logging or automatic upload is configured.
- Child study ID is the default identifier. Child names are optional and excluded from default exports.
- Trial persistence must complete before the next stimulus can be presented. Trial response and session-cursor advancement are committed in one database transaction.
- The Web application is independent from Android storage and has no participant-data synchronization.
- Browser-local storage is limited to non-sensitive workspace preferences; structured IndexedDB persistence is not implemented.
- Participant identifiers, child names, trial responses and research session records remain disabled in the Web build pending separate institutional approval.

## Important implementation boundary

The SQLCipher database, secure-key provider, session-manifest persistence and transactional trial APIs are implemented as a data-layer foundation. They are not yet integrated into the assessor and child screens, and SQLCipher behavior has not yet passed on the actual study tablets. Do not treat the current app as a validated field data system.

The institution must approve the data controller, retention period, device custody, backup/recovery, export destination, transfer channel, access control, deletion process, and device-loss procedure. Encryption at rest is one control, not a complete data-governance programme.

## Export and REDCap

- Exports must be assessor initiated, PIN protected, non-destructive, UTF-8 with BOM, and audited locally.
- Include study IDs only by default; include names only when explicitly authorised.
- REDCap import mapping must be signed off by the REDCap administrator and study team.
- Do not embed REDCap project API tokens in the application or static Web bundle. Automated synchronisation is a separate future project requiring an approved server-side design.

## Independent Web storage boundary

Browser storage is scoped to an origin/profile, can be cleared or evicted, may be unavailable in private browsing, and is exposed to same-origin script execution. It is not equivalent to SQLCipher or Android Keystore protection. Do not describe browser records as encrypted, tamper-proof or suitable for participant data without a separately reviewed design and institutional approval.

The Web and Android data stores are independent. No shared API, cloud database, background upload, import bridge or cross-device synchronization is part of this product architecture.
