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
import re
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
if "signingConfig = null" not in gradle:
    raise SystemExit("Unsigned release fallback was not configured.")

gradle_path.write_text(gradle, encoding="utf-8")

android_ns = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", android_ns)
tree = ET.parse(manifest_path)
root = tree.getroot()
application = root.find("application")
if application is None:
    raise SystemExit("Android manifest does not contain an application element.")

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

main_activity.set(attr("screenOrientation"), "landscape")
main_activity.set(attr("exported"), "true")
tree.write(manifest_path, encoding="utf-8", xml_declaration=True)
PY

mkdir -p android/app
cat > android/app/proguard-rules.pro <<'RULES'
# SQLCipher uses reflective/native entry points. Keep these classes intact
# when the release build enables R8/ProGuard shrinking.
-keep class net.sqlcipher.** { *; }
-keep class net.zetetic.** { *; }
RULES

grep -q 'minSdk = 26' "${APP_GRADLE}"
grep -q 'applicationId = "org.phfi.cdlr.padalab_android"' "${APP_GRADLE}"
grep -q 'signingConfig = null' "${APP_GRADLE}"
! grep -q 'signingConfig = signingConfigs.getByName("debug")' "${APP_GRADLE}"
grep -q 'screenOrientation="landscape"' "${MANIFEST}"
grep -q 'allowBackup="false"' "${MANIFEST}"
test -s android/app/proguard-rules.pro

echo "Configured Padalab Android host. Release signing: ${PADALAB_RELEASE_SIGNING_READY:-configured only via android/key.properties}"
