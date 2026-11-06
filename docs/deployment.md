# Deployment and release model

## One Flutter application, one release pipeline

The repository has one application codebase: Flutter/Dart under `lib/`. A single GitHub Actions workflow validates that commit, builds the Android APK and Flutter Web output, and uploads the build artifacts. After a successful push to `main`, it can publish that same commit's Web output to Cloudflare Pages.

| Target | Role | Delivery |
|---|---|---|
| Android | Canonical offline field application | Debug APK in CI now; signed release package only after signing and study gates |
| Flutter Web | Browser-based UI review of the same Flutter screens | Cloudflare Pages static deployment from the same successful CI run |

This is not a separate React/Next.js website. Flutter widgets and Dart application logic are shared. The web build is a browser review surface and does not certify SQLite, native Android behavior, offline study operation, audio, timing accuracy or tablet acceptance. Do not enter real participant data in it.

## Cloudflare Pages — primary web preview host

The repository is prepared for Cloudflare Pages Direct Upload. The GitHub Actions workflow runs `flutter build web`, configures browser cache revalidation, and deploys `build/web` with Wrangler after a successful push to `main`. The Cloudflare step safely skips itself until the two repository secrets below exist.

### One-time Cloudflare setup

1. Open Cloudflare Dashboard → **Workers & Pages** → **Create application** → **Pages** → **Direct Upload**. Do not choose Git integration for this project: this repository uses GitHub Actions to build Flutter and upload the prebuilt output, and Cloudflare does not let a Direct Upload project later switch to Git integration.
2. Create the Pages project with the exact name `padalab-kannada-reading` and set its production branch to `main`.
3. In Cloudflare, create a custom API token with **Account → Cloudflare Pages → Edit** permission. Do not use a Global API Key.
4. In the GitHub repository, open **Settings → Secrets and variables → Actions** and add:

   | Secret name | Value |
   |---|---|
   | `CLOUDFLARE_ACCOUNT_ID` | Your Cloudflare account ID |
   | `CLOUDFLARE_API_TOKEN` | The Pages-scoped API token |

5. Do not paste the token into source files, issues, pull requests or chat. Once the project exists and both secrets are saved, merge the reviewed Flutter PR to `main` only when its engineering and research gates are satisfied. The next successful `main` run publishes the web build to `https://padalab-kannada-reading.pages.dev`.

### Preview and cache behavior

Pushes to `main` publish the Cloudflare production site. Same-repository pull requests publish a branch preview after validation; forked pull requests receive no Cloudflare credentials and only run the build checks. The preview branch name is normalized for DNS, so this feature branch will use `feat-flutter-android-foundation.padalab-kannada-reading.pages.dev`. The shared `scripts/deploy/configure_web_output.sh` writes a `_headers` policy that revalidates web assets when the app is opened again. Flutter 3.47.9 is pinned to the latest stable release currently selected for this project; do not use Flutter 3.50 preview-only flags in a production build.

A browser-installed shortcut can receive the current Web bundle after the device reconnects and the app is reopened or refreshed. A currently open tab does not change its running code in-place. Do not force-refresh an active assessment; update checks should be offered only between sessions, after the workflow is complete and approved.

The Web build is not the offline field client. The current app uses native-only local persistence and needs device-level validation. A browser app cannot be assumed to work offline simply because it is hosted on Cloudflare.

## Android updates after installation

The Android APK and Web bundle are built from the same Flutter commit, but they are different platform packages. Deploying a new Web build to Cloudflare does not rewrite the binary already installed on an Android tablet.

For normal Android distribution, publish a signed Android App Bundle/APK through Google Play (initially an internal or closed testing track). Devices with app auto-updates enabled can then receive approved releases through Play. The package name and signing identity must remain stable, and each release must increase the version code. Directly sideloaded APKs do not gain a safe, silent Cloudflare-based binary updater.

Because this is a research instrument, updates must not interrupt a running session. Record the app version with each session; deploy protocol or item-bank changes only after written approval, and install them between sessions. Consider an in-app update prompt backed by Google Play rather than a custom binary downloader.

## Existing Vercel project

The Vercel project `kannada-word-reading-platform` was previously repointed to Flutter Web. Keep it as a temporary fallback while Cloudflare is configured and its first deployment is verified. Cloudflare should become the single canonical Web preview URL after cutover; then disable or disconnect the Vercel Git deployment so two competing web production URLs are not maintained. Vercel preview protection is currently SSO-based.

## Release safeguards

- Do not add API keys, database credentials, service-account JSON, signing keys or participant data to the static Web bundle.
- The debug APK produced by CI is for engineering review only, not participant use.
- Release signing must use protected GitHub secrets or a secure signing environment; never commit the keystore.
- CI success proves code checks and buildability only. It does not prove ethics approval, linguistic validity, item-bank approval, offline reliability or field acceptance.
- Before participant use, pass tablet checks for cold offline launch, durable local responses, resume/restart, timing, Kannada shaping, bundled approved audio, rewards, exports, privacy and power-loss recovery.
