#!/usr/bin/env bash
# Analyzer debt gate (RELEASE-PROOF-01)
#
# Runs `flutter analyze` and applies the checked-in baseline policy:
#   - errors   -> always blocking (exit 1)
#   - warnings -> always blocking (exit 1)
#   - infos    -> must not exceed tools/analyzer_baseline.txt
#
# Rationale: the repo carries a known info-level lint debt. We must not
# regress it (net-new findings fail) and must not permanently ship broad
# `--no-fatal-*` flags. When debt is deliberately reduced, lower the
# number in tools/analyzer_baseline.txt.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASELINE_FILE="tools/analyzer_baseline.txt"
if [ ! -f "$BASELINE_FILE" ]; then
  echo "FAIL: $BASELINE_FILE missing — commit it before enabling this gate."
  exit 1
fi

OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
flutter analyze 2>&1 | tee "$OUT" || true

ERRORS="$(grep -c 'error •' "$OUT" || true)"
WARNINGS="$(grep -c 'warning •' "$OUT" || true)"
INFOS="$(grep -c 'info •' "$OUT" || true)"

echo "analyzer: errors=$ERRORS warnings=$WARNINGS infos=$INFOS"

if [ "$ERRORS" -gt 0 ]; then
  echo "FAIL: analyzer errors are blocking."
  grep 'error •' "$OUT" | head -20
  exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
  echo "FAIL: analyzer warnings are blocking."
  grep 'warning •' "$OUT" | head -20
  exit 1
fi

BASELINE_INFOS="$(cat "$BASELINE_FILE")"
if [ "$INFOS" -gt "$BASELINE_INFOS" ]; then
  echo "FAIL: info-level findings grew from $BASELINE_INFOS to $INFOS."
  echo "      Fix the net-new findings, or if debt was reduced, lower the baseline."
  exit 1
fi

echo "PASS: analyzer within baseline (infos=$INFOS <= $BASELINE_INFOS)."
