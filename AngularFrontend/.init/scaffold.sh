#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/sample-login-19753-21122/AngularFrontend"
cd "$WORKSPACE"
# Create .env template only if missing
[ -f .env ] || cat > .env <<'EOF'
# API endpoint for backend WebAPI
API_BASE_URL=http://backend.local/api
EOF
# Ensure scripts dir exists
mkdir -p scripts
# Create sync helper JS only if missing (reads .env and writes Angular environment.ts)
[ -f scripts/sync-env-to-angular.js ] || cat > scripts/sync-env-to-angular.js <<'EOF'
#!/usr/bin/env node
'use strict';
const fs = require('fs');
const path = require('path');
const workspace = process.cwd();
const envFile = path.join(workspace, '.env');
const outDir = path.join(workspace, 'src', 'environments');
const outFile = path.join(outDir, 'environment.ts');
function parseDotEnv(text){
  const lines = text.split(/\r?\n/);
  const obj = {};
  for(const l of lines){
    const line = l.trim();
    if(!line || line.startsWith('#')) continue;
    const m = line.match(/^([^=]+)=(.*)$/);
    if(m){
      const key = m[1].trim();
      let val = m[2].trim();
      if(val.startsWith('"') && val.endsWith('"')) val = val.slice(1,-1);
      if(val.startsWith("'") && val.endsWith("'")) val = val.slice(1,-1);
      obj[key] = val;
    }
  }
  return obj;
}
try{
  if(!fs.existsSync(envFile)){
    // nothing to do
    process.exit(0);
  }
  const txt = fs.readFileSync(envFile,'utf8');
  const env = parseDotEnv(txt);
  const apiBase = env.API_BASE_URL || 'http://backend.local/api';
  if(!fs.existsSync(outDir)) fs.mkdirSync(outDir,{ recursive: true });
  const content = `// This file is auto-generated from .env - do not edit by hand\nexport const environment = {\n  production: false,\n  apiBaseUrl: ${JSON.stringify(apiBase)}\n};\n`;
  // Only write if changed to avoid touching file mtime unnecessarily
  let write = true;
  if(fs.existsSync(outFile)){
    const existing = fs.readFileSync(outFile,'utf8');
    if(existing === content) write = false;
  }
  if(write) fs.writeFileSync(outFile, content, 'utf8');
} catch(err){
  // Fail silently for non-blocking execution as requested by orchestrator
  // But emit to stderr for debugging if someone inspects
  console.error('sync-env helper failed:', err && err.message ? err.message : err);
  process.exit(0);
}
EOF
# Make helper executable
chmod +x scripts/sync-env-to-angular.js 2>/dev/null || true
# Run sync helper non-privileged; ignore failures
node ./scripts/sync-env-to-angular.js >/dev/null 2>&1 || true
exit 0
