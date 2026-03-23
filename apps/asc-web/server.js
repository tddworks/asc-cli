#!/usr/bin/env node
// ASC Web Server — Unified bridge for all web apps
// Runs `asc` CLI commands and serves static files for web UIs
//
// Usage:
//   node server.js              # starts on port 8420
//   node server.js --port 3000  # custom port
//
// Routes:
//   /api/run          → execute asc CLI commands
//   /command-center/  → 302 redirect to asccli.app/command-center
//   /console/         → 302 redirect to asccli.app/console
//   /                 → 302 redirect to asccli.app/command-center
//
// Prerequisites:
//   - `asc` CLI installed and on PATH (or built: swift run asc)
//   - Authenticated: `asc auth check` should pass

const http = require('http');
const https = require('https');
const { execFile, execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const PORT = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--port') || '8420', 10);
const HTTPS_PORT = PORT + 1; // 8421 by default
const ASC_BIN = process.argv.find((_, i, a) => a[i - 1] === '--asc-bin') || 'asc';
const ASC_DIR = path.join(os.homedir(), '.asc');
const CERT_KEY = path.join(ASC_DIR, 'server.key');
const CERT_PEM = path.join(ASC_DIR, 'server.crt');

function runASC(command) {
  return new Promise((resolve) => {
    const parts = command.split(/\s+/);
    const args = parts[0] === 'asc' ? parts.slice(1) : parts;

    execFile(ASC_BIN, args, {
      timeout: 30000,
      maxBuffer: 10 * 1024 * 1024,
      env: { ...process.env, NO_COLOR: '1' },
    }, (err, stdout, stderr) => {
      resolve({
        stdout: stdout || '',
        stderr: stderr || '',
        exit_code: err ? (err.code || 1) : 0,
      });
    });
  });
}

function handleRequest(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Private-Network', 'true');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // API endpoint — execute asc commands
  if (req.method === 'POST' && req.url === '/api/run') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      try {
        const { command } = JSON.parse(body);
        if (!command || typeof command !== 'string') {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Missing command' }));
          return;
        }

        if (/[;&|`$\\(){}\[\]!><]/.test(command)) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Command contains disallowed characters' }));
          return;
        }

        console.log(`  $ ${command}`);
        const result = await runASC(command);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // Redirect to hosted web apps at asccli.app
  const urlPath = decodeURIComponent(req.url.split('?')[0]);

  if (urlPath === '/' || urlPath === '/index.html' || urlPath.startsWith('/command-center')) {
    res.writeHead(302, { 'Location': 'https://asccli.app/command-center' });
    res.end();
    return;
  }
  if (urlPath.startsWith('/console')) {
    res.writeHead(302, { 'Location': 'https://asccli.app/console' });
    res.end();
    return;
  }

  res.writeHead(404);
  res.end('Not found');
}

const server = http.createServer(handleRequest);

// --- Self-signed cert generation for HTTPS (mixed-content support) ---

function ensureSelfSignedCert() {
  if (fs.existsSync(CERT_KEY) && fs.existsSync(CERT_PEM)) return true;
  try {
    fs.mkdirSync(ASC_DIR, { recursive: true });
    execFileSync('openssl', [
      'req', '-x509', '-newkey', 'rsa:2048',
      '-keyout', CERT_KEY, '-out', CERT_PEM,
      '-days', '825', '-nodes',
      '-subj', '/CN=localhost',
      '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1',
    ], { stdio: 'pipe' });
    // Trust the cert in macOS Keychain so browsers accept it without warnings
    try {
      execFileSync('security', [
        'add-trusted-cert', '-p', 'ssl',
        '-k', path.join(os.homedir(), 'Library/Keychains/login.keychain-db'),
        CERT_PEM,
      ], { stdio: 'pipe' });
    } catch {
      console.log('  ⚠ Could not auto-trust cert. Visit https://localhost:' + HTTPS_PORT + ' and accept manually.');
    }
    return true;
  } catch {
    return false;
  }
}

// --- Start servers ---

server.listen(PORT, () => {
  const httpUrl = `http://localhost:${PORT}`;
  let httpsUrl = null;

  // Start HTTPS server for mixed-content support (HTTPS sites → localhost)
  if (ensureSelfSignedCert()) {
    try {
      const httpsServer = https.createServer({
        key: fs.readFileSync(CERT_KEY),
        cert: fs.readFileSync(CERT_PEM),
      }, handleRequest);
      httpsServer.listen(HTTPS_PORT, () => {
        httpsUrl = `https://localhost:${HTTPS_PORT}`;
      });
    } catch {}
  }

  // Print banner after a tick so HTTPS status is known
  setTimeout(() => {
    const lines = [
      '  ┌─────────────────────────────────────────┐',
      '  │  ASC Web Server                         │',
      `  │  ${httpUrl.padEnd(39)}│`,
    ];
    if (httpsUrl) {
      lines.push(`  │  ${httpsUrl.padEnd(39)}│`);
    }
    lines.push(
      '  │                                         │',
      '  │  asccli.app/command-center              │',
      '  │  asccli.app/console                     │',
      '  │  /api/run          CLI bridge           │',
      '  │                                         │',
      `  │  Binary: ${ASC_BIN.padEnd(31)}│`,
      '  │  Press Ctrl+C to stop                   │',
      '  └─────────────────────────────────────────┘',
    );
    console.log('\n' + lines.join('\n') + '\n');
  }, 100);
});
