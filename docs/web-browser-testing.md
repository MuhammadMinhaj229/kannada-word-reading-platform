# Flutter Web browser verification

The Flutter Web build is validated at three levels:

1. Dart unit/widget tests validate shared domain and screen behavior.
2. The release build validation checks the generated Web output and required bundled assets.
3. Playwright runs a real Chromium browser against the built Web output served locally in CI.

## Browser tests

From the repository root, with Node.js 22 and dependencies installed:

```bash
npm install --no-package-lock
npx playwright install --with-deps chromium
python3 -m http.server 4173 --directory build/web
# In another terminal:
npm run test:e2e
```

The Playwright suite verifies:

- Flutter Web mounts without uncaught JavaScript or console errors.
- Desktop and mobile viewport sizes both mount the same Flutter application.
- The production metadata, supplied 193-row non-word CSV and allocation JSON are served and internally consistent.
- The service worker takes control and the app shell can be reloaded after the browser goes offline.

## Data and participant safety assertions

Browser tests also assert that the Vercel/Web release metadata continues to report:

- `participantDataEntry: false`
- `participantReady: false`
- `participantDataSync: false`

The test environment uses only the bundled catalogue and never creates or submits participant records. These assertions are deliberate release guards, not temporary skips.
