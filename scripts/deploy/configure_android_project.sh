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
grep -q 'screenOrientation="landscape"' "${MANIFEST}"
grep -q 'allowBackup="false"' "${MANIFEST}"
test -s android/app/proguard-rules.pro

echo "Configured Padalab Android host: API 26+, landscape, backup disabled, SQLCipher shrinker rules"
