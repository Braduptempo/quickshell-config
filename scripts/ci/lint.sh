#!/usr/bin/env bash
# Static checks for the Quickshell config. Runs locally and in CI.
#
# Fails on:
#   - qmldir entries that point to files that don't exist
#   - QML syntax errors (qmllint exit code != 0)
#   - [import] warnings: missing files or types
#   - more qmllint warnings than the baseline in .ci/qmllint-baseline
#
# Usage: scripts/ci/lint.sh            check
#        scripts/ci/lint.sh --update   write the current warning count as the new baseline

set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2

QMLLINT="${QMLLINT:-/usr/lib/qt6/bin/qmllint}"
BASELINE_FILE=".ci/qmllint-baseline"
failed=0

fail() { echo "::error::$*"; failed=1; }

if [ ! -x "$QMLLINT" ]; then
  echo "qmllint not found at $QMLLINT (install qt6-declarative, or set QMLLINT)"
  exit 2
fi

# --- 1. qmldir paths ---------------------------------------------------------
echo "== qmldir"
while read -r first _ third fourth; do
  # skip comments, blank lines and the module line
  case "$first" in ''|'#'*|module) continue ;; esac
  # "singleton Name 1.0 path" or "Name 1.0 path"
  if [ "$first" = "singleton" ]; then path="$fourth"; else path="$third"; fi
  [ -z "$path" ] && continue
  if [ ! -f "$path" ]; then
    fail "qmldir: '$path' does not exist"
  fi
done < qmldir

# --- 2. qmllint --------------------------------------------------------------
# Tracked and new (untracked, not ignored) files, so a local run sees what CI will see
echo "== qmllint"
warnings=0
while IFS= read -r file; do
  out="$("$QMLLINT" "$file" 2>&1)"
  rc=$?
  if [ $rc -ne 0 ]; then
    fail "$file: qmllint exit code $rc (syntax error)"
    echo "$out"
  fi
  # Quickshell registers `pragma Singleton` files itself, so qmllint's
  # "not declared as singleton in qmldir" is a false positive.
  imports="$(echo "$out" | grep -E '\[import\]$' | grep -v 'not declared as singleton in qmldir' || true)"
  if [ -n "$imports" ]; then
    while IFS= read -r line; do fail "$line"; done <<< "$imports"
  fi
  count="$(echo "$out" | grep -c '^Warning:' || true)"
  warnings=$((warnings + count))
done < <(git ls-files --cached --others --exclude-standard '*.qml')

echo "qmllint warnings: $warnings"

if [ "${1:-}" = "--update" ]; then
  echo "$warnings" > "$BASELINE_FILE"
  echo "Baseline updated to $warnings"
else
  baseline="$(cat "$BASELINE_FILE" 2>/dev/null || echo 0)"
  if [ "$warnings" -gt "$baseline" ]; then
    fail "qmllint warnings went up: $warnings (baseline $baseline). Fix the new ones, or run 'scripts/ci/lint.sh --update' if they are false positives."
  elif [ "$warnings" -lt "$baseline" ]; then
    echo "Fewer warnings than the baseline ($baseline). Run 'scripts/ci/lint.sh --update' to lock this in."
  fi
fi

# --- 3. shell scripts ---------------------------------------------------------
echo "== shellcheck"
if command -v shellcheck >/dev/null; then
  mapfile -t scripts < <(git ls-files --cached --others --exclude-standard '*.sh')
  if [ ${#scripts[@]} -gt 0 ] && ! shellcheck -S warning "${scripts[@]}"; then
    fail "shellcheck found problems"
  fi
else
  echo "shellcheck not installed, skipped"
fi

if [ $failed -ne 0 ]; then
  echo "Lint failed"
  exit 1
fi
echo "Lint passed"
