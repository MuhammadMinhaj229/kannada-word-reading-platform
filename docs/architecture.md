# System architecture

## Decision

**Next.js PWA + jsPsych + Serwist + Dexie. No cloud database in the current scope.** The app is an assessment client for the study's existing REDCap environment, not a replacement for REDCap.

```text
Vercel HTTPS distribution
  └── Next.js App Router PWA
       ├── Assessor workspace (study ID, visit/block, notes, import/export)
       ├── Child player (Kannada instruction, stimulus, two answers)
       ├── Local approved Kannada audio
       ├── jsPsych experiment timeline
       │    ├── 5 practice trials (additional to 90 scored: PI confirmation pending)
       │    ├── 90 scored trials per block
       │    ├── 45 real words + 45 non-words
       │    └── response, RT, timestamps
       ├── Serwist service worker (precache app, audio, bank; offline fallback)
       └── Dexie / IndexedDB (local participants, sessions, trials and bank)
              └── CSV / XLSX export → authorised REDCap import
```

## Confirmed allocation

- Three visits per child.
- Two blocks per visit, six blocks overall.
- Ninety scored items per block.
- Forty-five real words and forty-five non-words in each block.
- 540 unique scored items per child: 270 real words and 270 non-words.
- Five practice examples before each block are proposed as additional trials; the PI must confirm this interpretation.
- Progress reward after every five completed scored trials. Rewards are based on completion, never correctness or speed.

## Offline lifecycle

1. Assessor opens the approved HTTPS deployment online.
2. PWA installs and service worker precaches required assets.
3. Offline-readiness verifies app shell, approved item bank, Kannada font and audio pack.
4. Assessor selects study ID, assessor ID, visit and block.
5. App locks app version and item-bank version for the session.
6. Each response is persisted to IndexedDB before the next stimulus is shown.
7. Service-worker updates must not activate during an assessment.
8. Assessor exports data for authorised REDCap import.
9. App updates are applied only when all sessions are closed.

## Module boundaries

- `src/components/assessment-console.tsx`: assessor and demo UI.
- `src/lib/jspsych/ldt-choice-plugin.js`: two-choice word/non-word response and RT capture.
- `src/lib/protocol.ts`: protocol constants and record types.
- `src/lib/item-bank/validate.ts`: 540-item and 45/45 block validation.
- `src/lib/item-bank/import-xlsx.ts`: Excel parsing and approval metadata checks.
- `src/lib/storage/db.ts`: IndexedDB persistence.
- `src/app/sw.ts`: offline caching policy.

## Privacy and integrity

No cloud DB, participant API, REDCap token, analytics or external tracking is required by the current app. Do not send trial records off-device automatically. Export is non-destructive. Store study IDs rather than child names unless the approved protocol requires otherwise.

## PWA validation caveat

A PWA is not identical to a native Android APK. Test the actual target tablet for cold offline launch, orientation, fullscreen, screen-awake behaviour, audio focus, RT timing, IndexedDB durability, service-worker updates and OS lifecycle. If it fails an essential field requirement, run a Capacitor compatibility spike while retaining the Next.js codebase.
