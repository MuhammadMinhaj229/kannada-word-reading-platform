#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/.flutter-version")"
CACHE_ROOT="${HOME}/.cache/padalab"
FLUTTER_ROOT="${CACHE_ROOT}/flutter-${FLUTTER_VERSION}"

mkdir -p "${CACHE_ROOT}"

if [[ ! -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
  ARCHIVE="${CACHE_ROOT}/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

  echo "Downloading pinned Flutter SDK ${FLUTTER_VERSION}"
  curl --fail --location --retry 3 --retry-delay 2 "${URL}" --output "${ARCHIVE}"
  tar -xJf "${ARCHIVE}" -C "${CACHE_ROOT}"
  mv "${CACHE_ROOT}/flutter" "${FLUTTER_ROOT}"
  rm -f "${ARCHIVE}"
fi

# Vercel's build container invokes custom commands as root. Flutter's SDK is
# itself a Git checkout; mark only this exact SDK directory as trusted before
# the Flutter tool runs its version checks (never trust all Git directories).
git config --global --add safe.directory "${FLUTTER_ROOT}"
export FLUTTER_ALLOW_ROOT=true

"${FLUTTER_ROOT}/bin/flutter" config --no-analytics --enable-web
"${FLUTTER_ROOT}/bin/flutter" precache --web

echo "Flutter ${FLUTTER_VERSION} is ready at ${FLUTTER_ROOT}"
