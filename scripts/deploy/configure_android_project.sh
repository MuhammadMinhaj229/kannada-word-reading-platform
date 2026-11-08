#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

APP_GRADLE="android/app/build.gradle.kts"
MANIFEST="android/app/src/main/AndroidManifest.xml"

if [[ ! -s "${APP_GRADLE}" || ! -s "${MANIFEST}" ]]; then
  echo "Android host scaffold is missing. Run flutter create --platforms=android first." >&2
  exit 1
fi

python3 - "${APP_GRADLE}" "${MANIFEST}" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

gradle_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
gradle = gradle_path.read_text(encoding="utf-8")

expected_app_id = "org.phfi.cdlr.padalab_android"
if f'applicationId = "{expected_app_id}"' not in gradle:
    raise SystemExit(
        "Unexpected Android applicationId. Confirm the permanent PHFI package "
        "identifier before changing it; do not silently generate a new ID."
    )

if "minSdk = flutter.minSdkVersion" in gradle:
    gradle = gradle.replace(
        "minSdk = flutter.minSdkVersion",
        "minSdk = 26",
        1,
    )
elif "minSdk = 26" not in gradle:
    raise SystemExit("Could not enforce the Android 8.0 (API 26) minimum SDK.")

# Never inherit Flutter's template release signing with the debug key.
# A signed release is configured only when a protected, local key.properties
# file is created by the CI secret-injection step.
debug_release = 'signingConfig = signingConfigs.getByName("debug")'
if debug_release in gradle:
    gradle = gradle.replace(
        debug_release,
        "// Release signing is injected from a protected key.properties file.",
        1,
    )

signing_block = """
import java.io.FileInputStream
import java.util.Properties

val padalabSigningProperties = Properties()
val padalabSigningFile = rootProject.file("key.properties")
if (padalabSigningFile.exists()) {
    FileInputStream(padalabSigningFile).use { stream ->
        padalabSigningProperties.load(stream)
    }
}
val padalabReleaseSigningReady = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword",
).all { !padalabSigningProperties.getProperty(it).isNullOrBlank() }

"""
if "val padalabSigningProperties = Properties()" not in gradle:
    gradle = gradle.replace("android {", signing_block + "android {", 1)

release_marker = """
    buildTypes {
        release {
"""
release_config = """
    signingConfigs {
        if (padalabReleaseSigningReady) {
            create("release") {
                keyAlias = padalabSigningProperties.getProperty("keyAlias")
                keyPassword = padalabSigningProperties.getProperty("keyPassword")
                storeFile = file(padalabSigningProperties.getProperty("storeFile"))
                storePassword = padalabSigningProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (padalabReleaseSigningReady) {
                signingConfigs.getByName("release")
            } else {
                null
            }
"""
if "padalabReleaseSigningReady" not in gradle[gradle.find("android {"):]:
    if release_marker not in gradle:
        raise SystemExit("Could not locate Android release build type block.")
    gradle = gradle.replace(release_marker, release_config, 1)

if debug_release in gradle:
    raise SystemExit("Debug signing remains configured for release builds.")
if "signingConfig = if (padalabReleaseSigningReady)" not in gradle:
    raise SystemExit("Conditional release signing and unsigned fallback were not configured.")

# Enable Android R8 shrinking/obfuscation for release builds and keep SQLCipher's
# native/reflection entry points. Flutter's Dart AOT compilation is separate.
release_block = """        release {
"""
release_hardening = """        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
"""
if "isMinifyEnabled = true" not in gradle:
    if release_block not in gradle:
        raise SystemExit("Could not find release build type for R8 hardening.")
    gradle = gradle.replace(release_block, release_hardening, 1)

# Filter native Android plugin libraries to the single supported tablet ABI.
default_config_marker = """    defaultConfig {
"""
arm64_filter = """    defaultConfig {
        ndk {
            abiFilters += "arm64-v8a"
        }
"""
if 'abiFilters += "arm64-v8a"' not in gradle:
    if default_config_marker not in gradle:
        raise SystemExit("Could not locate Android defaultConfig block for ABI filtering.")
    gradle = gradle.replace(default_config_marker, arm64_filter, 1)

# Some AARs (notably SQLCipher) ship several ABI variants. Gradle's
# ndk.abiFilters does not consistently strip all prebuilt AAR libraries, so
# exclude unsupported ABIs explicitly from the final APK as well.
packaging_marker = """    buildTypes {
"""
arm64_packaging = """    packaging {
        jniLibs {
            excludes += setOf(
                "lib/armeabi-v7a/**",
                "lib/x86/**",
                "lib/x86_64/**"
            )
        }
    }

    buildTypes {
"""
if 'lib/armeabi-v7a/**' not in gradle:
    if packaging_marker not in gradle:
        raise SystemExit("Could not locate Android buildTypes block for ABI packaging exclusions.")
    gradle = gradle.replace(packaging_marker, arm64_packaging, 1)

gradle_path.write_text(gradle, encoding="utf-8")

android_ns = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", android_ns)
tree = ET.parse(manifest_path)
root = tree.getroot()
application = root.find("application")
if application is None:
    raise SystemExit("Android manifest does not contain an application element.")

internet_permission = "{http://schemas.android.com/apk/res/android}name"
has_internet = any(
    element.tag == "uses-permission"
    and element.get(internet_permission) == "android.permission.INTERNET"
    for element in root.findall("uses-permission")
)
if not has_internet:
    permission = ET.Element("uses-permission")
    permission.set(internet_permission, "android.permission.INTERNET")
    root.insert(0, permission)

def attr(name: str) -> str:
    return f"{{{android_ns}}}{name}"

application.set(attr("label"), "ಪದLab")
application.set(attr("allowBackup"), "false")
application.set(attr("fullBackupContent"), "false")
application.set(attr("usesCleartextTraffic"), "false")

main_activity = None
for activity in application.findall("activity"):
    name = activity.get(attr("name"), "")
    if name.endswith("MainActivity"):
        main_activity = activity
        break
if main_activity is None:
    raise SystemExit("Android MainActivity was not found in the manifest.")

# Android 11+ package visibility: allow the local system TTS service to be queried.
queries = root.find("queries")
if queries is None:
    queries = ET.Element("queries")
    root.insert(list(root).index(application), queries)
has_tts_query = any(
    action.get(attr("name")) == "android.intent.action.TTS_SERVICE"
    for intent in queries.findall("intent")
    for action in intent.findall("action")
)
if not has_tts_query:
    intent = ET.SubElement(queries, "intent")
    action = ET.SubElement(intent, "action")
    action.set(attr("name"), "android.intent.action.TTS_SERVICE")

main_activity.set(attr("screenOrientation"), "landscape")
main_activity.set(attr("exported"), "true")
tree.write(manifest_path, encoding="utf-8", xml_declaration=True)
PY

# Pin the generated Gradle wrapper to Gradle's direct distribution CDN and
# verify the archive before Gradle executes it. The standard services.gradle.org
# URL redirected this CI runner to a GitHub release asset that returned 504;
# downloads.gradle-dn.com is also an official Gradle distribution host.
WRAPPER_PROPERTIES="android/gradle/wrapper/gradle-wrapper.properties"
if [[ ! -s "${WRAPPER_PROPERTIES}" ]]; then
  echo "Generated Android Gradle wrapper properties are missing." >&2
  exit 1
fi
python3 - "${WRAPPER_PROPERTIES}" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
properties = {
    "distributionBase": "GRADLE_USER_HOME",
    "distributionPath": "wrapper/dists",
    "distributionUrl": (
        r"https\://downloads.gradle-dn.com/distributions/gradle-9.3.1-bin.zip"
    ),
    "distributionSha256Sum": (
        "b266d5ff6b90eada6dc3b20cb090e3731302e553a27c5d3e4df1f0d76beaff06"
    ),
    "networkTimeout": "120000",
    "retries": "3",
    "retryBackOffMs": "1000",
    "zipStoreBase": "GRADLE_USER_HOME",
    "zipStorePath": "wrapper/dists",
}

path.write_text(
    "".join(f"{key}={value}\n" for key, value in properties.items()),
    encoding="utf-8",
)
PY

grep -Fq 'distributionUrl=https\://downloads.gradle-dn.com/distributions/gradle-9.3.1-bin.zip' "${WRAPPER_PROPERTIES}"
grep -Fq 'distributionSha256Sum=b266d5ff6b90eada6dc3b20cb090e3731302e553a27c5d3e4df1f0d76beaff06' "${WRAPPER_PROPERTIES}"
grep -Fq 'retries=3' "${WRAPPER_PROPERTIES}"

mkdir -p android/app
cat > android/app/proguard-rules.pro <<'RULES'
# SQLCipher uses reflective/native entry points. Keep these classes intact
# when the release build enables R8/ProGuard shrinking.
-keep class net.sqlcipher.** { *; }
-keep class net.zetetic.** { *; }
RULES

grep -q 'minSdk = 26' "${APP_GRADLE}"
grep -q 'applicationId = "org.phfi.cdlr.padalab_android"' "${APP_GRADLE}"
grep -q 'abiFilters += "arm64-v8a"' "${APP_GRADLE}"
grep -q 'lib/armeabi-v7a/\*\*' "${APP_GRADLE}"
grep -q 'lib/x86_64/\*\*' "${APP_GRADLE}"
grep -q 'signingConfig = if (padalabReleaseSigningReady)' "${APP_GRADLE}"
! grep -q 'signingConfig = signingConfigs.getByName("debug")' "${APP_GRADLE}"
grep -q 'screenOrientation="landscape"' "${MANIFEST}"
grep -q 'allowBackup="false"' "${MANIFEST}"
test -s android/app/proguard-rules.pro
grep -q 'android.permission.INTERNET' "${MANIFEST}"
grep -q 'android.intent.action.TTS_SERVICE' "${MANIFEST}"
grep -q 'isMinifyEnabled = true' "${APP_GRADLE}"
grep -q 'isShrinkResources = true' "${APP_GRADLE}"

# Flutter's Gradle settings plugin loads this machine-local SDK path before
# Gradle configures the Android project. Never commit this file.
if [[ -z "${FLUTTER_ROOT:-}" || ! -d "${FLUTTER_ROOT:-/nonexistent}" ]]; then
  FLUTTER_BIN="$(command -v flutter || true)"
  if [[ -z "${FLUTTER_BIN}" ]]; then
    echo "Flutter SDK not found; set FLUTTER_ROOT or add flutter to PATH." >&2
    exit 1
  fi
  FLUTTER_ROOT="$(cd "$(dirname "${FLUTTER_BIN}")/.." && pwd)"
fi
printf 'flutter.sdk=%s\n' "${FLUTTER_ROOT}" > android/local.properties
chmod 600 android/local.properties

echo "Configured Padalab Android host. Release signing: ${PADALAB_RELEASE_SIGNING_READY:-configured only via android/key.properties}"
