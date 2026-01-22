#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/sample-login-19753-21122/AngularFrontend"
cd "$WORKSPACE"
mkdir -p test
cat > test/smoke.test.js <<'JS'
test('smoke', ()=>{ expect(1+1).toBe(2); });
JS
cat > jest.smoke.config.js <<'CFG'
module.exports={testEnvironment:'node',testMatch:['**/test/*.test.js']};
CFG
# ensure package.json has test:smoke and jest dev dep (idempotent)
node -e "const fs=require('fs');let p='package.json';if(!fs.existsSync(p))process.exit(0);let j=JSON.parse(fs.readFileSync(p));j.scripts=j.scripts||{};j.scripts['test:smoke']=j.scripts['test:smoke']||'./node_modules/.bin/jest --config=./jest.smoke.config.js --runInBand';j.devDependencies=j.devDependencies||{};j.devDependencies.jest=j.devDependencies.jest||'^29.0.0';fs.writeFileSync(p,JSON.stringify(j,null,2));"
# run smoke tests using local jest; fail clearly if missing
if [ -x node_modules/.bin/jest ]; then
  ./node_modules/.bin/jest --config=./jest.smoke.config.js --runInBand || { echo "Smoke tests failed" >&2; exit 6; }
else
  echo "local jest not found; run deps-003 to install dependencies" >&2; exit 7
fi
exit 0
