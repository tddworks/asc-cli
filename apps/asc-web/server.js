#!/usr/bin/env node
// ASC Web Server — Unified bridge for all web apps
// Runs `asc` CLI commands and serves static files for web UIs
//
// Usage:
//   node server.js              # starts on port 8420
//   node server.js --port 3000  # custom port
//
// Routes:
//   /command-center/  → command-center (dashboard)
//   /console/         → console (terminal)
//   /shared/          → shared (domain, infrastructure, static)
//   /                 → appstore-command-center (default)
//   /api/run          → execute asc CLI commands
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

const APPS_DIR = __dirname;
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

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

function serveStatic(filePath, res) {
  const ext = path.extname(filePath);
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.stat(filePath, (statErr, stats) => {
    if (statErr || !stats) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    if (stats.isDirectory()) {
      serveStatic(path.join(filePath, 'index.html'), res);
      return;
    }
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
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

  // Static file serving with app routing
  const urlPath = decodeURIComponent(req.url.split('?')[0]);

  let filePath;
  if (urlPath.startsWith('/command-center')) {
    const subPath = urlPath.slice('/command-center'.length) || '/';
    filePath = path.join(APPS_DIR, 'command-center', subPath === '/' ? 'index.html' : subPath);
  } else if (urlPath.startsWith('/console')) {
    const subPath = urlPath.slice('/console'.length) || '/';
    filePath = path.join(APPS_DIR, 'console', subPath === '/' ? 'index.html' : subPath);
  } else if (urlPath.startsWith('/shared')) {
    filePath = path.join(APPS_DIR, urlPath);
  } else if (urlPath === '/' || urlPath === '/index.html') {
    filePath = path.join(APPS_DIR, 'command-center', 'index.html');
  } else {
    filePath = path.join(APPS_DIR, 'command-center', urlPath);
  }

  // Security: block path traversal
  if (!filePath.startsWith(APPS_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  serveStatic(filePath, res);
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
      '  │  /command-center/  Dashboard            │',
      '  │  /console/         Terminal             │',
      '  │  /api/run          CLI bridge           │',
      '  │                                         │',
      `  │  Binary: ${ASC_BIN.padEnd(31)}│`,
      '  │  Press Ctrl+C to stop                   │',
      '  └─────────────────────────────────────────┘',
    );
    console.log('\n' + lines.join('\n') + '\n');
  }, 100);
});
