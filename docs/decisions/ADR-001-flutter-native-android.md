# ADR-001: Flutter Android application is the field deliverable

- **Status:** Accepted as implementation direction.
- **Date:** 2026-11-04

## Context

The application requirements specify an Android tablet application, fully offline, distributed as a signed APK. Flutter/Dart is the named primary framework; native Android (Kotlin + Jetpack Compose) is the alternative. The requirements specify SQLite local storage, bundled pre-recorded Kannada audio, a bundled Kannada font, landscape orientation, full-screen child assessment and an awake display during sessions.

The repository currently contains a Next.js PWA prototype. Its layout and behavioural experiments can inform the Flutter implementation, but it does not satisfy the signed APK delivery requirement.

## Decision

Build the field application in Flutter/Dart under `android_app/`. Preserve the existing Next.js PWA at the repository root as a non-field reference until the Flutter implementation is accepted.

Use SQLite in the app's private data directory. Keep the item bank, audio, fonts and other required assets bundled locally. Do not add cloud sync, analytics, remote logging or third-party data collection.

## Consequences

- Android host files and release builds must be generated and validated with the Flutter/Android toolchain.
- The application must pass real-device tests with network access disabled.
- The PWA must not be represented as the signed APK deliverable.
- The item bank stays disabled until the source files are reconciled, native-language reviewed and approved in writing.
- Reaction-time, persistence, export and lifecycle behaviour require device validation beyond unit and widget tests.
