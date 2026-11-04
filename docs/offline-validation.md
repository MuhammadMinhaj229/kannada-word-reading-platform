# Offline and field validation plan

Test on the exact Android tablet model and browser version intended for the research study. Emulator results alone are insufficient.

| Test | Required pass condition |
|---|---|
| First install | PWA installs and reports required assets cached |
| Cold offline launch | Force-close, enable airplane mode, reopen from home screen; app opens |
| Navigation offline | Every assessor and child route works without network |
| Audio offline | Each approved Kannada recording plays from local storage |
| Kannada font | All approved akshara combinations render without missing glyphs |
| Touch input | Each answer tap registers exactly once |
| Reaction time | PI/statistician accepts timing accuracy on target hardware |
| Timeout | No-response recorded once, with protocol-approved next step |
| Local durability | Every trial is persisted before next stimulus |
| Recovery | Interruption follows PI-approved resume/restart policy, no duplicate trials |
| Rewards | Appears at exact five-trial milestones, independent of accuracy |
| Update safety | New service worker does not interrupt active session |
| Export | CSV/XLSX opens correctly and preserves Unicode |
| Privacy | No outbound network traffic during scored trials; no telemetry or analytics |
| Storage | App handles low storage and failed writes without silently losing data |

Do not mark the instrument field-ready until every required item passes on the target device and evidence is recorded.
