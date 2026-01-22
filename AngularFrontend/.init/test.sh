#!/usr/bin/env bash
set -euo pipefail
# testing-setup: create minimal spec if absent, ensure ChromeHeadless works in container and use puppeteer chromium fallback; run tests headless and fail on failures
WORKSPACE="/home/kavia/workspace/code-generation/sample-login-19753-21122/AngularFrontend"
cd "$WORKSPACE"
export PATH="$WORKSPACE/node_modules/.bin:$PATH"
# Ensure dependencies were installed
if [ ! -d "$WORKSPACE/node_modules" ]; then echo "ERROR: node_modules missing; run .init/install.sh or run dependencies step" >&2; exit 2; fi
# Create minimal spec if missing
SPEC="src/app/app.component.spec.ts"
if [ ! -f "$SPEC" ]; then mkdir -p "$(dirname "$SPEC")" && cat > "$SPEC" <<'EOF'
import { AppComponent } from './app.component';

describe('AppComponent', () => { it('creates component', () => { const c = new AppComponent(); expect(c).toBeTruthy(); }); });
EOF
fi
# Configure CHROME_BIN: prefer system chrome, otherwise try Puppeteer's chromium in node_modules
CHROME_BIN=""
if command -v chromium-browser >/dev/null 2>&1; then CHROME_BIN=$(command -v chromium-browser); fi
if [ -z "$CHROME_BIN" ] && command -v google-chrome >/dev/null 2>&1; then CHROME_BIN=$(command -v google-chrome); fi
# Look for Puppeteer's local chromium (common installation path under node_modules/.local-chromium)
if [ -z "$CHROME_BIN" ]; then
  # shellglob to find a candidate
  if compgen -G "$WORKSPACE/node_modules/.local-chromium/*/chrome-linux/chrome" >/dev/null; then
    CHROME_BIN=$(ls -d $WORKSPACE/node_modules/.local-chromium/*/chrome-linux/chrome | head -n1) || true
  fi
fi
export CHROME_BIN
# Export Puppeteer env so installs that rely on puppeteer can download chromium if needed
# Only set during test run; if puppeteer is not installed this has no effect
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=${PUPPETEER_SKIP_CHROMIUM_DOWNLOAD:-"false"}
# Prepare Karma custom launcher name used in angular.json/karma.conf.js: ChromeHeadlessCI with --no-sandbox
# If a karma.conf.js exists, ensure it supports ChromeHeadlessCI; if absent, create a minimal one compatible with Angular's karma runner
KARMA_CONF="$WORKSPACE/karma.conf.js"
if [ ! -f "$KARMA_CONF" ]; then cat > "$KARMA_CONF" <<'EOF'
module.exports = function(config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage'),
      require('@angular-devkit/build-angular/plugins/karma')
    ],
    client: { clearContext: false },
    coverageReporter: { dir: require('path').join(__dirname, './coverage'), reporters: [{ type: 'html' }, { type: 'lcovonly' }, { type: 'text-summary' }] },
    reporters: ['progress'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    singleRun: true,
    browsers: ['ChromeHeadlessCI'],
    customLaunchers: {
      ChromeHeadlessCI: {
        base: 'ChromeHeadless',
        flags: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage']
      }
    },
    restartOnFileChange: false
  });
};
EOF
else
  # Try to inject custom launcher if not present: append a minimal override file karma.ci.js that requires existing karma.conf and extends
  KARMA_CI="$WORKSPACE/karma.ci.js"
  if [ ! -f "$KARMA_CI" ]; then cat > "$KARMA_CI" <<'EOF'
const baseConfig = require('./karma.conf.js');
module.exports = function(config) {
  baseConfig(config);
  const cfg = config;
  cfg.browsers = ['ChromeHeadlessCI'];
  cfg.customLaunchers = Object.assign({}, cfg.customLaunchers || {}, {
    ChromeHeadlessCI: { base: 'ChromeHeadless', flags: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage'] }
  });
  cfg.singleRun = true;
  config.set(cfg);
};
EOF
  fi
fi
# Run tests using npx to prefer local binaries; prefer using karma.ci.js if created, else karma.conf.js
set +e
# Determine ng binary: prefer local node_modules/.bin/ng, otherwise npx will resolve
if [ -x "$WORKSPACE/node_modules/.bin/ng" ]; then NG_BIN="$WORKSPACE/node_modules/.bin/ng"; else NG_BIN="npx --yes ng"; fi
# Use karma.ci.js if present to ensure custom launcher
if [ -f "$WORKSPACE/karma.ci.js" ]; then
  $NG_BIN test --watch=false --no-progress --browsers=ChromeHeadlessCI --karma-config=karma.ci.js
  RC=$?
else
  # If angular.json references karma.conf.js by default, this will pick it up
  $NG_BIN test --watch=false --no-progress --browsers=ChromeHeadlessCI
  RC=$?
fi
set -e
if [ $RC -ne 0 ]; then echo "ERROR: ng test failed (exit $RC)" >&2; exit $RC; fi
exit 0
