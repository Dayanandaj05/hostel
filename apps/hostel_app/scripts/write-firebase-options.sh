#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${FIREBASE_OPTIONS_DART:-}" ]]; then
  echo "Missing FIREBASE_OPTIONS_DART environment variable"
  exit 1
fi

cat > lib/firebase_options.dart <<'EOF'
${FIREBASE_OPTIONS_DART}
EOF

echo "Wrote lib/firebase_options.dart"
