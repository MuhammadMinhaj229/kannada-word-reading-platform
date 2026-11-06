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
import re
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
html = re.sub(
    r"<html(?:\\s+[^>]*)?>",
    '<html lang="en">',
    html,
    count=1,
    flags=re.IGNORECASE,
)
html = re.sub(
    r'<meta\\s+name="description"\\s+content="[^"]*"\\s*/?>',
    f'<meta name="description" content="{description}">',
    html,
    count=1,
    flags=re.IGNORECASE,
)
html = re.sub(
    r'<meta\\s+name="apple-mobile-web-app-title"\\s+content="[^"]*"\\s*/?>',
    '<meta name="apple-mobile-web-app-title" content="ಪದLab">',
    html,
    count=1,
    flags=re.IGNORECASE,
)
html = re.sub(
    r"<title>.*?</title>",
    f"<title>{title}</title>",
    html,
    count=1,
    flags=re.IGNORECASE | re.DOTALL,
)
if not re.search(r'<meta\\s+name="theme-color"', html, flags=re.IGNORECASE):
    html = html.replace(
        "</head>",
        f'<meta name="theme-color" content="{theme_color}">\\n</head>',
        1,
    )
if not re.search(r'<meta\\s+name="robots"', html, flags=re.IGNORECASE):
    html = html.replace(
        "</head>",
        '<meta name="robots" content="noindex, nofollow, noarchive">\\n</head>',
        1,
    )
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
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\\n",
    encoding="utf-8",
)
PY

grep -q "ಪದLab" "${INDEX_FILE}"
if grep -q "A new Flutter project" "${INDEX_FILE}" "${MANIFEST_FILE}"; then
  echo "Default Flutter scaffold metadata remains in the web output." >&2
  exit 1
fi

echo "Configured Padalab web metadata in ${OUTPUT_DIR}"
