#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/sample-login-19753-21122/AngularFrontend"
cd "$WORKSPACE"
# Determine Angular major deterministically
NG_MAJOR=""
if command -v ng >/dev/null 2>&1; then
  if ng --version --json >/dev/null 2>&1; then
    NG_MAJOR=$(ng --version --json 2>/dev/null | awk -F '"' '/@angular\\/cli"/{print $(NF-1);exit}' | sed -E 's/^([0-9]+).*/\1/') || true
  else
    NG_MAJOR=$(ng --version 2>/dev/null | awk -F: '/Angular CLI/{gsub(/[^0-9.]/,"",$2); print $2; exit}' | sed -E 's/^([0-9]+).*/\1/') || true
  fi
fi
# fallback: try global npm listing
if [ -z "$NG_MAJOR" ]; then
  NG_MAJOR=$(npm ls -g --depth=0 @angular/cli --json 2>/dev/null | awk -F'"' '/@angular\\/cli/ {getline; getline; print $2; exit}' | sed -E 's/^([0-9]+).*/\1/' || true)
fi
# if still empty, choose conservative pinned local install (15)
if [ -z "$NG_MAJOR" ]; then
  NG_MAJOR=15
  echo "warning: could not detect global @angular/cli; installing local @angular/cli@${NG_MAJOR} as fallback" >&2
  npm i --no-audit --no-fund --silent --save-dev @angular/cli@"^${NG_MAJOR}"
fi
if ! [[ "$NG_MAJOR" =~ ^[0-9]+$ ]]; then
  echo "failed to determine Angular major (NG_MAJOR='$NG_MAJOR')" >&2
  exit 2
fi
# conservative TS/RxJS mapping by major
TS_VER="^4.9.0"
RXJS_VER="^7.0.0"
if [ "$NG_MAJOR" -ge 16 ]; then TS_VER="^5.0.0"; RXJS_VER="^7.8.0"; fi
if [ "$NG_MAJOR" -ge 15 ] && [ "$NG_MAJOR" -lt 16 ]; then TS_VER="^4.9.5"; RXJS_VER="^7.5.0"; fi
# Update package.json pins idempotently (only fill missing/placeholders)
if [ -f package.json ]; then
  node -e "const fs=require('fs');const p='package.json';let j=JSON.parse(fs.readFileSync(p));j.dependencies=j.dependencies||{};j.devDependencies=j.devDependencies||{};const setDep=(k,v)=>{if(!j.dependencies[k]||j.dependencies[k]===''||j.dependencies[k]==='__PLACEHOLDER__')j.dependencies[k]=v};const setDev=(k,v)=>{if(!j.devDependencies[k]||j.devDependencies[k]===''||j.devDependencies[k]==='__PLACEHOLDER__')j.devDependencies[k]=v};setDep('@angular/core','^'+${NG_MAJOR});setDep('@angular/common','^'+${NG_MAJOR});setDep('@angular/platform-browser','^'+${NG_MAJOR});setDep('@angular/platform-browser-dynamic','^'+${NG_MAJOR});setDep('@angular/compiler','^'+${NG_MAJOR});if(!j.dependencies['rxjs']||j.dependencies['rxjs']===''||j.dependencies['rxjs']==='__PLACEHOLDER__')j.dependencies['rxjs']='${RXJS_VER}';if(!j.dependencies['zone.js']||j.dependencies['zone.js']===''||j.dependencies['zone.js']==='__PLACEHOLDER__')j.dependencies['zone.js']='^0.11.0';setDev('@angular-devkit/build-angular','^'+${NG_MAJOR});setDev('typescript',''+'${TS_VER}');if(!j.devDependencies['jest'])j.devDependencies['jest']='^29.0.0';fs.writeFileSync(p,JSON.stringify(j,null,2));"
else
  echo "package.json missing; cannot proceed with deterministic dependency install" >&2
  exit 3
fi
# Install dependencies: prefer npm ci when lockfile exists
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --silent
else
  npm install --no-audit --no-fund --silent
fi
# Post-install verification
if [ ! -x node_modules/.bin/ng ]; then
  echo "warning: local ng binary missing; ensure @angular/cli is installed locally or use global ng" >&2
fi
node -e "const p=require('./package.json');if(!(p.devDependencies&&p.devDependencies['@angular-devkit/build-angular'])){console.warn('@angular-devkit/build-angular not present in devDependencies')}
" || true
# Record tool versions to workspace file
node -e "const fs=require('fs');const exec=require('child_process').execSync;const out={node:process.version,npm:exec('npm --version').toString().trim(),ng:(function(){try{let s=exec('./node_modules/.bin/ng --version 2>/dev/null').toString();return s.split('\n')[0]}catch(e){try{return exec('ng --version 2>/dev/null').toString().split('\n')[0]}catch(e){return 'n/a'}}})()};fs.writeFileSync('.deps-info',JSON.stringify(out,null,2));"
exit 0
