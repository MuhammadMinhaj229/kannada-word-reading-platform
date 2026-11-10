#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

FLUTTER_VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/.flutter-version")"
FLUTTER_BIN="${HOME}/.cache/padalab/flutter-${FLUTTER_VERSION}/bin/flutter"

if [[ ! -x "${FLUTTER_BIN}" ]]; then
  bash scripts/deploy/install_flutter.sh
fi

export FLUTTER_ALLOW_ROOT=true

"${FLUTTER_BIN}" config --no-analytics --enable-web
"${FLUTTER_BIN}" create . --platforms=web --org org.phfi.cdlr --project-name padalab_android --no-pub
bash scripts/deploy/prepare_assets.sh
"${FLUTTER_BIN}" pub get --enforce-lockfile
"${FLUTTER_BIN}" build web --release --base-href /

bash scripts/deploy/configure_flutter_web.sh build/web

test -s build/web/index.html
test -s build/web/main.dart.js
echo "Flutter Web review bundle is ready at build/web"
