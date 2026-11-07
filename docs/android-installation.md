# Android tablet installation and release

## Supported target

The current native build target is Android 8.0 (API 26) or later on ARM64 (`arm64-v8a`) tablets. A single APK cannot guarantee compatibility with every Android tablet, chipset, vendor ROM or Android version. Confirm the exact study tablet model and Android build before field distribution.

## Production APK

A production APK must be built from a reviewed release tag and signed with the institution-owned, long-lived Android signing identity. The keystore and passwords must be stored only in protected GitHub Actions secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

The signing keystore and `android/key.properties` must never be committed or uploaded as workflow artifacts. The workflow publishes the signed APK and SHA-256 checksum only when all signing secrets are present. Debug APKs are engineering-review packages, not field releases.

## Installation procedure

1. Obtain the signed APK and its SHA-256 file from the approved GitHub Release or institutional distribution channel.
2. Verify the checksum on the receiving computer or tablet before installation.
3. Confirm the tablet is Android 8.0+ and ARM64.
4. Install the APK using the institution-approved managed process. Enable installation from the selected source only when required, then disable that permission afterwards.
5. Open PadLab once while online only if needed for installation; the assessment application and its assets must then launch and operate with Wi-Fi and mobile data disabled.
6. Complete the tablet acceptance checklist before any participant session.

## Field-release requirements

A successful APK build is not research approval. Do not collect participant data until the signed study protocol, item bank, Kannada audio/font, ethics and data-governance decisions, export rules, supervisor controls and actual-device offline/timing tests have all been approved and recorded.
