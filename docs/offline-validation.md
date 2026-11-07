# Offline and cross-platform acceptance plan

## Shared application experience

The Flutter target is intended to share its Game / Settings screens and assessment-domain logic between Android and Web. Only platform capabilities and persistence adapters should differ.

Current branch scope:
- Game and Settings navigation is shared Flutter UI.
- Kannada TTS is a device/browser demo preview only; it is not the approved recorded instruction audio.
- Participant workflow remains locked.
- Android SQLCipher is a foundation not yet wired to the UI.
- Flutter Web caches the built application shell and resources with a versioned service worker after the first successful online load. The user can refresh the worker from the assessor's idle screen.

The existing production Next.js PWA remains the production website until the migration reaches feature parity. It has its own offline service worker and IndexedDB demo persistence. Do not assume the Flutter preview has inherited the Next.js storage workflow.

## Target-device tests

Run these checks on the exact Android tablet model and Android version intended for the study. Emulator and host-SQLite results alone are insufficient.

| Test | Required pass condition |
|---|---|
| Android first install | Install signed APK from the institution-approved channel; all required assets are bundled and app opens without network access. |
| Android cold offline launch | Force-stop, enable airplane mode, relaunch from app icon; assessor screen opens without network. |
| Android UI navigation | Game and Settings render consistently in landscape and every enabled screen works offline. |
| Android local database | SQLCipher opens the encrypted database with Android secure storage/Keystore; missing key and legacy plaintext cases fail safely. |
| Android data durability | After the approved workflow is integrated, every shown trial and response is committed before next stimulus; force-stop and inspect recovery. |
| Web first load | Visit online, allow the service worker install and confirm every precached asset is available. |
| Web cold offline launch | Close the browser/PWA, disconnect network and reopen; app shell and local static resources load from cache. |
| Web navigation | Game and Settings can be navigated while offline; no external network resource is required for the demo shell. |
| Web update | Publish a new version, press Refresh updates while idle, verify worker activation/reload and preserve local browser records when a data adapter is eventually enabled. |
| Update safety | No update activation is triggered automatically during a trial or active data transaction. |
| Kannada rendering | Approved akshara combinations and conjuncts render with the approved bundled font without missing glyphs or clipping. |
| Audio offline | PHFI/CDLR-approved Kannada recordings are bundled and play offline. Device TTS is only a preview fallback and does not count as audio acceptance. |
| Scored-trial audio | Scored stimuli remain silent unless the PI explicitly approves a protocol change. |
| Touch and reaction time | Each response tap registers exactly once; PI/statistician accepts timing accuracy on target hardware. |
| Timeout and recovery | No-response, interruption, resume, restart and repeat behavior follows the signed protocol; no duplicate/skipped ordinals. |
| Export and restore | Approved CSV files preserve Kannada UTF-8 BOM, follow the signed dictionary and restore records without data loss. |
| Privacy | No participant data or telemetry leaves the device/browser; no analytics, crash upload or remote logging. |

## Browser storage boundary

The Flutter Web branch currently has an offline shell only. It does not yet persist participant sessions through an IndexedDB/browser-local adapter. Do not enter participant information in this preview. If Web participant capture remains required, the browser adapter must be implemented and separately tested for persistence, export, restore, deletion, storage quota failure and multi-tab behavior.

## Release gate

Do not mark the instrument field-ready until the study approvals, final item/audio/font assets, full data workflows, actual tablet checks and privacy/security review all have evidence. The participant release gate must remain closed in the meantime.
