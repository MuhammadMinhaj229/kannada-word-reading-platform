# Deployment and release model

## Hosting decision

**Primary online workspace: Vercel.** The GitHub repository is connected to the Vercel project `kannada-word-reading-platform`. Vercel serves the interactive Flutter workspace; GitHub Releases distributes the downloadable offline Android APK. We will not introduce Cloudflare or a second hosting provider.

Vercel's CDN is automatically included with each deployment and is globally distributed. Vercel currently documents 126+ Points of Presence across 51 countries and more than 20 compute regions. Static Flutter files are served through that edge network; the current application has no cloud API or database requirement. See the official [CDN overview](https://vercel.com/docs/cdn) and [global network documentation](https://vercel.com/docs/regions).

## One Flutter source, platform-specific artifacts

The repository contains one application codebase: Flutter/Dart under `lib/`. Both Android and Web are built from the same commit.

| Target | Role | Delivery |
|---|---|---|
| Flutter Web | Interactive online workspace | Vercel production deployment from `main`; PWA caches the app shell and bundled assets; participant data entry remains disabled |
| Android | Downloadable offline tablet application | ARM64 APK from GitHub Releases; signed field release only after protocol, ethics, device and institutional-signing gates |

The outputs differ because Android requires an installable native package while Web requires browser assets. They are not separately maintained applications. GitHub Actions validates the shared source and builds both targets. Vercel's Git integration publishes the Web target from that same repository/commit.

The two targets have independent local data stores. Web browser storage is limited to non-sensitive workspace preferences and is scoped to the browser origin/profile; it is not equivalent to SQLCipher/Android Keystore and is not approved for participant records. Android stores its local field data in SQLCipher under app-private storage. No participant data is uploaded, imported, synchronized or shared between platforms. A Vercel deployment updates Web assets only; it does not update an installed APK.

## Vercel project

- Project: `kannada-word-reading-platform`
- Git repository: `MuhammadMinhaj229/kannada-word-reading-platform`
- Root directory: repository root
- Framework preset: none (Flutter Web is a static output)
- Install command: `bash scripts/deploy/install_flutter.sh`
- Build command: `bash scripts/deploy/build_flutter_web.sh`
- Output directory: `build/web`
- Flutter SDK: pinned by `.flutter-version` (currently `3.47.9`)

Vercel creates a preview deployment for feature-branch pushes and pull requests. Merges to the configured production branch `main` create a production deployment. This is the documented Git integration model; see [Deploying Git Repositories](https://vercel.com/docs/git).

### Production workspace

The canonical online workspace is:

https://kannada-word-reading-platform.vercel.app/

The Vercel project is linked to `MuhammadMinhaj229/kannada-word-reading-platform`; merges to `main` publish the Flutter Web application. The workspace is interactive for bundled item-bank review, Settings, release readiness and the non-participant Task preview. Its PWA caches the application shell and bundled static assets after the first successful online load.

The site does not accept participant identifiers or research responses. Vercel deployment access protection and the no-index headers remain enabled while the research instrument is under development. A Vercel deployment being `READY` means the website built and deployed; it does not authorize participant data collection.

## Build and cache behavior

The Vercel build downloads the pinned Flutter SDK and builds `build/web`. `scripts/deploy/configure_flutter_web.sh` replaces Flutter scaffold metadata with Padalab's app title, description, browser theme color, and PWA manifest labels. `vercel.json` applies the SPA fallback, baseline security headers, no-index headers, and revalidation for app entry points.

Do not enable immutable caching for all Web files unless the build is configured to use Flutter's content-hashed asset output. Entry points and the current un-hashed bundle must revalidate so a reopened browser app can receive the latest release. An already-running browser tab will not hot-swap its executing code; never force-refresh during an assessment.

The Vercel workspace is an interactive online application, but it does not provide the Android app's SQLCipher storage, durable local research records, power-loss recovery or approved field-session behavior. The Android APK is the downloadable offline tablet build.

## Android updates after installation

Publishing a new Vercel Web deployment does not replace an installed Android APK. The Android package must be signed and distributed through a managed Android channel. Recommended route:

1. Generate a signed Android App Bundle (AAB) or APK using the stable package ID and protected signing keys.
2. Publish it to a Google Play internal testing track for device QA, then a closed track for controlled pilot testing.
3. Enable Android/Google Play automatic updates on managed tablets.
4. Record the application version in each assessment session and apply updates between sessions only.

Google Play requires an update to keep the package name, use a higher version code, and be signed with the same signing identity. Devices with automatic updates enabled can receive published updates; delivery is not instantaneous. See [Google Play update guidance](https://support.google.com/googleplay/android-developer/answer/9859350) and [testing tracks](https://support.google.com/googleplay/android-developer/answer/9845334).

A custom APK downloader from Vercel is not recommended for a research instrument: it adds signing, install-permission, downgrade, interruption and integrity risks.

## Plan and cost guardrail

Vercel is globally scalable for static delivery, but the account plan matters. The Hobby plan is restricted to personal, non-commercial use. Vercel documents different included usage and build/concurrency limits across Hobby and Pro; verify the team's billing plan and expected traffic before an institutional or production rollout. See [plans](https://vercel.com/docs/plans), [limits](https://vercel.com/docs/limits), and [fair-use guidelines](https://vercel.com/docs/limits/fair-use-guidelines).

Do not treat the CDN's global distribution as a substitute for a capacity review. Before launch, estimate the number of assessor devices, daily sessions, browser-preview viewers and expected build frequency.

## Release safeguards

- Do not add API keys, database credentials, service-account JSON, signing keys or participant data to the static Web bundle.
- The debug APK produced by CI is for engineering review only, not participant use.
- Release signing must use protected GitHub secrets or a secure signing environment; never commit the keystore.
- CI success proves code checks and buildability only. It does not prove ethics approval, linguistic validity, item-bank approval, offline reliability or field acceptance.
- Before participant use, pass tablet checks for cold offline launch, durable local responses, resume/restart, timing, Kannada shaping, bundled approved audio, rewards, exports, privacy and power-loss recovery.


## Android hardening

The CI hardening step configures Android API 26+, landscape orientation, no backup/cleartext traffic, Internet permission for Play update checks, conditional release signing from protected secrets, and R8 release shrinking with SQLCipher keep rules. It creates the Flutter SDK path in machine-local `android/local.properties` on the CI runner; that file and signing material must never be committed.

The current release candidate is unsigned because no Android signing secrets are configured. It is an engineering compilation check, not a distributable field package. The institution must also confirm the permanent package identifier and own the long-term signing key before a store release.
