#!/usr/bin/env bash
set -euo pipefail
# Idempotent Angular scaffolding for workspace
WORKSPACE="/home/kavia/workspace/code-generation/sample-login-19753-21122/AngularFrontend"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
PROJ_NAME="angular-frontend-sample"
# package.json: create only if missing and include placeholders for required deps
if [ ! -f package.json ]; then
  cat > package.json <<'JSON'
{
  "name": "angular-frontend-sample",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "start": "./node_modules/.bin/ng serve --host 0.0.0.0 --port 4200 --disable-host-check",
    "build": "./node_modules/.bin/ng build",
    "test:smoke": "./node_modules/.bin/jest --config=./jest.smoke.config.js --runInBand"
  },
  "dependencies": {
    "@angular/core": "",
    "@angular/common": "",
    "@angular/platform-browser": "",
    "@angular/platform-browser-dynamic": "",
    "@angular/compiler": "",
    "rxjs": "",
    "zone.js": ""
  },
  "devDependencies": {
    "@angular-devkit/build-angular": "",
    "typescript": "",
    "jest": ""
  }
}
JSON
fi
# tsconfig.json baseline
if [ ! -f tsconfig.json ]; then
  cat > tsconfig.json <<'TS'
{
  "compileOnSave": false,
  "compilerOptions": {
    "outDir": "./dist",
    "sourceMap": true,
    "module": "es2020",
    "moduleResolution": "node",
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "target": "es2017",
    "typeRoots": ["node_modules/@types"],
    "lib": ["es2018", "dom"]
  }
}
TS
fi
# angular.json minimal
if [ ! -f angular.json ]; then
  cat > angular.json <<ANG
{
  "$schema": "https://angular.io/cli/schema.json",
  "version": 1,
  "defaultProject": "${PROJ_NAME}",
  "projects": {
    "${PROJ_NAME}": {
      "projectType": "application",
      "root": "",
      "sourceRoot": "src",
      "architect": {
        "build": { "builder": "@angular-devkit/build-angular:browser", "options": { "outputPath": "dist/${PROJ_NAME}", "index": "src/index.html", "main": "src/main.ts", "polyfills": "src/polyfills.ts", "tsConfig": "tsconfig.json", "assets": ["src/assets"], "styles": ["src/styles.css"] } },
        "serve": { "builder": "@angular-devkit/build-angular:dev-server", "options": { "browserTarget": "${PROJ_NAME}:build" } }
      }
    }
  }
}
ANG
fi
# minimal src tree (AOT-friendly)
if [ ! -d src ]; then
  mkdir -p src/assets src/environments src/app
  cat > src/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Minimal App</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <app-root></app-root>
</body>
</html>
HTML
  cat > src/polyfills.ts <<'POL'
/** minimal polyfills */
import 'zone.js';
POL
  cat > src/environments/environment.ts <<'ENV'
export const environment = { production: false, apiUrl: 'http://localhost:3000' };
ENV
  cat > src/main.ts <<'MAIN'
import { enableProdMode } from '@angular/core';
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';
import { environment } from './environments/environment';
if (environment.production) { enableProdMode(); }
platformBrowserDynamic().bootstrapModule(AppModule).catch(err => console.error(err));
MAIN
  cat > src/app/app.module.ts <<'MOD'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppComponent } from './app.component';
@NgModule({ declarations: [AppComponent], imports: [BrowserModule], bootstrap: [AppComponent] })
export class AppModule {}
MOD
  cat > src/app/app.component.ts <<'CMP'
import { Component } from '@angular/core';
@Component({ selector: 'app-root', template: `<h1>Minimal App</h1>` })
export class AppComponent {}
CMP
  echo "/* minimal styles */" > src/styles.css
  echo "node 16" > browserslist || true
fi
# ensure scripts present if package.json exists
if [ -f package.json ]; then
  node -e "const fs=require('fs');let p='package.json';let j=JSON.parse(fs.readFileSync(p));j.scripts=j.scripts||{};j.scripts.start=j.scripts.start||'./node_modules/.bin/ng serve --host 0.0.0.0 --port 4200 --disable-host-check';j.scripts.build=j.scripts.build||'./node_modules/.bin/ng build';j.scripts['test:smoke']=j.scripts['test:smoke']||'./node_modules/.bin/jest --config=./jest.smoke.config.js --runInBand';fs.writeFileSync(p,JSON.stringify(j,null,2));"
fi
exit 0
