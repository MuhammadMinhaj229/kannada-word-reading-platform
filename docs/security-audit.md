# Security and release audit

**Audit date:** 7 November 2026  
**Scope:** Flutter Android/Web branch, GitHub Actions build/release workflows, Vercel static hosting and local data-protection foundation.  
**Disposition:** Engineering hardening in progress; not approved for research participant use.

This is a repository code/configuration review, not a third-party penetration test, institutional security approval or Android device-acceptance certificate.

## Controls present in the Flutter branch

### Android platform

- Native Android host is generated from the pinned Flutter SDK and hardened by `scripts/deploy/configure_android_project.sh`.
- Minimum Android API is 26; the field orientation is landscape.
- Android backup and cleartext network traffic are disabled.
- R8 shrinking is configured with SQLCipher keep rules.
- The current supported native ABI is ARM64 (`arm64-v8a`).
- Play update checks are explicit and are not used as a substitute for managed release distribution.

### Local data foundation

- Assessment storage uses SQLCipher rather than plaintext SQLite on Android.
- A cryptographically random database key is stored through Android secure-storage/Keystore integration.
- Missing or unreadable keys for an existing encrypted database fail closed.
- A legacy plaintext database is preserved and is not silently overwritten.
- Session creation freezes its manifest transactionally.
- Trial content is checked against the frozen manifest.
- Response persistence and session-cursor advancement are atomic and exactly-once guarded.
- Repeat/restart is disabled until trusted supervisor authorization is implemented.

The database API is not yet wired through the complete assessor/child UI, and native SQLCipher/Keystore behavior has not yet been accepted on the target tablet.

### Supplied study content

- The 270-word source CSV is bundled and structurally validated.
- The non-word summary records the supplied 68 / 68 / 67 / 67 proportions.
- All non-word candidate rows remain Pending; the participant engine must not load them as approved stimuli.
- The approved 540-item bank and signed session allocations are not present.

### Audio

- Device TTS was removed from the active application.
- The audio player accepts only locally bundled clips whose manifest carries a written approval reference.
- The supplied source recording has not yet been segmented and approved; the manifest remains closed.
- No network speech service or synthesized fallback is configured.

### Web hosting and cache updates

- Flutter Web is a static review build on Vercel.
- The browser build does not accept participant identifiers or persist participant sessions.
- Security headers, no-index headers and SPA fallback are configured in `vercel.json`.
- The service-worker cache fingerprint now hashes asset file contents and paths, so stable filenames such as `main.dart.js` still produce a new cache version when their bytes change.
- The service worker waits for the user-triggered refresh action rather than replacing an active app automatically.

### CI and APK artifact handling

- The ordinary validation workflow uploads only source/test artifacts, a debug APK and Web build output.
- It no longer uploads the generated Android scaffold directory.
- The separate `release-apk.yml` workflow requires all four protected signing secrets, builds a signed ARM64 release APK, verifies the APK signature and ABI, calculates a SHA-256 checksum, and publishes only the APK and checksum.
- Signing files remain on the ephemeral runner and are not included in workflow artifacts.

## Findings addressed in this branch

| Finding | Change | State |
|---|---|---|
| Android keystore could be included in a scaffold artifact | Removed scaffold artifact upload; signed release workflow publishes only APK and checksum | Addressed in source; fresh CI evidence pending |
| Web service-worker fingerprint ignored asset contents | Cache fingerprint now hashes each path and its bytes | Addressed in source; fresh Vercel build pending |
| Synthetic app mode and sample records could be mistaken for field workflow | Removed demo flag, demo game, demo record store, demo exports and associated tests | Addressed in source; fresh CI evidence pending |
| Device TTS could substitute for approved voice | Removed TTS dependency and implementation; added approved local recording manifest/player | Addressed in source; approved clips still missing |

## Release blockers

1. Written PI/statistician approval of the final study protocol, session schedule, allocation/order, timeout/no-response, practice and reward rules.
2. Native Kannada review and written approval for all 270 non-word candidates.
3. Final signed 540-item bank, checksum and six signed session allocations.
4. PHFI/CDLR-approved Kannada instruction clips, recording version and approval reference.
5. Ethics/consent and institutional data-governance/retention/device-loss procedures.
6. Supervisor PIN provisioning, rate limiting, trusted authorization verifier and audit trail.
7. End-to-end assessor/session/child workflow integration with the SQLCipher repository.
8. Session recovery, history, summary, protected export dictionary and REDCap mapping.
9. Android SQLCipher/Keystore, reaction-time, offline cold launch, Kannada font/audio, power-loss and update testing on the actual tablet.
10. Institution-owned Android package identity and signing keystore configured as protected GitHub secrets.
11. Successful current GitHub Actions and Vercel preview checks.

Passing CI proves code checks and buildability only. It does not prove research validity, ethics approval, linguistic/audio validity, security certification, offline acceptance or field readiness.

**Keep the participant release gate closed until every blocker has recorded evidence.**
