// Page: Simulators
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { escapeHTML } from '../helpers.js';
import { showToast } from '../toast.js';

let simStreamUdid = null;
let simStreamName = null;
let simStreamTimer = null;
let simFrameCount = 0;
let simFpsTimer = null;
let simImgNaturalW = 0;
let simImgNaturalH = 0;
let simFrameInsets = {};
let simAxeAvailable = false;
let simDragStart = null;
let simIsDragging = false;

const SIM_API = '/api/sim';

export function renderSimulators() {
  return `
    <div id="simListView">
      <div class="dashboard-stats" id="simStats">
        <div class="stat-card">
          <div class="stat-header">
            <div class="stat-icon green"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2"/><line x1="12" y1="18" x2="12" y2="18"/></svg></div>
            <span class="stat-change up" id="simBootedBadge">--</span>
          </div>
          <div class="stat-value" id="simBootedCount">--</div>
          <div class="stat-label">Booted</div>
        </div>
        <div class="stat-card">
          <div class="stat-header">
            <div class="stat-icon blue"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="5" y="2" width="14" height="20" rx="2"/><line x1="12" y1="18" x2="12" y2="18"/></svg></div>
          </div>
          <div class="stat-value" id="simTotalCount">--</div>
          <div class="stat-label">Available</div>
        </div>
        <div class="stat-card">
          <div class="stat-header">
            <div class="stat-icon purple"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/></svg></div>
            <span class="stat-change" id="simAxeBadge">--</span>
          </div>
          <div class="stat-value" id="simAxeStatus">--</div>
          <div class="stat-label">AXe Interaction</div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <span class="card-title">iOS Simulators</span>
          <button class="btn btn-sm btn-secondary" onclick="simRefresh()">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><path d="M23 4v6h-6M1 20v-6h6"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            Refresh
          </button>
        </div>
        <div class="card-body" id="simDeviceList">
          <div class="empty-state"><div class="spinner" style="margin: 24px auto"></div></div>
        </div>
      </div>

      <div class="card mt-16" style="margin-top:16px">
        <div class="card-header">
          <span class="card-title">Quick Actions</span>
        </div>
        <div class="card-body padded">
          <div class="quick-actions">
            <button class="action-btn" onclick="runAffordance('asc simulators list --output table')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><rect x="5" y="2" width="14" height="20" rx="2"/><line x1="12" y1="18" x2="12" y2="18"/></svg>
              List Simulators
            </button>
            <button class="action-btn" onclick="runAffordance('asc simulators stream')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><polygon points="5 3 19 12 5 21 5 3"/></svg>
              Start Stream CLI
            </button>
          </div>
        </div>
      </div>
    </div>

    <div id="simStreamView" style="display:none">
      <div class="toolbar" style="padding:0 0 16px;border:none;display:flex;align-items:center;gap:12px">
        <button class="btn btn-secondary btn-sm" onclick="simStopStream()">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
          Back to List
        </button>
        <span style="font-weight:600" id="simStreamTitle"></span>
        <span style="color:var(--text-muted);font-size:12px;font-variant-numeric:tabular-nums" id="simStreamFps"></span>
      </div>

      <div style="display:flex;gap:20px;align-items:flex-start">
        <!-- Device Screen -->
        <div style="flex:1;display:flex;justify-content:center">
          <div id="simDeviceFrame" style="position:relative;display:inline-block;max-height:70vh"></div>
        </div>

        <!-- Controls Panel -->
        <div style="width:240px;flex-shrink:0;display:flex;flex-direction:column;gap:12px">
          <!-- Hardware -->
          <div class="card">
            <div class="card-header"><span class="card-title" style="font-size:12px">Hardware</span></div>
            <div class="card-body padded" style="display:flex;flex-direction:column;gap:6px">
              <button class="btn btn-secondary btn-sm" style="width:100%;justify-content:flex-start;gap:8px" onclick="simButton('home')">&#9711; Home</button>
              <button class="btn btn-secondary btn-sm" style="width:100%;justify-content:flex-start;gap:8px" onclick="simButton('lock')">&#9211; Lock</button>
              <button class="btn btn-secondary btn-sm" style="width:100%;justify-content:flex-start;gap:8px" onclick="simButton('siri')">&#9834; Siri</button>
            </div>
          </div>

          <!-- Gestures -->
          <div class="card">
            <div class="card-header"><span class="card-title" style="font-size:12px">Gestures</span></div>
            <div class="card-body padded">
              <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:4px;width:120px;margin:0 auto">
                <div></div>
                <button class="btn btn-secondary btn-sm" onclick="simGesture('scroll-up')" style="padding:6px;justify-content:center">&#8593;</button>
                <div></div>
                <button class="btn btn-secondary btn-sm" onclick="simGesture('scroll-left')" style="padding:6px;justify-content:center">&#8592;</button>
                <div style="display:flex;align-items:center;justify-content:center;font-size:9px;color:var(--text-muted)">scroll</div>
                <button class="btn btn-secondary btn-sm" onclick="simGesture('scroll-right')" style="padding:6px;justify-content:center">&#8594;</button>
                <div></div>
                <button class="btn btn-secondary btn-sm" onclick="simGesture('scroll-down')" style="padding:6px;justify-content:center">&#8595;</button>
                <div></div>
              </div>
              <div style="display:flex;gap:4px;margin-top:8px">
                <button class="btn btn-secondary btn-sm" style="flex:1;font-size:11px" onclick="simGesture('swipe-from-left-edge')">&#8676; Edge</button>
                <button class="btn btn-secondary btn-sm" style="flex:1;font-size:11px" onclick="simGesture('swipe-from-bottom-edge')">&#8679; Home</button>
              </div>
            </div>
          </div>

          <!-- Text Input -->
          <div class="card">
            <div class="card-header"><span class="card-title" style="font-size:12px">Text Input</span></div>
            <div class="card-body padded">
              <div style="display:flex;gap:6px">
                <input type="text" id="simTextInput" placeholder="Type text..." style="flex:1;padding:6px 8px;border:1px solid var(--border);border-radius:6px;font-size:12px;background:var(--bg);color:var(--text)" onkeydown="if(event.key==='Enter')simSendText()">
                <button class="btn btn-primary btn-sm" onclick="simSendText()">Send</button>
              </div>
              <div style="display:flex;gap:4px;margin-top:6px">
                <button class="btn btn-secondary btn-sm" style="flex:1;font-size:11px" onclick="simKey(40)">&#9166;</button>
                <button class="btn btn-secondary btn-sm" style="flex:1;font-size:11px" onclick="simKey(42)">&#9003;</button>
                <button class="btn btn-secondary btn-sm" style="flex:1;font-size:11px" onclick="simKey(43)">&#8677;</button>
                <button class="btn btn-secondary btn-sm" style="flex:1;font-size:11px" onclick="simKey(41)">Esc</button>
              </div>
            </div>
          </div>

          <!-- Accessibility -->
          <div class="card">
            <div class="card-header"><span class="card-title" style="font-size:12px">Inspect</span></div>
            <div class="card-body padded">
              <div style="display:flex;gap:6px">
                <input type="text" id="simTapIdInput" placeholder="Identifier or label..." style="flex:1;padding:6px 8px;border:1px solid var(--border);border-radius:6px;font-size:12px;background:var(--bg);color:var(--text)">
                <button class="btn btn-secondary btn-sm" onclick="simTapById()">ID</button>
              </div>
              <button class="btn btn-secondary btn-sm" style="width:100%;margin-top:6px" onclick="simDescribeUI()">&#128270; Describe UI</button>
            </div>
          </div>

          <!-- Activity Log -->
          <div class="card">
            <div class="card-header"><span class="card-title" style="font-size:12px">Activity</span></div>
            <div class="card-body" style="max-height:160px;overflow-y:auto;font-size:11px;font-family:var(--font-mono);padding:8px" id="simActivityLog">
              <div style="color:var(--text-muted)">Click device screen to interact</div>
            </div>
          </div>
        </div>
      </div>
    </div>`;
}

export async function loadSimulators() {
  // Load frame insets
  try {
    const res = await fetch(`${SIM_API}/frame-insets`);
    simFrameInsets = await res.json();
  } catch {}

  loadSimDeviceList();
}

async function loadSimDeviceList() {
  try {
    const result = await DataProvider.fetch('simulators list --pretty');
    if (result?.data) {
      const sims = result.data;
      const booted = sims.filter(s => s.isBooted || s.state === 'Booted');

      // Check AXe
      try {
        const r = await fetch(`${SIM_API}/devices`);
        const d = await r.json();
        simAxeAvailable = d.axeAvailable;
      } catch {}

      // Update stats
      document.getElementById('simBootedCount').textContent = booted.length;
      document.getElementById('simBootedBadge').textContent = booted.length > 0 ? 'Active' : '--';
      document.getElementById('simBootedBadge').className = `stat-change ${booted.length > 0 ? 'up' : ''}`;
      document.getElementById('simTotalCount').textContent = sims.length;
      document.getElementById('simAxeStatus').textContent = simAxeAvailable ? 'Ready' : 'Not Found';
      document.getElementById('simAxeBadge').textContent = simAxeAvailable ? 'Installed' : 'Missing';
      document.getElementById('simAxeBadge').className = `stat-change ${simAxeAvailable ? 'up' : ''}`;

      renderSimDeviceTable(sims);
    }
  } catch {
    document.getElementById('simDeviceList').innerHTML = '<div class="empty-state">Could not list simulators</div>';
  }
}

function renderSimDeviceTable(sims) {
  const el = document.getElementById('simDeviceList');
  if (!sims.length) { el.innerHTML = '<div class="empty-state">No iOS simulators</div>'; return; }

  // Group by displayRuntime
  const groups = {};
  for (const s of sims) {
    const rt = s.displayRuntime || 'Unknown';
    (groups[rt] = groups[rt] || []).push(s);
  }

  let html = '';
  for (const [runtime, devices] of Object.entries(groups).sort()) {
    html += `<div style="margin-bottom:4px"><span style="font-size:11px;color:var(--text-muted);font-weight:600;text-transform:uppercase;letter-spacing:0.05em;padding:8px 16px;display:block">${escapeHTML(runtime)}</span>`;
    html += `<table class="data-table"><thead><tr><th>Name</th><th>State</th><th>UDID</th><th style="text-align:right">Actions</th></tr></thead><tbody>`;
    for (const s of devices) {
      const booted = s.isBooted || s.state === 'Booted';
      const dot = booted ? 'var(--success)' : 'var(--text-muted)';
      html += `<tr>
        <td><strong>${escapeHTML(s.name)}</strong></td>
        <td><span style="display:inline-block;width:6px;height:6px;border-radius:50%;background:${dot};margin-right:6px;vertical-align:middle"></span>${escapeHTML(s.state || '')}</td>
        <td style="font-family:var(--font-mono);font-size:11px;color:var(--text-muted)">${escapeHTML(s.id)}</td>
        <td style="text-align:right">
          ${booted
            ? `<button class="btn btn-primary btn-sm" onclick="simStartStream('${s.id}','${escapeHTML(s.name)}')">Stream</button>
               <button class="btn btn-secondary btn-sm" style="margin-left:4px" onclick="simAction('shutdown','${s.id}')">Shutdown</button>`
            : `<button class="btn btn-secondary btn-sm" onclick="simAction('boot','${s.id}')">Boot</button>`
          }
        </td>
      </tr>`;
    }
    html += `</tbody></table></div>`;
  }
  el.innerHTML = html;
}

// === Stream Mode ===

function buildDeviceFrame(name) {
  const container = document.getElementById('simDeviceFrame');
  container.innerHTML = '';

  const wrapper = document.createElement('div');
  wrapper.style.cssText = 'position:relative;display:inline-block;max-height:70vh;';

  const frameImg = document.createElement('img');
  frameImg.src = `${SIM_API}/frame?name=${encodeURIComponent(name)}`;
  frameImg.draggable = false;
  frameImg.style.cssText = 'display:block;height:100%;max-height:70vh;pointer-events:none;position:relative;z-index:2;';
  frameImg.onerror = () => {
    frameImg.style.display = 'none';
    screenArea.style.cssText = 'position:relative;height:100%;max-height:70vh;';
    img.style.cssText = 'display:block;height:100%;max-height:70vh;border-radius:12px;cursor:crosshair;';
  };

  const screenArea = document.createElement('div');
  screenArea.style.cssText = 'position:absolute;overflow:hidden;cursor:crosshair;border-radius:5.5%/2.8%;';

  const img = document.createElement('img');
  img.id = 'simStreamImg';
  img.style.cssText = 'display:block;width:100%;height:100%;object-fit:fill;';
  screenArea.appendChild(img);

  wrapper.appendChild(screenArea);
  wrapper.appendChild(frameImg);

  frameImg.onload = () => {
    const fw = frameImg.naturalWidth, fh = frameImg.naturalHeight;
    const inset = simFrameInsets[name];
    const ix = inset ? inset.screenInsetX : Math.round(fw * 0.05);
    const iy = inset ? inset.screenInsetY : Math.round(fh * 0.022);
    screenArea.style.left = (ix / fw * 100) + '%';
    screenArea.style.top = (iy / fh * 100) + '%';
    screenArea.style.width = ((fw - ix * 2) / fw * 100) + '%';
    screenArea.style.height = ((fh - iy * 2) / fh * 100) + '%';
  };

  // Touch handlers
  let startTime = 0;
  screenArea.addEventListener('mousedown', e => {
    e.preventDefault();
    const r = screenArea.getBoundingClientRect();
    simDragStart = { x: e.clientX - r.left, y: e.clientY - r.top };
    startTime = Date.now();
    simIsDragging = false;
  });
  screenArea.addEventListener('mousemove', e => {
    const r = screenArea.getBoundingClientRect();
    const cx = e.clientX - r.left, cy = e.clientY - r.top;
    if (simDragStart) {
      if (Math.sqrt((cx - simDragStart.x) ** 2 + (cy - simDragStart.y) ** 2) > 10) simIsDragging = true;
    }
  });
  screenArea.addEventListener('mouseup', e => {
    if (!simDragStart) return;
    const r = screenArea.getBoundingClientRect();
    const ex = e.clientX - r.left, ey = e.clientY - r.top;
    if (simIsDragging) simSwipeAt(simDragStart.x, simDragStart.y, ex, ey, r.width, r.height, Date.now() - startTime);
    else simTapAt(simDragStart.x, simDragStart.y, r.width, r.height, screenArea);
    simDragStart = null; simIsDragging = false;
  });
  screenArea.addEventListener('mouseleave', () => { simDragStart = null; simIsDragging = false; });

  container.appendChild(wrapper);
  return img;
}

function viewToDevice(vx, vy, vw, vh) {
  const inset = simStreamName ? simFrameInsets[simStreamName] : null;
  if (inset) {
    const ptW = (inset.outputWidth - inset.screenInsetX * 2) / 3;
    const ptH = (inset.outputHeight - inset.screenInsetY * 2) / 3;
    return { x: (vx / vw) * ptW, y: (vy / vh) * ptH };
  }
  return { x: (vx / vw) * 440, y: (vy / vh) * 956 };
}

async function simTapAt(vx, vy, vw, vh, el) {
  const { x, y } = viewToDevice(vx, vy, vw, vh);
  simLog(`tap(${Math.round(x)}, ${Math.round(y)})`);
  // Ripple
  const r = document.createElement('div');
  r.style.cssText = `position:absolute;width:30px;height:30px;border:2px solid var(--primary);border-radius:50%;transform:translate(-50%,-50%);pointer-events:none;left:${vx}px;top:${vy}px;animation:simRipple 0.4s ease-out forwards;`;
  el.appendChild(r); setTimeout(() => r.remove(), 400);
  try {
    await fetch(`${SIM_API}/tap`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid: simStreamUdid, x: Math.round(x), y: Math.round(y) }) });
  } catch (e) { simLog(e.message, true); }
}

async function simSwipeAt(vx1, vy1, vx2, vy2, vw, vh, durationMs) {
  const from = viewToDevice(vx1, vy1, vw, vh);
  const to = viewToDevice(vx2, vy2, vw, vh);
  const dist = Math.sqrt((to.x - from.x) ** 2 + (to.y - from.y) ** 2);
  simLog(`swipe(${Math.round(from.x)},${Math.round(from.y)} → ${Math.round(to.x)},${Math.round(to.y)})`);
  try {
    await fetch(`${SIM_API}/swipe`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid: simStreamUdid, fromX: Math.round(from.x), fromY: Math.round(from.y), toX: Math.round(to.x), toY: Math.round(to.y), duration: Math.max(0.1, (durationMs || 300) / 1000), delta: Math.max(1, Math.round(dist / 10)) }) });
  } catch (e) { simLog(e.message, true); }
}

function simLog(msg, isErr) {
  const log = document.getElementById('simActivityLog');
  if (!log) return;
  const t = new Date().toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
  const entry = document.createElement('div');
  entry.style.cssText = 'padding:2px 0;border-bottom:1px solid var(--border-light,rgba(0,0,0,0.05))';
  entry.innerHTML = `<span style="color:var(--text-muted);margin-right:6px">${t}</span><span style="color:var(--${isErr ? 'danger' : 'success'})">${escapeHTML(msg)}</span>`;
  if (log.children.length === 1 && !log.children[0].querySelector('span')) log.innerHTML = '';
  log.appendChild(entry);
  log.scrollTop = log.scrollHeight;
}

// === Global handlers ===

window.simRefresh = function () {
  showToast('Refreshing simulators...', 'info');
  loadSimulators();
};

window.simAction = async function (action, udid) {
  showToast(`Running: asc simulators ${action}...`, 'info');
  try {
    await DataProvider.fetch(`simulators ${action} --udid ${udid}`);
    showToast(`${action} succeeded`, 'success');
    setTimeout(() => loadSimDeviceList(), 1000);
  } catch (e) { showToast(`${action} failed`, 'error'); }
};

window.simStartStream = async function (udid, name) {
  simStreamUdid = udid; simStreamName = name;
  document.getElementById('simListView').style.display = 'none';
  document.getElementById('simStreamView').style.display = '';
  document.getElementById('simStreamTitle').textContent = name;
  document.getElementById('simActivityLog').innerHTML = '<div style="color:var(--text-muted)">Click device screen to interact</div>';

  const img = buildDeviceFrame(name);
  simFrameCount = 0;

  // Start capture
  try {
    const res = await fetch(`${SIM_API}/stream-start`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid }) });
    const data = await res.json();
    simLog(`Stream: ${data.method}`);
    await new Promise(r => setTimeout(r, 500));
  } catch {}

  // Frame polling
  const loadFrame = () => {
    if (!simStreamUdid) return;
    const url = `${SIM_API}/screenshot?udid=${udid}&t=${Date.now()}`;
    const tmp = new Image();
    tmp.onload = () => {
      if (tmp.naturalWidth > 0) { simImgNaturalW = tmp.naturalWidth; simImgNaturalH = tmp.naturalHeight; }
      img.src = tmp.src;
      simFrameCount++;
      if (simStreamUdid) simStreamTimer = setTimeout(loadFrame, 100);
    };
    tmp.onerror = () => { if (simStreamUdid) simStreamTimer = setTimeout(loadFrame, 500); };
    tmp.src = url;
  };
  loadFrame();

  simFpsTimer = setInterval(() => {
    const el = document.getElementById('simStreamFps');
    if (el) el.textContent = simFrameCount + ' fps';
    simFrameCount = 0;
  }, 1000);
};

window.simStopStream = function () {
  simStreamUdid = null; simStreamName = null;
  if (simStreamTimer) { clearTimeout(simStreamTimer); simStreamTimer = null; }
  if (simFpsTimer) { clearInterval(simFpsTimer); simFpsTimer = null; }
  fetch(`${SIM_API}/stream-stop`, { method: 'POST' }).catch(() => {});
  document.getElementById('simStreamView').style.display = 'none';
  document.getElementById('simListView').style.display = '';
  loadSimDeviceList();
};

window.simButton = async function (button) {
  simLog(`button(${button})`);
  try { await fetch(`${SIM_API}/button`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid: simStreamUdid, button }) }); }
  catch (e) { simLog(e.message, true); }
};

window.simGesture = async function (gesture) {
  simLog(`gesture(${gesture})`);
  try { await fetch(`${SIM_API}/gesture`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid: simStreamUdid, gesture }) }); }
  catch (e) { simLog(e.message, true); }
};

window.simSendText = async function () {
  const input = document.getElementById('simTextInput');
  const text = input.value; if (!text) return;
  simLog(`type("${text.length > 20 ? text.slice(0, 20) + '...' : text}")`);
  try { await fetch(`${SIM_API}/type`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid: simStreamUdid, text }) }); }
  catch (e) { simLog(e.message, true); }
  input.value = ''; input.focus();
};

window.simKey = async function (keycode) {
  const names = { 40: 'Return', 42: 'Backspace', 43: 'Tab', 41: 'Escape' };
  simLog(`key(${names[keycode] || keycode})`);
  try { await fetch(`${SIM_API}/key`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid: simStreamUdid, keycode }) }); }
  catch (e) { simLog(e.message, true); }
};

window.simTapById = async function () {
  const id = document.getElementById('simTapIdInput').value; if (!id) return;
  simLog(`tap(id: "${id}")`);
  try { await fetch(`${SIM_API}/tap`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ udid: simStreamUdid, id }) }); }
  catch (e) { simLog(e.message, true); }
};

window.simDescribeUI = async function () {
  simLog('describe-ui...');
  try {
    const res = await fetch(`${SIM_API}/describe?udid=${simStreamUdid}`);
    const data = await res.json();
    if (data.tree) { simLog(`UI tree: ${data.tree.length} chars`); console.log('=== UI Tree ===\n' + data.tree); }
  } catch (e) { simLog(e.message, true); }
};

// Ripple animation (injected once)
if (!document.getElementById('simRippleStyle')) {
  const style = document.createElement('style');
  style.id = 'simRippleStyle';
  style.textContent = '@keyframes simRipple { 0% { opacity:1;width:10px;height:10px } 100% { opacity:0;width:40px;height:40px } }';
  document.head.appendChild(style);
}
