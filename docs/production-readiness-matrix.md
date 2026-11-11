# PadLab production-readiness matrix

**Status as of 11 November 2026**  
**Source of truth:** the repository's `main` branch. The exact deployed commit is recorded in `app-release.json`.

## Release posture

| Target | State | What this means |
|---|---|---|
| Vercel Web review workspace | Production deployment ready | The online Flutter review workspace, catalogue, Settings, non-participant preview and PWA shell are deployed and browser-tested. |
| Web participant collection | Disabled by design | Under the accepted Option C boundary, Web stores only a non-sensitive workspace preference. No participant IDs or responses are accepted in the browser. |
| Android ARM64 engineering APK | CI build passed; debug-signed | Suitable for internal engineering review only. It is not an institutional field release. |
| Android participant assessment | Blocked | SQLCipher schema and transaction methods exist, but the assessor/session/child UI is not wired to them and the signed release gate is closed. |
| Research protocol/item bank | Blocked | The requirements baseline conflicts with the latest 45+32 engineering allocation; 193 bundled candidate rows are pending review and do not form the required 270-item approved non-word pool. |
| Kannada audio | Blocked | Approved per-item recordings and the approved instruction clip set have not been installed. |
| Institutional field deployment | Blocked | Ethics/data governance, target-tablet acceptance, export mapping, supervisor authorization and institution-owned signing remain outstanding. |

## Verified engineering evidence

- Main-branch Flutter CI passed formatting, static analysis, 83 unit/widget tests, ARM64 Android debug build, Flutter Web release build and all four Playwright browser tests.
- Playwright verified Flutter Web startup, desktop/mobile viewport mounting, current bundled review assets and offline PWA app-shell reload.
- Vercel production deployment for `d24e129` reached READY and serves the release manifest and service worker.
- Vercel runtime error query for the preceding 24-hour window returned no runtime errors.
- The release manifest reports `participantDataEntry: false`, `participantReady: false`, `participantDataSync: false` and `apkSigning: "debug"`.

## Data and protocol integrity

The app contains 270 real-word rows. The original non-word summary asset records 270 candidates (A/B/C/D = 68/68/67/67), while the bundled review CSV contains 193 rows (A/B/C/D = 34/46/65/48); all supplied rows remain pending. These artifacts do not reconcile and must not be presented as a complete approved pool.

The latest engineering proposal v2 is 6 × (45 real + 32 non-words) = 462 scored items, with `N270` held as one reserve. It does not define practice items or randomisation. The transcribed requirements baseline remains 6 × 90 presentations (five practice + 85 test) and a 270+270 bank. This conflict requires written PI/statistician resolution.

## Remaining engineering work

1. Wire the native assessor, session history, child trial and resume/recovery screens to the existing SQLCipher repository after a signed protocol and item bank are available.
2. Complete database migration policy, transactional trial recovery, supervisor authorization, export generation and integrity checks; validate on the actual Android study tablet.
3. Build and install the final approved 270-item non-word pool, freeze and sign session manifests, and verify item-bank checksums.
4. Segment and approve Kannada instruction/word audio; verify offline playback and Kannada font shaping on the target tablet.
5. Complete privacy/ethics/data-governance decisions, participant/parent consent, retention, device-loss and approved REDCap/export mapping.
6. Provision the institution-owned signing identity and permanent package/update/distribution path; run the signed-release workflow only after the release gate can verify the signed approval manifest.

## Definition of field-ready

Field-ready means all required scientific, linguistic, governance, technical, device and signing evidence is recorded, the signed approval manifest verifies against a pinned study-team public key, and the participant workflow passes end-to-end target-device tests. A successful CI build or Vercel deployment alone cannot satisfy this definition.
