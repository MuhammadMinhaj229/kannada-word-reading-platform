# Offline and Android field-validation plan

The primary deployment target is the native Android APK. The Vercel Flutter Web build is a synthetic-data review surface only; it does not validate Android storage, audio, timing, or device behavior.

Run these checks on the exact Android tablet model and Android version intended for the study. Emulator and host-SQLite results alone are insufficient.

| Test | Required pass condition |
|---|---|
| First install | Install the APK/managed Play build; confirm the app opens and all bundled fonts/assets are present without a first-launch network dependency. |
| Cold offline launch | Force-stop the app, enable airplane mode, relaunch from the app icon; the assessor home screen opens without a network request. |
| Offline navigation | All currently enabled assessor and synthetic-demo screens remain usable offline. The participant workflow is still release-locked and must not be treated as validated. |
| Local database | On Android, verify SQLCipher opens the encrypted database with the Android Keystore-backed key; verify missing-key and legacy-plaintext cases fail safely. |
| Local durability | After the persistence workflow is approved and integrated, verify every presented trial and response is committed before the next stimulus; force-stop and inspect recovery. |
| Kannada rendering | All approved akshara combinations and conjuncts render with the approved bundled font, with no missing glyphs or layout clipping. |
| Audio offline | No audio player or approved Kannada recordings are currently bundled. Do not claim audio support. After the study team approves the exact instruction recordings, verify they play from packaged local assets with the device offline. |
| Scored-trial audio | Scored stimuli remain silent unless the PI explicitly approves a protocol change. No network TTS or generated voice is permitted as a substitute for approved recordings. |
| Touch input | Each response tap registers exactly once, including rapid taps and repeated taps after a response is accepted. |
| Reaction time | PI/statistician accepts timing accuracy and the timestamp source on the target hardware. |
| Timeout | No-response is recorded exactly once and follows the approved timeout/next-step policy. |
| Recovery | Interruption, resume, restart and repeat behavior follows the signed protocol; there are no duplicate or skipped trial ordinals. |
| Rewards | Reward cadence and practice/scored-trial treatment match the approved protocol exactly. |
| Manual update | Install through the approved Play testing/managed track, connect to Wi-Fi, use **Refresh updates** from the idle assessor home screen, and verify the expected version is installed. Do not update during a trial. |
| Sideloaded APK | Confirm that Play in-app updates are unavailable for a locally sideloaded APK; do not represent the debug APK as self-updating. |
| Export | Approved CSV/XLSX exports open correctly, preserve Kannada Unicode, and follow the signed data dictionary and privacy rules. |
| Privacy | No telemetry or analytics; no outbound request during a scored trial. Update checks occur only after the assessor explicitly requests them from the idle home screen. |
| Storage failure | Low-storage and failed-write cases do not silently lose responses or advance the trial cursor. |

The present build is an engineering preview: the participant workflow remains locked, SQLCipher is not yet integrated into the full assessor/child flow, and no study audio or font has been approved. Do not mark the instrument field-ready until every applicable check passes on target devices and evidence is recorded.
