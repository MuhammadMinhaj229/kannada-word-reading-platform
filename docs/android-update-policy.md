# Android application updates

## Web preview

The Flutter Web build is hosted on Vercel. New deployments update the hosted assets; a browser tab already open may need a reload to download the latest version. The Web application is a review surface, not the Android participant data store.

## Android field tablets

The supported production distribution path is a private Android app distributed through Managed Google Play to institution-managed tablets.

- Publish a signed Android App Bundle (AAB) or APK under the stable package ID `org.phfi.cdlr.padalab_android`.
- Keep the same Android signing identity for every update. A different signing key will prevent an in-place update.
- In Managed Google Play / Android Management API, configure the app's automatic update policy. The default policy updates when the device is on Wi-Fi, charging, inactive, and the app is not in the foreground. High-priority policy requests installation as soon as the reviewed update becomes available and the device is online.
- The Flutter app includes Google Play In-App Updates for Play-installed Android releases. Debug builds and Web previews skip the check. High-priority updates use the immediate flow; normal updates use the flexible flow at app startup.
- Google Play In-App Updates do not work for locally sideloaded debug APKs. A Play internal testing track or Managed Google Play distribution is required to validate the flow.

## Release versioning

- Increment `version:` in `pubspec.yaml` for each release, e.g. `0.2.0+2`.
- The build number after `+` must increase for each uploaded Android version.
- Release signing material must remain in protected GitHub Actions secrets. Never commit `key.properties`, a keystore, or passwords.
- The current repository has no release signing secrets configured. CI can compile an unsigned release-mode candidate, but cannot publish a signed production APK/AAB yet.
- Install updates between research sessions where possible. Do not change the application during an active trial.

## Current limitation

No Play Console / Managed Google Play publication has been performed, no institutional Android device-management policy is configured, and no signed release keystore has been provisioned. The update code compiles, but automatic delivery to installed study tablets is not active until those external release steps are completed.
