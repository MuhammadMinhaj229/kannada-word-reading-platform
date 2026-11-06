# Repository status — 6 November 2026

## Active application

- Flutter/Dart is the only active application codebase and lives at the repository root.
- Android and Flutter Web are built from the same source commit in one GitHub Actions workflow.
- Android remains the canonical offline field target; the Web build is a browser review surface using the same Flutter screens.
- The former Next.js implementation is removed from this branch and preserved on `archive/nextjs-prototype-before-flutter-root`.
- Android portrait and landscape orientation are both supported; the UI uses responsive scrollable layouts rather than a fixed orientation.

## Responsive quality coverage

- Assessor workspace and child welcome screen are covered at 15 viewport sizes.
- Test dimensions include compact phones, larger phones, portrait tablets, landscape tablets and desktop browser widths.
- The assessor's wide layout gives both content columns their own scroll region, avoiding vertical overflow on short landscape displays.
- Small screens use a vertically scrolling single-column layout.
- The current CI run has passed formatting, static analysis and widget/unit tests; Android and Web builds are still running as of this status update.

This is a repeatable viewport regression matrix, not a guarantee for every physical device or system font/zoom setting. Final acceptance still requires the exact tablets and Android versions used by the study.

## Shared build and hosting

- One GitHub Actions workflow runs formatting, static analysis, tests, Android debug APK build and Flutter Web build from one commit.
- The tested Web artifact is handed to a dependent Cloudflare Pages deployment job; the deploy job does not rebuild the application.
- The workflow is configured to target Cloudflare Pages Direct Upload project `padalab-kannada-reading`, production branch `main`; the project still needs to be created in the Cloudflare account.
- Same-repository pull requests receive Cloudflare branch previews; the `main` branch receives the production Pages deployment.
- Cloudflare deployment requires repository Actions secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`. Until both are configured, the deploy step safely skips. No Cloudflare production deployment has yet been verified.
- Vercel remains a temporary fallback until the Cloudflare Pages deployment is connected and verified. Do not maintain two canonical Web URLs after cutover.

## Still not field-ready

- Formal protocol choice is unresolved: the supplied DOCX specifies 270 real + 270 non-words and 5 practice + 85 test items per session; the later 194 non-word / 45+32 scored-item allocation is an unapproved working proposal.
- The non-word candidate workbook has 270 entries, but all are pending native Kannada review and written approval.
- Full persistent child/session workflow, session resume/restart and supervisor PIN.
- Complete trial state machine, immediate persistence integration and reaction-time validation.
- Bundled Kannada font/audio and licensed visual assets.
- Approved coin/reward behavior, summary metrics and protected two-file CSV export.
- Stable committed Android platform scaffold, migrations, device-level tests, signed release APK and install guide.
- Actual study tablet models and Android versions must pass hands-on acceptance.

## Update behavior

- The Cloudflare-hosted Flutter Web build can receive a newer web bundle when reopened/refreshed after deployment and reconnection; an already-running assessment must not be force-refreshed.
- Updating Cloudflare does not replace an installed Android APK. Android binary releases need a signed package and a managed distribution channel such as Google Play; updates must be installed between sessions.
- The CI debug APK is for engineering review only.

**Do not use the browser preview or current Android foundation with children or for research data collection.**
