# Deployment and release model

## Product targets

- **Android APK:** canonical field product. It runs Flutter/Dart with on-device SQLite and bundled approved assets. It is built and validated through GitHub Actions; release signing is a separate protected workflow.
- **Flutter Web:** review-only build of the Flutter UI. It is a static site, not an alternative field client. Do not enter real participant data in a browser preview.

## Vercel project settings

The existing Vercel project `kannada-word-reading-platform` remains connected to the private GitHub repository. It is repurposed from Next.js to a static Flutter Web build.

| Setting | Value |
|---|---|
| Framework preset | Other / no framework (`framework: null`) |
| Root directory | Repository root |
| Install command | `bash scripts/deploy/install_flutter.sh` |
| Build command | `bash scripts/deploy/build_flutter_web.sh` |
| Output directory | `build/web` |
| Runtime environment variables | None required |
| Flutter SDK | Pinned by `.flutter-version` |
| Git integration | `MuhammadMinhaj229/kannada-word-reading-platform` |
| Preview protection | Retain Vercel SSO protection |

No API keys, database credentials, service account JSON, or participant data belong in Vercel environment variables. The Flutter Web bundle is static and contains no secrets.

## Build behavior

Vercel runs the install script to cache the pinned Flutter SDK in the build environment. The build script generates the Flutter web host directory, resolves Dart packages, and runs:

```bash
flutter build web --release --base-href /
```

The output directory is `build/web`. `vercel.json` declares the build and single-page fallback. A successful deployment means the browser review bundle was produced and hosted; it does not prove the Android package works.

## Preview access

Vercel preview deployments are created from non-production Git branches. Keep SSO enabled by default. A reviewer must have the required Vercel team access to open the protected preview. Do not disable deployment protection merely to make a preview URL public; use an approved reviewer invitation or a separate password-protected preview if external review is required.

## Free-host alternatives researched

| Host | Flutter Web suitability | Relevant free-tier characteristics | Recommendation |
|---|---|---|---|
| Vercel Hobby | Good for static Flutter output with custom build/output settings | Hobby build time up to 45 minutes; Git-based preview deployments; existing project/repository already connected | **Use first**; lowest migration overhead |
| Cloudflare Pages | Very good when CI uploads prebuilt static files | Free limits include 500 builds/month, 20-minute build timeout, 20,000 files/site and 25 MiB per individual file | Best alternative if Vercel's Flutter SDK build becomes unreliable |
| Firebase Hosting | Very good static hosting; Flutter has official deployment documentation | Spark is no-cost and does not require a payment method; hosting has plan-specific quotas | Good Google ecosystem option, but requires Firebase project setup |
| Netlify | Good static hosting | Free plan currently uses a 300-credit monthly allowance, including build/deploy usage | Viable, but less attractive for frequent CI deploys |

Static asset hosting is the only infrastructure needed for the UI preview. No server, database or API is required for this purpose.

## Android release

1. Build with the pinned Flutter SDK and Android SDK in CI.
2. Add a release signing keystore only through protected GitHub secrets or a secure local signing environment. Never commit it.
3. Build a signed release APK.
4. Test installation and runtime behavior on the actual field tablet with Wi-Fi and mobile data disabled.
5. Provide the APK through an approved download link and a one-page install guide.

## Release gate

Before participant use, obtain written protocol and item-bank approval; then pass tablet testing for cold offline launch, local persistence, response durability, resume/restart, reaction-time capture, Kannada shaping, bundled audio, reward behavior, CSV exports, Downloads/share sheet, privacy and power-loss recovery. A browser preview or CI green check cannot replace those acceptance tests.
