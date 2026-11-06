#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${1:-build/web}"

if [[ ! -s "${OUTPUT_DIR}/index.html" ]]; then
  echo "Flutter Web output is missing: ${OUTPUT_DIR}/index.html" >&2
  exit 1
fi

# Flutter 3.47 does not yet provide --web-content-hash. Revalidate browser
# assets on launch so an installed browser app can fetch the latest release
# after reconnecting. Do not force-reload an assessment while it is running.
cat > "${OUTPUT_DIR}/_headers" <<'EOF'
/*
  Cache-Control: no-cache, must-revalidate
EOF

echo "Configured revalidation headers in ${OUTPUT_DIR}/_headers"
