# ಪದLab — Kannada Word Reading Assessment PWA

**Repository status:** starter implementation — not yet build-verified  
**Build:** 0.1.0 · **Framework:** Next.js App Router + TypeScript  
**Target:** Android phones and tablets with current Chrome/Chromium installed PWA support

## Product decision

This project uses **Next.js as the single application framework** and ships as an installable, offline-first Progressive Web App (PWA). It does not require a hosted database.

The existing research study remains in **REDCap**. This app is a specialist child-facing lexical-decision instrument. It presents stimuli, records trial responses locally, and exports session-level data for the study's approved REDCap workflow.

## Confirmed planning structure

- 3 visits per child.
- 2 test blocks per visit.
- 6 blocks per child.
- 90 scored items per block.
- 45 real words + 45 non-words per block.
- 540 scored items per child: 270 real words + 270 non-words.
- Proposed: 5 practice trials before each 90-item scored block. This makes 95 presentations per block and 570 total presentations. **The PI must confirm practice trials are additional to the 90 scored items.**
- Small progress reward after every 5 completed scored trials; never based on correctness or speed.
- No correctness feedback during scored trials unless explicitly approved by the study protocol.

## Architecture

| Concern | Implementation |
|---|---|
| Application | Next.js App Router + React + TypeScript |
| Offline shell/assets | Serwist service worker and precache |
| Behavioral timeline | jsPsych 8, custom Kannada two-choice plugin |
| Trial persistence | Dexie + browser IndexedDB |
| Excel item-bank import | ExcelJS with strict structural validation |
| Hosting / updates | Vercel connected to private GitHub |
| Research data system | Existing REDCap; CSV/XLSX export first |
| Cloud database | None in current scope |

## Run locally

Use Node.js 22.

```bash
npm install
npm run dev
```

Open `http://localhost:3000`.

For a production PWA build:

```bash
npm run build
npm run start
```

## Implementation status

- Next.js App Router project scaffold.
- Assessor workspace and child-game demonstration.
- Custom jsPsych lexical-decision plugin; local response write is awaited before moving forward.
- Five practice examples followed by a 10-item demonstration block.
- Progress/reward milestone after every fifth scored demonstration response.
- Dexie IndexedDB persistence.
- Responsive phone/tablet layouts with phone bottom navigation, safe-area padding, accessible zoom, and a dedicated full-screen child trial view.
- PWA manifest, install prompt, network/offline status, and Serwist service worker with local static-resource caching.
- Bundled Noto Sans Kannada font files via Fontsource (OFL-1.1).
- Six-block item-bank validator: 540 total, 270/270, 45/45 per block, unique IDs/text, complete order, approval metadata.
- ExcelJS workbook parser and local item-bank storage.
- Blank 540-item authoring template.
- CI workflow and architecture/privacy/licensing notes.

## Not yet approved or complete

- Final 540 approved stimuli and allocation/order file.
- PI decision on whether five practice items are additional to the 90 scored items.
- Final Kannada instruction scripts and native female voice recordings.
- Full participant/session setup, session locking, recovery and export workflow.
- Final REDCap mapping/API integration.
- Actual-tablet offline validation, RT validation, accessibility and field pilot.
- Build/CI verification: the preparation environment could not reach npm registry, so lint, typecheck and production build have not been run.

The demo includes fictional non-word strings for visual demonstration only. They are not linguistically screened and must never be used with children.

## Research and licensing

The LEVANTE core-tasks repository is a methodological reference; do not copy its implementation or assets without a licensing review. Its core task materials have CC BY-NC terms. ROAR-LDT has a more restrictive Stanford academic software licence. See `docs/reference-repositories.md` and `docs/open-source-reuse-policy.md`.

## Data and ethics guardrails

- Never commit child names, study data, item-bank data or trial exports.
- No analytics, advertising, remote logging or external tracking on the child assessment route.
- Keep trial records local; do not upload automatically.
- Use approved Kannada recordings and institution-approved visuals.
- Obtain PHFI/CDLR ownership, ethics, information-security and data-retention approval before field use.
- This repository is private and has no open-source licence assignment.

## Deployment

Import this private GitHub repository into Vercel. Use project root `/`, install command `npm install`, and build command `npm run build`. The current prototype needs no backend environment variables. Commit a lockfile after npm install before treating CI as production-ready.
