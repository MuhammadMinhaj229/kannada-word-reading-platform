# Repository status — 7 November 2026

## Active application

- Flutter/Dart is the only active application codebase and lives at the repository root.
- Android and Web are built from the same source commit.
- Android remains the canonical offline field target; Flutter Web is a browser UI review target using the same screens.
- The former Next.js implementation is preserved on branch `archive/nextjs-prototype-before-flutter-root`.
- Both portrait and landscape orientations are supported; the app uses responsive layouts rather than a fixed orientation.

## Responsive quality coverage

- Assessor workspace and child welcome screen are tested at 15 viewport sizes each.
- Test dimensions include compact phones, larger phones, portrait tablets, landscape tablets and desktop browser widths.
- The wide assessor layout gives both columns their own scroll region; narrow layouts use one vertically scrolling column.
- The child welcome flow now opens a four-item synthetic demo with working word/non-word buttons, a progress indicator, in-memory response timing, feedback, a result view and restart.
- This is automated viewport regression coverage, not a guarantee for every physical device, system font or zoom setting. Final acceptance requires the actual tablets used by the study.

## Build and hosting

- GitHub Actions runs formatting, static analysis, unit/widget tests, Android debug APK build and Flutter Web build.
- The latest verified CI run on commit `43c0d2ce8f3e53f51c1bc447b60b90666d3551f0` succeeded for all listed checks and both platform builds.
- Vercel is the single Web host. The connected project automatically creates branch previews and production deployments from `main`.
- A branch preview for commit `43c0d2ce8f3e53f51c1bc447b60b90666d3551f0` returned HTTP 200.
- The production branch is still `main`; the Flutter migration remains in the draft PR and has not been merged.
- No Cloudflare project, account token or second Web host is required.

## Engineering and research blockers

- The supplied requirements DOCX specifies 270 real + 270 non-words and 5 practice + 85 test items per session; the later 194 non-word / 45+32 scored-item allocation is an unapproved working proposal. The PI/statistician must resolve the protocol in writing.
- The non-word candidate workbook has 270 entries, all pending native Kannada review and written approval.
- The synthetic child demo is not the real study game: it uses demonstration examples only and does not persist responses.
- Full persistent assessor/child/session workflow, session resume/restart and supervisor PIN remain incomplete.
- Complete trial state machine, immediate response persistence, response correctness capture and reaction-time validation remain incomplete.
- Bundled Kannada font/audio and licensed visual assets remain incomplete.
- Reward behavior, summary metrics, protected CSV exports, stable committed Android platform scaffold and migrations remain incomplete.
- Release signing, Play testing track, installation/rollback instructions and real-device offline testing remain incomplete.
- Study tablet models and Android versions need hands-on acceptance.

## Update behavior

- Reopened/refreshed Flutter Web preview can receive the latest Vercel deployment after a branch update and network reconnection; an active tab will not replace its own running code.
- Vercel Web deployment does not update an installed APK.
- Android binaries require a signed, versioned package distributed through a managed update channel. Install updates between sessions.
- The current APK is debug-signed and intended only for engineering review.

**Do not use the browser preview or current Android foundation with children or for research data collection.**
