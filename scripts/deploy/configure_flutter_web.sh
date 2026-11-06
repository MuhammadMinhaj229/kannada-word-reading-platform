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

grep -q "ಪದLab" "${INDEX_FILE}"
if grep -q "A new Flutter project" "${INDEX_FILE}" "${MANIFEST_FILE}"; then
  echo "Default Flutter scaffold metadata remains in the web output." >&2
  exit 1
fi
python3 -m json.tool "${MANIFEST_FILE}" >/dev/null

echo "Configured Padalab web metadata in ${OUTPUT_DIR}"
