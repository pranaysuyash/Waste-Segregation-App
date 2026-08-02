#!/usr/bin/env bash
# Format debt gate (RELEASE-PROOF-01)
#
# Runs `dart format --output=none --set-exit-if-changed` and fails only when a
# file NOT listed in tools/format_baseline.txt needs reformatting (net-new
# debt). Files already listed in the baseline are existing debt and are not
# re-blocked here; they are tracked with an owner and removal condition.
#
# To shrink debt: `dart format <files>`, then regenerate the baseline with:
#   dart format --output=none --set-exit-if-changed lib test integration_test \
#     2>/dev/null | grep '^Changed' | sed 's/^Changed //' | sort > tools/format_baseline.txt
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BASELINE_FILE="tools/format_baseline.txt"
if [ ! -f "$BASELINE_FILE" ]; then
  echo "FAIL: $BASELINE_FILE missing — commit it before enabling this gate."
  exit 1
fi

OUT="$(mktemp)"
RAW="$(mktemp)"
ERR="$(mktemp)"
trap 'rm -f "$OUT" "$RAW" "$ERR"' EXIT

# Capture stderr so a parse failure is distinguishable from "files need
# formatting" (which also exits non-zero). `dart format` exits 1 both when a
# file should be reformatted AND when a file cannot be parsed; the difference
# is that a parse failure produces no 'Changed' lines and a stderr error.
set +e
dart format --output=none --set-exit-if-changed lib test integration_test \
  >"$RAW" 2>"$ERR"
FORMAT_EXIT=$?
set -e

grep '^Changed' "$RAW" | sed 's/^Changed //' | sort > "$OUT" || true

# If dart format failed and produced no 'Changed' lines, it is a parse/IO
# error, not formatting debt — fail loudly instead of passing on a broken file.
if [ "$FORMAT_EXIT" -ne 0 ] && [ ! -s "$OUT" ]; then
  echo "FAIL: dart format errored (exit $FORMAT_EXIT) — likely a file cannot be parsed:"
  grep -v '^$' "$ERR" | head -20
  exit 1
fi

# comm -13: lines only present in the second file (net-new changes).
NET_NEW="$(comm -13 <(sort "$BASELINE_FILE") "$OUT")"
if [ -n "$NET_NEW" ]; then
  echo "FAIL: net-new formatting debt detected in files:"
  echo "$NET_NEW"
  echo "      Run 'dart format <file>' on them, or regenerate the baseline."
  exit 1
fi

echo "PASS: no net-new formatting debt (baseline covers $(wc -l < "$BASELINE_FILE" | tr -d ' ') files)."
