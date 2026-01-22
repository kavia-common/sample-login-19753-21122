#!/usr/bin/env bash
set -euo pipefail
# install-dependencies: deterministic npm install/ci with logging and local binary validation
WORKSPACE="/home/kavia/workspace/code-generation/sample-login-19753-21122/AngularFrontend"
LOG=/tmp/npm_install.log
cd "$WORKSPACE"
# Ensure npm available
command -v npm >/dev/null 2>&1 || { echo "ERROR: npm not found on PATH" >&2; exit 2; }
# Choose deterministic install when lockfile present
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund >"$LOG" 2>&1 || { echo "ERROR: npm ci failed; see $LOG" >&2; tail -n 200 "$LOG" >&2; exit 5; }
else
  # npm install but avoid package.json mutation; capture logs
  npm install --no-audit --no-fund >"$LOG" 2>&1 || { echo "ERROR: npm install failed; see $LOG" >&2; tail -n 200 "$LOG" >&2; exit 6; }
fi
# Prefer local node_modules binaries for this session
export PATH="$WORKSPACE/node_modules/.bin:$PATH"
# Validate local binaries; warn and fall back if not present
if ! command -v ng >/dev/null 2>&1; then
  echo "WARNING: local ng not found; falling back to global ng if available" >&2
fi
if ! command -v tsc >/dev/null 2>&1; then
  echo "WARNING: local tsc not found; falling back to global tsc if available" >&2
fi
# Print short version info for transparency (best-effort)
(command -v ng >/dev/null 2>&1 && ng --version 2>/dev/null | sed -n '1,3p') || true
(command -v tsc >/dev/null 2>&1 && tsc -v) || true
# show brief install log summary
echo "npm install log tail (last 50 lines):" >&2
tail -n 50 "$LOG" || true
exit 0
