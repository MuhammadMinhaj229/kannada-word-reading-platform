#!/usr/bin/env python3
"""Validate PadLab's generated offline Flutter Web/PWA bundle."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"Flutter Web output validation failed: {message}")


def main() -> int:
    output = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web")
    required = (
        "index.html",
        "main.dart.js",
        "manifest.json",
        "service-worker.js",
        "app-release.json",
    )
    for name in required:
        if not (output / name).is_file():
            fail(f"missing {name}")

    index = (output / "index.html").read_text(encoding="utf-8")
    worker = (output / "service-worker.js").read_text(encoding="utf-8")
    manifest = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
    release = json.loads((output / "app-release.json").read_text(encoding="utf-8"))

    if 'navigator.serviceWorker.register("/service-worker.js"' not in index:
        fail("index.html does not register the PadLab service worker")
    if "controllerchange" in index or "location.reload()" in index:
        fail("index.html contains an automatic reload handler")
    activate_start = worker.find('self.addEventListener("activate"')
    message_start = worker.find('self.addEventListener("message"')
    fetch_start = worker.find('self.addEventListener("fetch"')
    if min(activate_start, message_start, fetch_start) < 0:
        fail("service worker lifecycle handlers are incomplete")
    activate_handler = worker[activate_start:message_start]
    message_handler = worker[message_start:fetch_start]
    if "await self.clients.claim();" not in activate_handler:
        fail("service worker must claim clients after precache activation")
    if (
        'event.data.type === "SKIP_WAITING"' not in message_handler
        or "self.skipWaiting();" not in message_handler
    ):
        fail("service worker must activate waiting updates only after an explicit message")
    if "self.skipWaiting();" in worker.replace(message_handler, ""):
        fail("service worker contains an automatic skipWaiting path")
    if 'request.mode === "navigate"' not in worker:
        fail("service worker is missing its offline navigation fallback")

    if manifest.get("display") != "standalone" or manifest.get("scope") != "/":
        fail("PWA manifest must be standalone and scoped to the root")
    if not isinstance(manifest.get("icons"), list) or not manifest["icons"]:
        fail("PWA manifest has no install icons")
    if not release.get("commit") or not release.get("version"):
        fail("release manifest must identify app version and source commit")
    if release.get("webRole") != "interactive_online_workspace":
        fail("release manifest does not identify the Vercel online workspace")
    if release.get("androidRole") != "offline_android_build":
        fail("release manifest does not identify the offline Android build")
    if release.get("androidOfflineCapable") is not True:
        fail("Android build must be marked offline-capable")
    if release.get("participantDataEntry") is not False:
        fail("participant data entry must remain disabled in the browser")
    features = release.get("webFeatures")
    required_features = {"item-bank-review", "settings", "task-preview", "release-readiness"}
    if not isinstance(features, list) or not required_features.issubset(set(features)):
        fail("online workspace feature metadata is incomplete")
    if release.get("participantReady") is not False:
        fail("engineering preview must remain explicitly non-field-ready")
    if release.get("participantDataSync") is not False:
        fail("participant data sync must remain disabled")
    if not release.get("apkDownloadUrl", "").endswith(
        "/padalab-android-arm64-debug.apk"
    ):
        fail("release manifest does not point to the engineering-preview APK")

    match = re.search(r"const PRECACHE_URLS = (\[.*?\]);", worker, re.DOTALL)
    if not match:
        fail("service worker has no generated precache list")
    precache = json.loads(match.group(1))
    for path in (
        "/index.html",
        "/main.dart.js",
        "/manifest.json",
        "/app-release.json",
    ):
        if path not in precache:
            fail(f"{path} is not precached for offline use")
    if len(precache) < 5:
        fail("precache manifest looks unexpectedly small")

    cache_names = re.findall(r'const CACHE_NAME = "([^"]+)"', worker)
    if len(cache_names) != 1 or not cache_names[0].startswith("padalab-shell-"):
        fail("content-derived PadLab shell cache name is missing")

    print(
        "Flutter Web output: PWA manifest, offline precache, "
        "manual update lifecycle and APK metadata PASS"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
