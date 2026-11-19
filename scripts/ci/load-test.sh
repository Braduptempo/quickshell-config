#!/usr/bin/env bash
# Starts the config for a few seconds and fails on load or JavaScript errors.
#
# In CI there is no desktop, so it starts a headless sway (wlroots) first.
# Locally it uses your running session: you will briefly see a second bar.
#
# Usage: scripts/ci/load-test.sh [config dir]
#   QS_TEST_SECONDS=8   how long to run
#   QS_TEST_HEADLESS=1  force a headless compositor (CI sets this)

set -uo pipefail
CONFIG_DIR="$(realpath "${1:-$(dirname "$0")/../..}")"
RUN_SECONDS="${QS_TEST_SECONDS:-8}"
LOG="$(mktemp)"
SWAY_PID=""

cleanup() { [ -n "$SWAY_PID" ] && kill "$SWAY_PID" 2>/dev/null; rm -f "$LOG"; }
trap cleanup EXIT

if [ "${QS_TEST_HEADLESS:-0}" = "1" ] || [ -z "${WAYLAND_DISPLAY:-}" ]; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-$(mktemp -d)}"
  chmod 700 "$XDG_RUNTIME_DIR"
  export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
  unset WAYLAND_DISPLAY
  sway -c /dev/null >"$XDG_RUNTIME_DIR/sway.log" 2>&1 &
  SWAY_PID=$!
  for _ in $(seq 1 50); do
    sock="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' -print -quit)"
    [ -n "$sock" ] && break
    sleep 0.1
  done
  if [ -z "${sock:-}" ]; then
    echo "::error::headless sway did not start"
    cat "$XDG_RUNTIME_DIR/sway.log"
    exit 1
  fi
  WAYLAND_DISPLAY="$(basename "$sock")"
  export WAYLAND_DISPLAY
  echo "Headless sway on $WAYLAND_DISPLAY"
fi

echo "Running $CONFIG_DIR for ${RUN_SECONDS}s"
timeout "$RUN_SECONDS" qs -p "$CONFIG_DIR" >"$LOG" 2>&1
cat "$LOG"

failed=0
if ! grep -q 'Configuration Loaded' "$LOG"; then
  echo "::error::Quickshell did not report 'Configuration Loaded'"
  failed=1
fi

# QML/JS errors that point at bugs in our own files. Warnings about missing
# services (Hyprland IPC, UPower, PipeWire, NetworkManager) are expected in CI.
# Quickshell prefixes messages from config files with "@File.qml[line:col]".
pattern='(TypeError|ReferenceError|SyntaxError|is not a type|is not defined|Cannot assign|Failed to load|module .* is not installed)'
errors="$(grep -E "$pattern" "$LOG" | grep -E '@[^ ]+\.qml' || true)"
if [ -n "$errors" ]; then
  echo "::error::QML errors found:"
  echo "$errors"
  failed=1
fi

[ $failed -eq 0 ] && echo "Load test passed"
exit $failed
