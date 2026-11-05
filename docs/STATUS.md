# Repository status — 5 November 2026

## Active application

- Flutter/Dart project promoted to the repository root.
- Android tablet remains the canonical field target.
- Flutter Web is a browser UI review build only.
- Next.js/PWA implementation is removed from this branch and preserved on `archive/nextjs-prototype-before-flutter-root`.
- Vercel project is being repointed to the static `build/web` output.

## Foundation currently present

- Flutter app composition and design theme.
- Initial assessor form and child welcome preview.
- Provisional six-session allocator and allocation model.
- Initial local SQLite schema.
- Trial record serialization with local timestamp offsets.
- Unit/widget tests for protocol arithmetic, allocator determinism and trial model behavior.
- GitHub Actions pipeline for formatting, static analysis, tests and Android/Web builds.

## Still not field-ready

- Formal protocol choice is unresolved: the supplied DOCX specifies 270 real + 270 non-words and 5 practice + 85 test items per session; the later 194 non-word / 45+32 scored-item allocation is an unapproved working proposal.
- The non-word candidate workbook has 270 entries, but all are pending native Kannada review and written approval.
- Full persistent child/session workflow, session resume/restart and supervisor PIN.
- Complete trial state machine, immediate persistence integration and reaction-time validation.
- Bundled Kannada font/audio and licensed visual assets.
- Approved coin/reward behavior, summary metrics and protected two-file CSV export.
- Android migrations, device-level tests, signed release APK and install guide.
- Actual tablet model and Android version need confirmation.

## Quality and hosting

GitHub Actions now runs Flutter format, analyzer, unit/widget tests, Android debug build and Flutter Web build. A green CI result verifies those automated checks only; it does not certify offline field behavior or study approval.

Vercel hosts a browser preview only. It has no runtime API environment variables. The Android APK is built separately by GitHub Actions.

**Do not use the browser preview or current Android foundation with children or for research data collection.**
