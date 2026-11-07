#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FONT_SOURCE="${ROOT_DIR}/assets/fonts/NotoSansKannada.ttf.b64"
FONT_OUTPUT="${ROOT_DIR}/assets/fonts/NotoSansKannada.ttf"
EXPECTED_GIT_BLOB_SHA="8a3ff863d2d742be0583d5602ea1b1637dcec939"

if [[ ! -s "${FONT_SOURCE}" ]]; then
  echo "Bundled Noto Sans Kannada source is missing." >&2
  exit 1
fi

python3 - "${FONT_SOURCE}" "${FONT_OUTPUT}" <<'PY'
import base64
import sys
from pathlib import Path

source = Path(sys.argv[1])
destination = Path(sys.argv[2])
try:
    encoded = source.read_text(encoding="ascii")
    font = base64.b64decode(encoded, validate=True)
except (OSError, UnicodeError, ValueError) as error:
    raise SystemExit(f"Could not decode the bundled Kannada font: {error}")

# TrueType sfnt signature. Reject truncated or malformed payloads.
if len(font) < 100_000 or font[:4] != b"\x00\x01\x00\x00":
    raise SystemExit("The bundled Kannada font failed its TrueType integrity check.")

destination.write_bytes(font)
print(f"Prepared offline Kannada font ({len(font)} bytes).")
PY

ACTUAL_GIT_BLOB_SHA="$(git -C "${ROOT_DIR}" hash-object "${FONT_OUTPUT}")"
if [[ "${ACTUAL_GIT_BLOB_SHA}" != "${EXPECTED_GIT_BLOB_SHA}" ]]; then
  echo "Bundled Noto Sans Kannada font hash mismatch." >&2
  exit 1
fi

echo "Bundled Noto Sans Kannada 2.006 verified."
