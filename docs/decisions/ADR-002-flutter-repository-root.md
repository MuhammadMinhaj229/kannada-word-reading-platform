# ADR-002: Make Flutter the repository-root application

- **Status:** Accepted for implementation
- **Date:** 5 November 2026

## Context

The study requirements name Flutter/Dart as the primary Android application framework, SQLite as local storage, fully offline operation and a signed installable APK. The repository root still contained a Next.js/PWA application while the Flutter foundation was nested under `android_app/`. This created two competing application architectures and caused the Vercel deployment to build the wrong deliverable.

## Decision

1. Promote the Flutter project files to the repository root.
2. Remove Next.js, React, PWA/service-worker, npm and Playwright application files from the active branch.
3. Preserve the prior Next.js implementation on `archive/nextjs-prototype-before-flutter-root` for traceability.
4. Use GitHub Actions for Flutter validation, Android debug APK and Flutter Web review builds.
5. Reconfigure the existing Vercel project to serve only the static Flutter Web output in `build/web`.
6. Keep the native Android APK as the sole field deliverable. The browser build is a UI review tool and must not collect participant data.

## Consequences

- Flutter/Dart is the single active application codebase.
- The repository no longer installs or builds Next.js dependencies.
- Vercel needs a pinned Flutter SDK build step and static output configuration.
- No API keys or runtime environment variables are required for the browser preview.
- Native Android-specific features and SQLite must be validated on Android, not inferred from web preview success.
- The archived branch allows recovery or reference to prior prototype behavior without keeping a second active app in the default branch.
