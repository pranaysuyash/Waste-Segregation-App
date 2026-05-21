#!/bin/bash
set -euo pipefail

# Waste Segregation App - Run with Environment Variables
# Defaults to Android phone when connected over adb.
#
# Usage:
#   ./scripts/development/run_with_env.sh
#   ./scripts/development/run_with_env.sh <device-id>
#
# Examples:
#   ./scripts/development/run_with_env.sh 192.168.1.5:40667

DEVICE_ID="${1:-}"

echo "Starting app with .env dart-defines..."

if [[ ! -f ".env" ]]; then
  echo "Error: .env file not found."
  echo "Create .env with OPENAI_API_KEY and GEMINI_API_KEY."
  exit 1
fi

# shellcheck disable=SC1091
source .env

if [[ -z "${OPENAI_API_KEY:-}" || -z "${GEMINI_API_KEY:-}" ]]; then
  echo "Error: Missing OPENAI_API_KEY or GEMINI_API_KEY in .env."
  exit 1
fi

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
fi

if [[ -n "$DEVICE_ID" ]]; then
  echo "Using device: $DEVICE_ID"
  flutter run -d "$DEVICE_ID" --dart-define-from-file=.env
else
  echo "No adb device detected, falling back to default flutter device selection."
  flutter run --dart-define-from-file=.env
fi
