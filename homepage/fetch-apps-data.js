#!/usr/bin/env node
/**
 * fetch-apps-data.js — Pre-fetch iTunes metadata for all apps in apps.json
 * Writes apps-data.json so the homepage loads a static file instead of
 * calling the iTunes API at runtime (avoids CORS issues in browsers).
 *
 * Usage: node fetch-apps-data.js
 * Run this whenever apps.json changes, then commit apps-data.json.
 */

const fs   = require('fs');
const path = require('path');
const https = require('https');

const HOMEPAGE_DIR = __dirname;
const APPS_JSON    = path.join(HOMEPAGE_DIR, 'apps.json');
const OUTPUT       = path.join(HOMEPAGE_DIR, 'apps-data.json');

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'asc-cli-homepage/1.0' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error('JSON parse error for ' + url + ': ' + e.message)); }
      });
    }).on('error', reject);
  });
}

async function main() {
  console.log('Fetching iTunes metadata for apps.json...\n');

  const entries = JSON.parse(fs.readFileSync(APPS_JSON, 'utf8'));
  const items = [];
  const seen  = new Set();

  for (const entry of entries) {
    const devInfo = {
      developer: entry.developer,
      github:    entry.github || null,
      x:         entry.x     || null,
    };

    // ── Phase 1: all apps from a developer ID ───────────────────────────
    if (entry.developerId) {
      const url = `https://itunes.apple.com/lookup?id=${entry.developerId}&entity=software&limit=200`;
      console.log(`  [developer ${entry.developerId}] ${entry.developer}`);
      try {
        const data = await fetchJson(url);
        for (const app of (data.results || [])) {
          if (app.wrapperType !== 'software') continue;
          const key = String(app.trackId);
          if (seen.has(key)) continue;
          seen.add(key);
          items.push({
            ...devInfo,
            trackId:          app.trackId,
            trackName:        app.trackName,
            artworkUrl100:    app.artworkUrl100,
            primaryGenreName: app.primaryGenreName || null,
            url:              app.trackViewUrl,
          });
        }
        console.log(`    → ${items.length} apps so far`);
      } catch (e) {
        console.warn(`    Warning: ${e.message}`);
      }
    }

    // ── Phase 2: specific app Store URLs ────────────────────────────────
    if (entry.apps && entry.apps.length) {
      const appEntries = entry.apps
        .map(u => { const m = u.match(/\/id(\d+)/); return m ? { appId: m[1], url: u } : null; })
        .filter(Boolean);

      if (appEntries.length) {
        const ids = appEntries.map(a => a.appId).join(',');
        const url = `https://itunes.apple.com/lookup?id=${ids}`;
        console.log(`  [apps] ${ids}`);
        try {
          const data  = await fetchJson(url);
          const byId  = {};
          for (const r of (data.results || [])) byId[String(r.trackId)] = r;
          for (const { appId, url: appUrl } of appEntries) {
            if (seen.has(appId)) continue;
            const app = byId[appId];
            if (!app) { console.warn(`    Warning: no result for app ${appId}`); continue; }
            seen.add(appId);
            items.push({
              ...devInfo,
              trackId:          app.trackId,
              trackName:        app.trackName,
              artworkUrl100:    app.artworkUrl100,
              primaryGenreName: app.primaryGenreName || null,
              url:              appUrl,
            });
          }
        } catch (e) {
          console.warn(`    Warning: ${e.message}`);
        }
      }
    }
  }

  const output = { generated: new Date().toISOString(), items };
  fs.writeFileSync(OUTPUT, JSON.stringify(output, null, 2) + '\n', 'utf8');
  console.log(`\n✓ Wrote ${items.length} app(s) to apps-data.json`);
}

main().catch(err => { console.error(err.message); process.exit(1); });
