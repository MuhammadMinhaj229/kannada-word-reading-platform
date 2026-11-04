# Deployment and release model

## Vercel preview vs field release

- Vercel Preview is for UX and engineering review only. Use synthetic demo content only.
- Production PWA distribution requires HTTPS and institutional access controls.
- Do not use the app with children until protocol, ethics, item-bank, voice and data approvals are documented.

## Vercel setup

1. Connect this private GitHub repository to the approved Vercel team.
2. Framework preset: Next.js.
3. Root directory: `/`.
4. Node.js: 22.x.
5. Build command: `npm run build`.
6. No database environment variables are required by this version.

## Install on Android

1. Open the HTTPS deployment on the target tablet.
2. Install the PWA using the browser's install option.
3. Open it while online and allow the service worker to cache the shell and bundled assets.
4. Confirm the installed app launches cold while airplane mode is enabled.
5. Do not begin testing until app, item bank, font and audio readiness checks pass.

## Release updates

Service-worker updates must not interrupt a live assessment. Apply app updates only from the assessor workspace after all sessions are closed and local data is exported. Keep a record of the exact app and item-bank versions used for every child.

## Current limitation

This is a starter implementation and has not been build-verified in this environment. Install dependencies, commit a lockfile, run lint/typecheck/build, then perform the tablet acceptance plan in `docs/offline-validation.md`.
