# Repository status — 4 November 2026

## Web application quality

- Next.js App Router + TypeScript PWA.
- Responsive layout includes six-item phone bottom navigation, tablet/desktop sidebar, safe-area support, larger touch targets and a dedicated full-screen child-play state.
- Noto Sans Kannada is bundled locally; no remote font dependency is required.
- Service worker precaches the app shell and caches local static resources plus the Excel item-bank template.
- PWA install prompt and user-controlled update action are implemented. An update action is disabled while the child demo session is active.
- Local CSV and XLSX exports read from IndexedDB; exports are non-destructive and include trial/session sheets.
- Excel import performs structural 540-item and 45/45-per-block checks. This does not certify Kannada linguistic validity.

## Automated verification

The GitHub Actions run at commit `80a7cbb48d97e20a1485e2cdcac80a283c40b0cf` passed:
- npm dependency installation
- ESLint
- TypeScript type checking
- Next.js production build
- 9 Playwright browser tests (6 responsive viewports, assessor setup, child demo/reward, Excel template endpoint)

That workflow generated and committed `package-lock.json` at commit `5d364ea5320c08f710da79976f3142de7c5eaa7d`. The next CI run should verify the committed lockfile using `npm ci`.

## Vercel

The private repository is linked to the Vercel project `kannada-word-reading-platform`. Project framework is Next.js, root directory is the repository root, Node.js is 22.x and build command is `npm run build`. Vercel SSO protection remains enabled. Verify the latest main deployment before sharing its URL with reviewers.

## Not field-ready yet

This is a review PWA, not an approved research instrument. Still required:
- Confirm whether five practice trials are additional to the 90 scored items in each block.
- Final PI-approved 540-item bank and allocation/order.
- Native-speaker-reviewed Kannada instructions and approved female voice recordings.
- Complete participant/session workflow, resume/restart rules and assessor note persistence.
- Research-grade export dictionary and REDCap import mapping.
- Security/ethics approval for browser-local child data, device custody, retention and device-loss response.
- Offline cold-launch, audio, RT, storage and update acceptance tests on the actual tablet.
- Field pilot and documented sign-off.

**Do not use demo strings, demo IDs or this review deployment with children.**
