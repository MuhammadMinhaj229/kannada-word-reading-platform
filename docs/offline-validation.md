# Offline and cross-platform acceptance plan

## Platform responsibilities

The Android tablet application is the field target. The Flutter Web output on Vercel is a read-only interface and bundled-content review. It must not collect participant identifiers or store participant sessions.

The two platforms share the Flutter presentation and assessment domain, while persistence and update behavior remain platform-specific.

## Current branch scope

- Responsive assessor workspace with NavigationRail on wide screens and bottom navigation on narrow screens.
- Supplied 270-word CSV bundled, parsed and checked for unique entries.
- Non-word method summary bundled; all candidate items remain pending native review.
- Android SQLCipher and secure-key storage foundation exists but is not fully connected to the assessor/child session UI.
- Flutter Web uses a content-derived service-worker fingerprint and manual refresh.
- Kannada audio playback is limited to bundled recordings with an approval reference. The source recording is not yet segmented into approved clips.

## Target-device checks

Run these on the exact Android tablet model and Android version intended for the study. Emulator and host SQLite tests alone are insufficient.

| Test | Required pass condition |
|---|---|
| Package compatibility | Signed APK installs on the target ARM64 tablet with Android 8.0 (API 26) or later. |
| First install | All required app assets are bundled; app opens without network access. |
| Cold offline launch | Force-stop, enable airplane mode and relaunch; assessor workspace opens. |
| Responsive layout | All enabled screens render without clipping or overflow in supported landscape tablet sizes and browser phone/tablet/desktop sizes. |
| Local database | SQLCipher opens with Android secure storage/Keystore; missing-key and legacy plaintext cases fail safely. |
| Response durability | Each presented trial and response is committed before the next stimulus; force-stop and inspect recovery. |
| Resume | App restores the same frozen manifest, current ordinal and any pending presented trial. |
| Kannada rendering | Approved akshara combinations and conjuncts render using the bundled font without clipping or missing glyphs. |
| Kannada audio | PHFI/CDLR-approved instruction recordings are bundled and play offline with no TTS or network fallback. |
| Scored-trial audio | Scored stimuli remain silent unless the PI approves a protocol amendment. |
| Reaction time | Each touch registers exactly once; timing accuracy is accepted on the target tablet. |
| Timeout/recovery | No-response, interruption, resume, restart and repeat rules match the signed protocol. |
| Export | Approved CSV preserves the UTF-8 BOM and signed dictionary; names are excluded by default. |
| Update safety | No application update is activated during an active assessment or data transaction. |
| Privacy | No participant identifiers or records leave the device; no analytics, crash upload or remote logging. |
| Power loss | A forced shutdown during a trial does not lose or duplicate committed responses. |

## Browser review checks

- First online load precaches the Flutter Web shell and local resources.
- Cold offline browser/PWA launch loads the shell and required static resources from cache.
- A changed asset byte produces a new service-worker cache identity, even when the URL remains unchanged.
- The assessor-triggered refresh activates the new worker only when the user requests it.
- Browser entry fields remain read-only; no participant data is accepted or persisted.

## Release gate

Do not use the application with research participants until the written protocol, approved item bank, signed allocations, audio/font assets, ethics/data-governance decisions, supervisor controls, exports and actual-tablet checks all have recorded evidence. CI and browser preview success do not replace this acceptance.
