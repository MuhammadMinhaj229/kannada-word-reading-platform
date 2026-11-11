# Branch consolidation archive

**Consolidation target:** `main` only  
**Main commit at audit:** `d24e1290d250c4805ced84997095423ae259c259`  
**Audit:** 11 November 2026

The 15 non-main branch tips below were compared with `main` and reviewed as merged, superseded or obsolete. None was protected at the time of the audit. Their exact tips are retained as lightweight Git tags before the branch refs are removed.

| Former branch | Snapshot tag | Tip SHA |
|---|---|---|
| `architecture/independent-web-local-storage` | `archive/branch-snapshots/architecture--independent-web-local-storage` | `652e6045db003afc1b34b5c91248d893ac59b630` |
| `architecture/option-c-mainline` | `archive/branch-snapshots/architecture--option-c-mainline` | `9419a0445f31340f6975c3d99d24f98b0ea425c0` |
| `archive/nextjs-prototype-before-flutter-root` | `archive/branch-snapshots/archive--nextjs-prototype-before-flutter-root` | `c1fc0a1f6593a65d5f848a84cf2529cea10622e6` |
| `archive/nextjs-pwa-before-flutter-migration` | `archive/branch-snapshots/archive--nextjs-pwa-before-flutter-migration` | `be5389d48acfdda6d75e4f20e931166d41dfee96` |
| `docs/current-release-status` | `archive/branch-snapshots/docs--current-release-status` | `46a6f315a74de8023ae5a7ff459e1ba69a60efe6` |
| `feat/flutter-android-foundation` | `archive/branch-snapshots/feat--flutter-android-foundation` | `72c334a28fba7321d3c3b291f663a57ca4254e49` |
| `feat/production-readiness` | `archive/branch-snapshots/feat--production-readiness` | `1567c2d8fb95162c6a253b52962a36c166ef5eff` |
| `feat/two-tab-game-audio-settings` | `archive/branch-snapshots/feat--two-tab-game-audio-settings` | `93d73fc905db407b8481924fe3ceb6d6c6b11a1a` |
| `feature/assessor-only-qa-results` | `archive/branch-snapshots/feature--assessor-only-qa-results` | `a707bb92a9ba62b7ebfd477a4bce5bf9a08db92e` |
| `feature/child-task-qa-simulation` | `archive/branch-snapshots/feature--child-task-qa-simulation` | `7fd249b14e12103bdf5d4af499d5a2a8bfca8516` |
| `fix/database-and-release-gate-hardening` | `archive/branch-snapshots/fix--database-and-release-gate-hardening` | `731f3143b90eaec2b95a2d675c8601f63722aec9` |
| `fix/field-release-hardening-v2` | `archive/branch-snapshots/fix--field-release-hardening-v2` | `679dae683add601fd7fce1ae9b1c763110b88fa5` |
| `fix/production-release-pipeline` | `archive/branch-snapshots/fix--production-release-pipeline` | `53c56a84be5eadaec61cedba174c3fc4903f4a4b` |
| `mobile-ux-review` | `archive/branch-snapshots/mobile-ux-review` | `a9b5f6b2136ef275fbfd43b26a2516fea6d416db` |
| `release/vercel-online-workspace-offline-android` | `archive/branch-snapshots/release--vercel-online-workspace-offline-android` | `b119572fdc686b0a6b1eb16d2803062430a2f1cd` |

## Cleanup safety

`.github/workflows/keep-main-only.yml` runs only after a successful push-triggered main validation. It verifies that `main` still points to the validated commit, checks every old branch tip against this allowlist, creates and verifies a snapshot tag for each tip, and only then deletes the old branch ref. It refuses to delete a protected or moved branch and fails unless the remaining branch list is exactly `main`.

The snapshot tags preserve historical commit tips without leaving additional development branches active. Restore a former branch from its snapshot tag if necessary.
