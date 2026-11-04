# Deployment and release model

## Vercel project settings

The private GitHub repository is already connected to the Vercel project `kannada-word-reading-platform` in your existing team. The project settings have been aligned with the repository build.

| Setting | Value |
|---|---|
| Framework preset | Next.js |
| Root directory | `/` |
| Production branch | `main` |
| Node.js | 22.x |
| Install command | `npm install --no-audit --no-fund` (or Vercel default) |
| Build command | `npm run build` |
| Output directory | Next.js default; leave override unset |
| Environment variables | None required by the current app |
| Git integration | GitHub · `MuhammadMinhaj229/kannada-word-reading-platform` |
| Preview protection | Vercel SSO enabled |

The app uses no cloud database, API key or backend environment variables. Do not add REDCap credentials to the browser build.

## What Vercel provides

Git integration creates Preview deployments for commits/branches and Production deployments from the configured production branch. Use Preview deployments for internal UX review with synthetic data only. Keep this private project protected with the team's normal deployment access controls.

## Current deployment status

The Vercel project exists and is Git-linked. The latest known successful Vercel deployments before this configuration update were preview deployments from the `mobile-ux-review` branch. The main-branch production deployment had been cancelled. Treat the next deployment from `main` as a preview for team review until the project owner deliberately promotes a production release. SSO protection remains enabled; reviewers need team access.

## Android install

1. Open the approved HTTPS deployment in Chrome on the target Android phone/tablet.
2. Use the app's Install app prompt when available, or Chrome's Install app / Add to Home Screen option.
3. Open the installed PWA once while online so the service worker can precache the app shell.
4. Confirm the status shows Offline ready. This confirms a service worker and template warm-up, not every field-readiness criterion.
5. Force-close, enable airplane mode and reopen from the home screen.
6. Verify every needed route and asset is available before starting any field assessment.
7. Run the Playwright mobile checks: `npm run test:e2e`.

iOS installation behavior differs; this build's primary field target is Android.

## Offline integrity and updates

- Keep the child assessment session on a single loaded app version.
- Do not allow app/service-worker updates to take control during an active block.
- Only update the installed app after all sessions on the device have ended and data has been exported.
- Verify that the PWA precache includes the relevant route chunks, Kannada font assets and approved local audio.
- The service-worker status alone does not replace the full offline validation procedure in `docs/offline-validation.md`.

## Release gate

Before research use, test on the exact Android device and browser build. Confirm cold offline launch, audio offline, Kannada text shaping, touch targets, RT capture, IndexedDB durability, exports, update behavior and data-protection rules. Do not use this demo build with participants until protocol, ethics, item-bank and security approval are complete.
