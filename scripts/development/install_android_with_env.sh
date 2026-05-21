#!/bin/bash
set -euo pipefail

# Build + install Android debug APK with .env dart-defines.
# Usage:
#   ./scripts/development/install_android_with_env.sh
#   ./scripts/development/install_android_with_env.sh <device-id>
# Example:
#   ./scripts/development/install_android_with_env.sh 192.168.1.5:40667

DEVICE_ID="${1:-}"

if [[ ! -f ".env" ]]; then
  echo "Error: .env not found in repo root."
  exit 1
fi

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "Error: no adb-connected Android device found."
  echo "Pass device id manually: $0 <device-id>"
  exit 1
fi

echo "Building debug APK with --dart-define-from-file=.env ..."
flutter build apk --debug --dart-define-from-file=.env

APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo "Error: APK not found at $APK_PATH"
  exit 1
fi

echo "Installing to $DEVICE_ID ..."
adb -s "$DEVICE_ID" install -r "$APK_PATH"

echo "Launching app ..."
adb -s "$DEVICE_ID" shell am force-stop com.pranaysuyash.wastewise || true
adb -s "$DEVICE_ID" shell am start -n com.pranaysuyash.wastewise/.MainActivity

echo "Done. Installed build includes .env keys via dart-defines."
