#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[1/5] Functions build"
cd functions
npm install --include=dev >/dev/null
npm run build >/dev/null
npm run test:classify-image >/dev/null
cd "$ROOT"

echo "[2/5] Flutter scoped analyze"
flutter analyze \
  lib/services/google_drive_service.dart \
  lib/services/storage_service.dart \
  lib/services/ai_service.dart \
  lib/screens/auth_screen.dart \
  lib/services/offline_queue_service.dart \
  lib/services/ad_service.dart \
  lib/screens/image_capture_screen.dart >/dev/null || true

echo "[3/5] Firebase auth check"
if ! firebase functions:list --project waste-segregation-app-df523 >/dev/null 2>&1; then
  echo "ERROR: Firebase CLI auth invalid. Run: firebase login --reauth"
  exit 2
fi

echo "[4/5] Android local.properties checks"
if ! rg -q '^ADMOB_APP_ID=' android/local.properties 2>/dev/null; then
  echo "ERROR: Missing ADMOB_APP_ID in android/local.properties"
  exit 3
fi
APP_ID="$(rg '^ADMOB_APP_ID=' android/local.properties | sed 's/^ADMOB_APP_ID=//')"
if [[ "$APP_ID" == "ca-app-pub-3940256099942544~3347511713" ]]; then
  echo "ERROR: Test AdMob app id detected in android/local.properties"
  exit 4
fi

echo "[5/5] Release build"
flutter build appbundle --release --dart-define=USE_BACKEND_CLASSIFICATION=true

echo "SUCCESS: Release readiness run completed."
