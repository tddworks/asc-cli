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
const { execFile, execFileSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const PORT = parseInt(process.argv.find((_, i, a) => a[i - 1] === '--port') || '8420', 10);
const HTTPS_PORT = PORT + 1; // 8421 by default
const ASC_BIN = process.argv.find((_, i, a) => a[i - 1] === '--asc-bin') || 'asc';
const PROJECT_DIR = process.argv.find((_, i, a) => a[i - 1] === '--project-dir') || process.cwd();
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

  // --- Simulator endpoints (merged stream server) ---
  const parsedUrl = new URL(req.url, `http://localhost:${PORT}`);
  const urlPath = decodeURIComponent(parsedUrl.pathname);

  if (urlPath.startsWith('/api/sim/')) {
    return handleSimulator(req, res, urlPath, parsedUrl);
  }

  // Serve local files from apps/asc-web/
  const WEB_DIR = path.join(PROJECT_DIR, 'apps/asc-web');
  const MIME = { '.html':'text/html','.css':'text/css','.js':'application/javascript','.json':'application/json','.png':'image/png','.svg':'image/svg+xml' };

  if (urlPath === '/' || urlPath === '/index.html') {
    res.writeHead(302, { 'Location': '/command-center/' }); res.end(); return;
  }
  if (/^\/(command-center|console|simulators)$/.test(urlPath)) {
    res.writeHead(302, { 'Location': urlPath + '/' }); res.end(); return;
  }

  let filePath = path.join(WEB_DIR, urlPath);
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) filePath = path.join(filePath, 'index.html');
  if (fs.existsSync(filePath) && !fs.statSync(filePath).isDirectory()) {
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': (MIME[ext] || 'application/octet-stream') + '; charset=utf-8' });
    res.end(fs.readFileSync(filePath)); return;
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
      `  │  /api/sim/*        Simulators ${AXE ? '(axe ✓)' : '       '} │`,
      '  │                                         │',
      `  │  Binary: ${ASC_BIN.padEnd(31)}│`,
      '  │  Press Ctrl+C to stop                   │',
      '  └─────────────────────────────────────────┘',
    );
    console.log('\n' + lines.join('\n') + '\n');

    // Open browser to hosted web app
    const opener = process.platform === 'darwin' ? 'open' : 'xdg-open';
    execFile(opener, ['https://asccli.app/command-center'], { stdio: 'ignore' }, () => {});
  }, 100);
});

// =============================================================================
// Simulator Stream Server (merged)
// =============================================================================

// --- AXe resolution ---
function resolveAxePath() {
  for (const p of ['/opt/homebrew/bin/axe', '/usr/local/bin/axe']) {
    if (fs.existsSync(p)) return p;
  }
  try { return execFileSync('which', ['axe'], { encoding: 'utf-8', timeout: 3000 }).trim(); }
  catch { return null; }
}

const AXE = resolveAxePath();

// --- Stream state ---
let streamProcess = null; // { proc, udid }
let latestFrame = null;
let mjpegClients = []; // connected MJPEG stream response objects
let streamBuffer = Buffer.alloc(0);
let streamHeaderSkipped = false;

function startStream(udid, fps = 15) {
  stopStream();
  if (!AXE) return;
  streamBuffer = Buffer.alloc(0);
  streamHeaderSkipped = false;

  const proc = spawn(AXE, [
    'stream-video', '--format', 'mjpeg',
    '--fps', String(fps), '--quality', '70', '--scale', '0.5',
    '--udid', udid,
  ], { stdio: ['pipe', 'pipe', 'pipe'] });

  streamProcess = { proc, udid };

  proc.stdout.on('data', (chunk) => {
    streamBuffer = Buffer.concat([streamBuffer, chunk]);

    // Skip AXe's HTTP header (first line up to \r\n\r\n)
    if (!streamHeaderSkipped) {
      const headerEnd = streamBuffer.indexOf('\r\n\r\n');
      if (headerEnd === -1) return;
      streamBuffer = streamBuffer.slice(headerEnd + 4);
      streamHeaderSkipped = true;
    }

    // Extract complete MJPEG frames and push to clients
    extractAndPushFrames();
  });

  proc.on('exit', () => {
    if (streamProcess && streamProcess.proc === proc) {
      streamProcess = null;
    }
  });
}

function stopStream() {
  if (streamProcess) {
    streamProcess.proc.kill();
    streamProcess = null;
    latestFrame = null;
    streamBuffer = Buffer.alloc(0);
    streamHeaderSkipped = false;
  }
}

const BOUNDARY = Buffer.from('--mjpegstream');
const HEADER_END = Buffer.from('\r\n\r\n');

function extractAndPushFrames() {
  // AXe MJPEG format: --mjpegstream\r\nContent-Type: image/jpeg\r\nContent-Length: NNN\r\n\r\n[JPEG]\r\n
  while (true) {
    const bIdx = streamBuffer.indexOf(BOUNDARY);
    if (bIdx === -1) break;

    const afterBoundary = streamBuffer.slice(bIdx + BOUNDARY.length);
    const hEnd = afterBoundary.indexOf(HEADER_END);
    if (hEnd === -1) break;

    // Parse Content-Length from frame headers
    const headerStr = afterBoundary.slice(0, hEnd).toString();
    const match = headerStr.match(/Content-Length:\s*(\d+)/i);
    if (!match) { streamBuffer = afterBoundary.slice(hEnd + 4); continue; }

    const contentLen = parseInt(match[1], 10);
    const frameStart = hEnd + 4;
    const frameEnd = frameStart + contentLen;

    if (afterBoundary.length < frameEnd) break; // incomplete frame

    const frame = afterBoundary.slice(frameStart, frameEnd);
    latestFrame = frame;
    pushMJPEGFrame(frame);

    streamBuffer = afterBoundary.slice(frameEnd);
  }
}

function captureScreenshot(udid) {
  const tmpFile = path.join(os.tmpdir(), `sim-${udid}-${Date.now()}.png`);
  try {
    if (AXE) {
      execFileSync(AXE, ['screenshot', '--output', tmpFile, '--udid', udid], { timeout: 5000, stdio: 'pipe' });
    } else {
      execFileSync('xcrun', ['simctl', 'io', udid, 'screenshot', '--type=png', tmpFile], { timeout: 5000, stdio: 'pipe' });
    }
    const buf = fs.readFileSync(tmpFile);
    try { fs.unlinkSync(tmpFile); } catch {}
    return buf;
  } catch { return null; }
}

function pushMJPEGFrame(frameData) {
  const dead = [];
  for (const client of mjpegClients) {
    try {
      client.write(`--frame\r\nContent-Type: image/jpeg\r\nContent-Length: ${frameData.length}\r\n\r\n`);
      client.write(frameData);
      client.write('\r\n');
    } catch {
      dead.push(client);
    }
  }
  if (dead.length) mjpegClients = mjpegClients.filter(c => !dead.includes(c));
}

// --- AXe actions ---
function axe(args, opts = {}) {
  if (!AXE) throw new Error('axe not installed. Run: brew install cameroncooke/axe/axe');
  return execFileSync(AXE, args.split(/\s+/), { encoding: 'utf-8', timeout: opts.timeout || 10000, stdio: 'pipe' });
}

function readBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => { try { resolve(JSON.parse(body)); } catch { resolve({}); } });
  });
}

function json(res, data, status = 200) {
  res.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
  res.end(JSON.stringify(data));
}

// --- Frame assets ---
const FRAMES_DIR = path.join(PROJECT_DIR, 'apps/remote-device-stream/frames');
console.log('  Frames dir:', FRAMES_DIR, fs.existsSync(FRAMES_DIR) ? '(exists)' : '(NOT FOUND)');
let frameInsetsCache = null;
function loadFrameInsets() {
  if (frameInsetsCache) return frameInsetsCache;
  try {
    frameInsetsCache = JSON.parse(fs.readFileSync(path.join(FRAMES_DIR, 'insets.json'), 'utf-8'));
  } catch { frameInsetsCache = {}; }
  return frameInsetsCache;
}

// --- Route handler ---
async function handleSimulator(req, res, urlPath, parsedUrl) {
  const query = Object.fromEntries(parsedUrl.searchParams);

  // GET /api/sim/devices
  if (req.method === 'GET' && urlPath === '/api/sim/devices') {
    const result = await runASC('asc simulators list --pretty');
    try {
      const data = JSON.parse(result.stdout);
      return json(res, { devices: data.data || [], axeAvailable: !!AXE });
    } catch {
      return json(res, { devices: [], axeAvailable: !!AXE });
    }
  }

  // GET /api/sim/stream?udid=X — MJPEG stream (single connection, server pushes frames)
  if (req.method === 'GET' && urlPath === '/api/sim/stream') {
    const udid = query.udid;
    if (!udid) return json(res, { error: 'missing udid' }, 400);
    res.writeHead(200, {
      'Content-Type': 'multipart/x-mixed-replace; boundary=frame',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
    });
    mjpegClients.push(res);
    // Send latest frame immediately if available
    if (latestFrame) pushMJPEGFrame(latestFrame);
    // Start stream if not already running
    if (!streamProcess) startStream(udid);
    // Clean up on disconnect
    req.on('close', () => {
      mjpegClients = mjpegClients.filter(c => c !== res);
    });
    return; // keep connection open
  }

  // GET /api/sim/screenshot?udid=X
  if (req.method === 'GET' && urlPath === '/api/sim/screenshot') {
    const udid = query.udid;
    if (!udid) return json(res, { error: 'missing udid' }, 400);
    // Fast path: cached frame from stream (JPEG)
    if (latestFrame) {
      res.writeHead(200, { 'Content-Type': 'image/jpeg', 'Cache-Control': 'no-cache', 'Access-Control-Allow-Origin': '*' });
      return res.end(latestFrame);
    }
    // Slow path: single capture
    const buf = captureScreenshot(udid);
    if (buf) {
      res.writeHead(200, { 'Content-Type': 'image/png', 'Cache-Control': 'no-cache', 'Access-Control-Allow-Origin': '*' });
      return res.end(buf);
    }
    return json(res, { error: 'capture failed' }, 500);
  }

  // POST /api/sim/stream-start
  if (req.method === 'POST' && urlPath === '/api/sim/stream-start') {
    const body = await readBody(req);
    if (!body.udid) return json(res, { error: 'missing udid' }, 400);
    if (AXE) {
      startStream(body.udid, body.fps || 15);
      return json(res, { success: true, method: 'axe-stream' });
    }
    return json(res, { success: true, method: 'simctl-polling' });
  }

  // POST /api/sim/stream-stop
  if (req.method === 'POST' && urlPath === '/api/sim/stream-stop') {
    stopStream();
    return json(res, { success: true });
  }

  // POST /api/sim/tap
  if (req.method === 'POST' && urlPath === '/api/sim/tap') {
    if (!AXE) return json(res, { error: 'axe not installed' }, 501);
    try {
      const { udid, x, y, id, label } = await readBody(req);
      if (id) { axe(`tap --id ${id} --udid ${udid}`); return json(res, { success: true, action: 'tap', id }); }
      if (label) { axe(`tap --label ${label} --udid ${udid}`); return json(res, { success: true, action: 'tap', label }); }
      axe(`tap -x ${Math.round(x)} -y ${Math.round(y)} --udid ${udid}`);
      return json(res, { success: true, action: 'tap', x, y });
    } catch (e) { return json(res, { error: e.message }, 500); }
  }

  // POST /api/sim/swipe
  if (req.method === 'POST' && urlPath === '/api/sim/swipe') {
    if (!AXE) return json(res, { error: 'axe not installed' }, 501);
    try {
      const { udid, fromX, fromY, toX, toY, duration, delta } = await readBody(req);
      let args = `swipe --start-x ${Math.round(fromX)} --start-y ${Math.round(fromY)} --end-x ${Math.round(toX)} --end-y ${Math.round(toY)}`;
      if (duration) args += ` --duration ${duration}`;
      if (delta) args += ` --delta ${delta}`;
      axe(`${args} --udid ${udid}`);
      return json(res, { success: true, action: 'swipe' });
    } catch (e) { return json(res, { error: e.message }, 500); }
  }

  // POST /api/sim/gesture
  if (req.method === 'POST' && urlPath === '/api/sim/gesture') {
    if (!AXE) return json(res, { error: 'axe not installed' }, 501);
    try {
      const { udid, gesture } = await readBody(req);
      axe(`gesture ${gesture} --udid ${udid}`);
      return json(res, { success: true, action: 'gesture', gesture });
    } catch (e) { return json(res, { error: e.message }, 500); }
  }

  // POST /api/sim/type
  if (req.method === 'POST' && urlPath === '/api/sim/type') {
    if (!AXE) return json(res, { error: 'axe not installed' }, 501);
    try {
      const { udid, text } = await readBody(req);
      const escaped = text.replace(/"/g, '\\"');
      require('child_process').execSync(`echo "${escaped}" | "${AXE}" type --stdin --udid ${udid}`, { timeout: 10000, stdio: 'pipe', shell: true });
      return json(res, { success: true, action: 'type' });
    } catch (e) { return json(res, { error: e.message }, 500); }
  }

  // POST /api/sim/button
  if (req.method === 'POST' && urlPath === '/api/sim/button') {
    if (!AXE) return json(res, { error: 'axe not installed' }, 501);
    try {
      const { udid, button } = await readBody(req);
      axe(`button ${button.toLowerCase()} --udid ${udid}`);
      return json(res, { success: true, action: 'button', button });
    } catch (e) { return json(res, { error: e.message }, 500); }
  }

  // POST /api/sim/key
  if (req.method === 'POST' && urlPath === '/api/sim/key') {
    if (!AXE) return json(res, { error: 'axe not installed' }, 501);
    try {
      const { udid, keycode, duration } = await readBody(req);
      let args = `key ${keycode}`;
      if (duration) args += ` --duration ${duration}`;
      axe(`${args} --udid ${udid}`);
      return json(res, { success: true, action: 'key', keycode });
    } catch (e) { return json(res, { error: e.message }, 500); }
  }

  // GET /api/sim/describe?udid=X&point=x,y
  if (req.method === 'GET' && urlPath === '/api/sim/describe') {
    if (!AXE) return json(res, { error: 'axe not installed' }, 501);
    try {
      let args = `describe-ui --udid ${query.udid}`;
      if (query.point) args += ` --point ${query.point}`;
      const output = axe(args);
      return json(res, { success: true, tree: output });
    } catch (e) { return json(res, { error: e.message }, 500); }
  }

  // GET /api/sim/frame?name=iPhone+16+Pro+Max
  if (req.method === 'GET' && urlPath === '/api/sim/frame') {
    const name = query.name;
    if (!name) return json(res, { error: 'missing name' }, 400);
    const framePath = path.join(FRAMES_DIR, `${name}.png`);
    try {
      const buf = fs.readFileSync(framePath);
      res.writeHead(200, { 'Content-Type': 'image/png', 'Cache-Control': 'public, max-age=3600', 'Access-Control-Allow-Origin': '*' });
      return res.end(buf);
    } catch {
      return json(res, { error: `frame not found: ${name}` }, 404);
    }
  }

  // GET /api/sim/frame-insets
  if (req.method === 'GET' && urlPath === '/api/sim/frame-insets') {
    return json(res, loadFrameInsets());
  }

  json(res, { error: 'unknown simulator endpoint' }, 404);
}
