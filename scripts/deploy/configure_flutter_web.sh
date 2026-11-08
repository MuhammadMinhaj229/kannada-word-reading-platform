#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="\${1:-build/web}"
INDEX_FILE="\${OUTPUT_DIR}/index.html"
MANIFEST_FILE="\${OUTPUT_DIR}/manifest.json"

if [[ ! -s "\${INDEX_FILE}" || ! -s "\${MANIFEST_FILE}" ]]; then
  echo "Flutter Web output is incomplete; expected index.html and manifest.json in \${OUTPUT_DIR}" >&2
  exit 1
fi

python3 - "\${INDEX_FILE}" "\${MANIFEST_FILE}" <<'PY'
import json
import sys
from pathlib import Path

index_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
title = "ಪದLab | Kannada Word Reading Assessment"
description = (
    "PadLab is an offline-first Kannada word-reading assessment application "
    "for authorised research assessors."
)
theme_color = "#0F766E"
background_color = "#F7F8F2"

html = index_path.read_text(encoding="utf-8")
html = html.replace("<html>", '<html lang="en">', 1)
html = html.replace(
    '<meta name="description" content="A new Flutter project.">',
    f'<meta name="description" content="{description}">',
    1,
)
html = html.replace(
    '<meta name="apple-mobile-web-app-title" content="padalab_android">',
    '<meta name="apple-mobile-web-app-title" content="ಪದLab">',
    1,
)
html = html.replace("<title>padalab_android</title>", f"<title>{title}</title>", 1)
head_tags = []
if '<meta name="theme-color"' not in html:
    head_tags.append(f'<meta name="theme-color" content="{theme_color}">')
if '<meta name="robots"' not in html:
    head_tags.append('<meta name="robots" content="noindex, nofollow, noarchive">')
if '<meta name="apple-mobile-web-app-capable"' not in html:
    head_tags.append('<meta name="apple-mobile-web-app-capable" content="yes">')
if '<meta name="mobile-web-app-capable"' not in html:
    head_tags.append('<meta name="mobile-web-app-capable" content="yes">')
if head_tags:
    newline = chr(10)
    html = html.replace(
        "</head>",
        newline + "  " + (newline + "  ").join(head_tags) + newline + "</head>",
        1,
    )
if "<title>padalab_android</title>" in html:
    raise SystemExit("Default Flutter page title was not replaced.")
index_path.write_text(html, encoding="utf-8")

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest.update(
    {
        "name": title,
        "short_name": "ಪದLab",
        "description": description,
        "theme_color": theme_color,
        "background_color": background_color,
        "display": "standalone",
        "display_override": ["standalone", "minimal-ui"],
        "orientation": "any",
        "start_url": "/",
        "scope": "/",
        "prefer_related_applications": False,
        "categories": ["education", "productivity"],
    }
)
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + chr(10),
    encoding="utf-8",
)
PY

python3 - "\${OUTPUT_DIR}" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

root = Path.cwd()
output = Path(sys.argv[1])
pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
match = re.search(r"(?m)^version:\s*([^\s#]+)", pubspec)
if not match:
    raise SystemExit("Could not read PadLab version from pubspec.yaml.")

release = {
    "application": "PadLab",
    "version": match.group(1),
    "commit": (
        os.environ.get("VERCEL_GIT_COMMIT_SHA")
        or os.environ.get("GITHUB_SHA")
        or "local"
    ),
    "channel": "engineering-preview",
    "apkDownloadUrl": (
        "https://github.com/MuhammadMinhaj229/kannada-word-reading-platform/releases/download/"
        "padalab-preview/padalab-android-arm64-debug.apk"
    ),
    "apkSigning": "debug",
    "participantReady": False,
    "participantDataSync": False,
    "webUpdateMode": "manual-user-triggered",
}
(output / "app-release.json").write_text(
    json.dumps(release, ensure_ascii=False, indent=2) + chr(10),
    encoding="utf-8",
)
PY

python3 - "\${OUTPUT_DIR}" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

output = Path(sys.argv[1])
required = {"index.html", "main.dart.js", "manifest.json", "app-release.json"}
files = sorted(
    path.relative_to(output).as_posix()
    for path in output.rglob("*")
    if path.is_file() and path.name != "service-worker.js"
)
missing = sorted(required.difference(files))
if missing:
    raise SystemExit("Flutter Web output is missing: " + ", ".join(missing))

hasher = hashlib.sha256()
for name in files:
    hasher.update(name.encode("utf-8"))
    hasher.update(b"\0")
    hasher.update((output / name).read_bytes())
    hasher.update(b"\0")
fingerprint = hasher.hexdigest()[:16]
precache = ["/" + name for name in files]
precache_json = json.dumps(precache, ensure_ascii=False, separators=(",", ":"))

worker = f"""/* Generated from the Flutter Web build; do not edit by hand. */
const CACHE_NAME = "padalab-shell-{fingerprint}";
const PRECACHE_URLS = {precache_json};

self.addEventListener("install", (event) => {{
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
  );
}});
// First install does not immediately take control of an open page.
// A waiting update activates only after the user presses Refresh app.
self.addEventListener("activate", (event) => {{
  event.waitUntil((async () => {{
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name.startsWith("padalab-shell-") && name !== CACHE_NAME)
      .map((name) => caches.delete(name)));
  }})());
}});
self.addEventListener("message", (event) => {{
  if (event.data && event.data.type === "SKIP_WAITING") {{
    self.skipWaiting();
  }}
}});
self.addEventListener("fetch", (event) => {{
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== "GET" || url.origin !== self.location.origin) return;

  event.respondWith((async () => {{
    const cache = await caches.open(CACHE_NAME);
    if (request.mode === "navigate") {{
      try {{
        const response = await fetch(request);
        if (response && response.ok) await cache.put("/index.html", response.clone());
        return response;
      }} catch (_) {{
        return (await cache.match("/index.html")) || (await cache.match("/"));
      }}
    }}

    const cached = await cache.match(request);
    if (cached) return cached;
    try {{
      const response = await fetch(request);
      if (response && response.ok && response.type !== "opaque") {{
        await cache.put(request, response.clone());
      }}
      return response;
    }} catch (_) {{
      return Response.error();
    }}
  }})());
}});
"""
(output / "service-worker.js").write_text(worker, encoding="utf-8")

registration = """
<script>
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", function () {
      navigator.serviceWorker.register("/service-worker.js", { scope: "/" })
        .then(function (registration) {
          window.padlabServiceWorkerRegistration = registration;
        })
        .catch(function (error) {
          console.error("PadLab offline cache registration failed.", error);
        });
    });
  }
</script>
"""
index = output / "index.html"
html = index.read_text(encoding="utf-8")
if 'navigator.serviceWorker.register("/service-worker.js"' not in html:
    html = html.replace("</body>", registration + "\n</body>", 1)
index.write_text(html, encoding="utf-8")
PY

test -s "\${OUTPUT_DIR}/service-worker.js"
test -s "\${OUTPUT_DIR}/app-release.json"
python3 -m json.tool "\${MANIFEST_FILE}" >/dev/null
python3 -m json.tool "\${OUTPUT_DIR}/app-release.json" >/dev/null
python3 scripts/deploy/validate_flutter_web_output.py "\${OUTPUT_DIR}"

echo "Configured PadLab offline PWA metadata and manual update flow in \${OUTPUT_DIR}"
