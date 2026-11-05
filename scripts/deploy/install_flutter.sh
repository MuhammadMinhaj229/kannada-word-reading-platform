#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/.flutter-version")"
CACHE_ROOT="${HOME}/.cache/padalab"
FLUTTER_ROOT="${CACHE_ROOT}/flutter-${FLUTTER_VERSION}"

if [[ -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
  echo "Using cached Flutter ${FLUTTER_VERSION} at ${FLUTTER_ROOT}"
  exit 0
fi

mkdir -p "${CACHE_ROOT}"
ARCHIVE="${CACHE_ROOT}/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "Downloading pinned Flutter SDK ${FLUTTER_VERSION}"
curl --fail --location --retry 3 --retry-delay 2 "${URL}" --output "${ARCHIVE}"
tar -xJf "${ARCHIVE}" -C "${CACHE_ROOT}"
mv "${CACHE_ROOT}/flutter" "${FLUTTER_ROOT}"
rm -f "${ARCHIVE}"

"${FLUTTER_ROOT}/bin/flutter" config --no-analytics --enable-web
"${FLUTTER_ROOT}/bin/flutter" precache --web

echo "Installed Flutter ${FLUTTER_VERSION}"
