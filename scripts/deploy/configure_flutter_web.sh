#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-build/web}"
INDEX_FILE="${OUTPUT_DIR}/index.html"
MANIFEST_FILE="${OUTPUT_DIR}/manifest.json"

if [[ ! -s "${INDEX_FILE}" || ! -s "${MANIFEST_FILE}" ]]; then
  echo "Flutter Web output is incomplete; expected index.html and manifest.json in ${OUTPUT_DIR}" >&2
  exit 1
fi

python3 - "${INDEX_FILE}" "${MANIFEST_FILE}" <<'PY'
import json
import sys
from pathlib import Path

index_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])

title = "ಪದLab | Kannada Word Reading Assessment"
description = (
    "ಪದLab is an offline-first Kannada word-reading assessment application "
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
html = html.replace(
    "<title>padalab_android</title>",
    f"<title>{title}</title>",
    1,
)
head_tags = []
if '<meta name="theme-color"' not in html:
    head_tags.append(f'<meta name="theme-color" content="{theme_color}">')
if '<meta name="robots"' not in html:
    head_tags.append(
        '<meta name="robots" content="noindex, nofollow, noarchive">'
    )
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
        "orientation": "any",
        "start_url": "/",
        "scope": "/",
    }
)
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + chr(10),
    encoding="utf-8",
)
PY

# Flutter Web assets are static. Generate a same-origin service worker that
# pre-caches the complete build, serves the shell offline, and waits for an
# assessor-requested update before replacing the running worker.
python3 - "${OUTPUT_DIR}" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

output = Path(sys.argv[1])
index = output / "index.html"
if not index.is_file():
    raise SystemExit("Flutter Web index.html is missing.")

files = sorted(
    path.relative_to(output).as_posix()
    for path in output.rglob("*")
    if path.is_file() and path.name not in {"service-worker.js"}
)
if "index.html" not in files or "main.dart.js" not in files:
    raise SystemExit("Flutter Web shell is missing index.html or main.dart.js.")

precache = ["/" + name for name in files]
# Include both paths and bytes. Flutter's entry-point paths (for
# example main.dart.js) can remain stable while their contents change.
fingerprint_hasher = hashlib.sha256()
for name in files:
    fingerprint_hasher.update(name.encode("utf-8"))
    fingerprint_hasher.update(b"\\0")
    fingerprint_hasher.update((output / name).read_bytes())
    fingerprint_hasher.update(b"\\0")
fingerprint = fingerprint_hasher.hexdigest()[:16]
manifest = json.dumps(precache, ensure_ascii=False, separators=(",", ":"))

worker = f"""/* Generated from the Flutter Web build; do not edit by hand. */
const CACHE_NAME = "padalab-shell-{fingerprint}";
const PRECACHE_URLS = {manifest};

self.addEventListener("install", (event) => {{
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
  );
}});

self.addEventListener("activate", (event) => {{
  event.waitUntil((async () => {{
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name.startsWith("padalab-shell-") && name !== CACHE_NAME)
      .map((name) => caches.delete(name)));
    await self.clients.claim();
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

  if (request.mode === "navigate") {{
    event.respondWith((async () => {{
      try {{
        const response = await fetch(request);
        if (response && response.ok) {{
          const cache = await caches.open(CACHE_NAME);
          await cache.put("/index.html", response.clone());
        }}
        return response;
      }} catch (_) {{
        return (await caches.match("/index.html")) || (await caches.match("/"));
      }}
    }})());
    return;
  }}

  event.respondWith((async () => {{
    const cached = await caches.match(request);
    if (cached) return cached;
    try {{
      const response = await fetch(request);
      if (response && response.ok) {{
        const cache = await caches.open(CACHE_NAME);
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

html = index.read_text(encoding="utf-8")
registration = """
<script>
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", function () {
      navigator.serviceWorker.register("/service-worker.js", { scope: "/" })
        .then(function (registration) {
          window.padlabServiceWorkerRegistration = registration;
        })
        .catch(function (error) {
          console.error("Padalab offline cache could not be registered.", error);
        });
    });
    navigator.serviceWorker.addEventListener("controllerchange", function () {
      window.location.reload();
    }, { once: true });
  }
</script>
"""
if "navigator.serviceWorker.register(\"/service-worker.js\"" not in html:
    html = html.replace("</body>", registration + "\n</body>", 1)
index.write_text(html, encoding="utf-8")
PY

test -s "${OUTPUT_DIR}/service-worker.js"
grep -q "navigator.serviceWorker.register" "${INDEX_FILE}"

grep -q "ಪದLab" "${INDEX_FILE}"
if grep -q "A new Flutter project" "${INDEX_FILE}" "${MANIFEST_FILE}"; then
  echo "Default Flutter scaffold metadata remains in the web output." >&2
  exit 1
fi
python3 -m json.tool "${MANIFEST_FILE}" >/dev/null

echo "Configured Padalab web metadata in ${OUTPUT_DIR}"
