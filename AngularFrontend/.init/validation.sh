#!/usr/bin/env bash
set -euo pipefail

# Validation script: build + start Angular dev server in new process group, log to /tmp, probe, then terminate cleanly
WORKSPACE="/home/kavia/workspace/code-generation/sample-login-19753-21122/AngularFrontend"
cd "$WORKSPACE"
export PATH="$WORKSPACE/node_modules/.bin:$PATH"
LOG=/tmp/angular_dev_serve.log
BUILD_LOG=/tmp/angular_build.log
PIDFILE=/tmp/angular_dev_serve.pid

cleanup(){ RC=$?
  # If PIDFILE exists, read PGID and terminate group
  if [ -f "$PIDFILE" ]; then
    PGID=$(cat "$PIDFILE" 2>/dev/null || true)
    if [ -n "$PGID" ]; then
      kill -TERM -"$PGID" 2>/dev/null || true
      sleep 3
      # If still exists, escalate
      if kill -0 -"$PGID" 2>/dev/null; then
        kill -KILL -"$PGID" 2>/dev/null || true
      fi
    fi
    rm -f "$PIDFILE" || true
  fi
  echo "--- build log (tail 200) ---"
  tail -n 200 "$BUILD_LOG" 2>/dev/null || true
  echo "--- serve log (tail 200) ---"
  tail -n 200 "$LOG" 2>/dev/null || true
  exit $RC
}
trap cleanup EXIT INT TERM

# Build using npx to prefer local ng; capture build output
npx --yes ng build --configuration=development --progress=false 2>&1 | tee "$BUILD_LOG"

# Start dev server in new process group (setsid) so we can kill group by negative PGID
# Redirect stdout/stderr to log file
setsid npx --yes ng serve --configuration=development --host=0.0.0.0 --port=4200 >"$LOG" 2>&1 &
SERV_PID=$!
# Obtain PGID of background process and persist
PGID=$(ps -o pgid= "$SERV_PID" | tr -d ' ')
echo "$PGID" > "$PIDFILE"

# Probe readiness with retries
MAX_WAIT=60
i=0
while ! curl -sS --fail http://127.0.0.1:4200/ >/dev/null 2>&1 && [ $i -lt $MAX_WAIT ]; do
  i=$((i+1))
  sleep 1
done
if [ $i -ge $MAX_WAIT ]; then
  echo "ERROR: Server did not respond within $MAX_WAIT seconds" >&2
  exit 6
fi

# Output first bytes of index as evidence
curl -sS http://127.0.0.1:4200/ | head -c 200 || true

# Normal exit (trap cleanup will stop server)
exit 0
