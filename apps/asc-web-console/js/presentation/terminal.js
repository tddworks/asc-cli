// Presentation: Terminal panel — command execution + output rendering
import { escapeHtml, stateColor } from './helpers.js';

let API_BASE = '';
let terminalOpen = false;
let cmdHistory = [];
let historyIndex = -1;
let isRunning = false;

const els = {};

export function initTerminal() {
  els.panel = document.getElementById('terminal-panel');
  els.input = document.getElementById('cmd-input');
  els.output = document.getElementById('cmd-output');
  els.status = document.getElementById('terminal-status');

  document.getElementById('terminal-btn').addEventListener('click', () => toggleTerminal());
  document.getElementById('terminal-close').addEventListener('click', () => toggleTerminal(false));
  document.getElementById('terminal-clear').addEventListener('click', () => {
    els.output.innerHTML = '<div style="color: var(--text-dim)">Terminal cleared.</div>';
  });

  els.input.addEventListener('keydown', handleInput);
}

export async function detectServer() {
  for (const base of ['', 'http://127.0.0.1:8420']) {
    try {
      const controller = new AbortController();
      setTimeout(() => controller.abort(), 2000);
      const res = await fetch(`${base}/api/run`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command: 'asc version' }),
        signal: controller.signal,
      });
      if (res.ok) { API_BASE = base; return true; }
    } catch {}
  }
  return false;
}

export function getServerUrl() { return API_BASE || window.location.origin; }

export function toggleTerminal(show) {
  const shouldShow = show !== undefined ? show : !terminalOpen;
  terminalOpen = shouldShow;
  if (shouldShow) {
    els.panel.classList.add('open');
    setTimeout(() => els.input.focus(), 300);
  } else {
    els.panel.classList.remove('open');
  }
}

export function isTerminalOpen() { return terminalOpen; }

export async function executeCommand(cmd) {
  if (isRunning) return;
  isRunning = true;

  if (cmdHistory[0] !== cmd) cmdHistory.unshift(cmd);
  if (cmdHistory.length > 50) cmdHistory.pop();
  historyIndex = -1;

  const cmdLine = document.createElement('div');
  cmdLine.innerHTML = `<span style="color: #60a5fa; user-select: none;">$ </span><span style="color: var(--text-primary)">${escapeHtml(cmd)}</span>`;
  els.output.appendChild(cmdLine);

  const loader = document.createElement('div');
  loader.style.cssText = 'display: flex; align-items: center; gap: 8px; color: var(--text-dim)';
  loader.innerHTML = `<svg style="width:12px;height:12px" class="animate-spin" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" opacity="0.25"/><path d="M12 2a10 10 0 019.95 9" stroke="currentColor" stroke-width="3" stroke-linecap="round"/></svg> Running...`;
  els.output.appendChild(loader);
  els.output.scrollTop = els.output.scrollHeight;
  setStatus('running', 'status-running');

  try {
    const res = await fetch(`${API_BASE}/api/run`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ command: cmd }),
    });
    const data = await res.json();
    loader.remove();

    if (data.error) {
      appendText(data.error, 'var(--danger)');
      setStatus('error', 'status-error');
    } else {
      if (data.stdout?.trim()) {
        try { appendJson(JSON.parse(data.stdout)); }
        catch { appendText(data.stdout.trim(), 'var(--text-secondary)'); }
      }
      if (data.stderr?.trim()) appendText(data.stderr.trim(), 'rgba(251,191,36,0.7)');
      if (data.exit_code !== 0) {
        appendText(`Exit code: ${data.exit_code}`, 'rgba(248,113,113,0.6)');
        setStatus('error', 'status-error');
      } else {
        setStatus('ready', 'status-ready');
      }
      if (!data.stdout?.trim() && !data.stderr?.trim() && data.exit_code === 0) {
        appendText('(no output)', 'var(--text-dim)');
        setStatus('ready', 'status-ready');
      }
    }
  } catch (err) {
    loader.remove();
    appendText(`Connection error: ${err.message}. Is the server running?\n  asc web-server`, 'var(--danger)');
    setStatus('error', 'status-error');
  }

  const spacer = document.createElement('div');
  spacer.style.height = '8px';
  els.output.appendChild(spacer);
  els.output.scrollTop = els.output.scrollHeight;
  isRunning = false;
}

function setStatus(text, cls) {
  els.status.textContent = text;
  els.status.className = `status-badge ${cls}`;
}

function appendText(text, color) {
  const el = document.createElement('pre');
  el.style.cssText = `color: ${color}; white-space: pre-wrap; word-break: break-word; line-height: 1.6;`;
  el.textContent = text;
  els.output.appendChild(el);
}

function appendJson(json) {
  const el = document.createElement('div');
  el.style.color = 'var(--text-secondary)';
  el.style.lineHeight = '1.6';

  if (Array.isArray(json)) {
    if (json.length > 0 && typeof json[0] === 'object') {
      el.innerHTML = renderJsonTable(json);
    } else {
      el.innerHTML = `<pre style="white-space:pre-wrap">${escapeHtml(JSON.stringify(json, null, 2))}</pre>`;
    }
  } else if (typeof json === 'object' && json !== null) {
    if (Array.isArray(json.data) && json.data.length > 0 && typeof json.data[0] === 'object') {
      el.innerHTML = renderJsonTable(json.data);
      if (json.affordances) el.innerHTML += renderAffordances(json.affordances);
    } else {
      el.innerHTML = renderJsonObject(json);
    }
  } else {
    el.textContent = JSON.stringify(json, null, 2);
  }
  els.output.appendChild(el);
}

function renderJsonTable(rows) {
  if (!rows.length) return '<span style="color: var(--text-dim)">(empty)</span>';
  const allKeys = [...new Set(rows.flatMap(r => Object.keys(r)))];
  const priority = ['id', 'name', 'appName', 'bundleId', 'state', 'platform', 'version', 'locale', 'type', 'status'];
  const keys = [
    ...priority.filter(k => allKeys.includes(k)),
    ...allKeys.filter(k => !priority.includes(k) && k !== 'affordances')
  ].slice(0, 8);
  const hasAffordances = rows.some(r => r.affordances);

  return `
    <div style="overflow-x:auto; border-radius:8px; border:1px solid var(--border); margin:4px 0">
      <table class="json-table">
        <thead><tr>
          ${keys.map(k => `<th>${escapeHtml(k)}</th>`).join('')}
          ${hasAffordances ? '<th>actions</th>' : ''}
        </tr></thead>
        <tbody>
          ${rows.map(row => `<tr>
            ${keys.map(k => {
              const val = row[k];
              const display = val === null || val === undefined ? '' : typeof val === 'object' ? JSON.stringify(val) : String(val);
              const style = (k === 'state' || k === 'status') ? stateColor(display) : k === 'id' ? 'color: rgba(96,165,250,0.7)' : '';
              return `<td style="${style}" title="${escapeHtml(display)}">${escapeHtml(display)}</td>`;
            }).join('')}
            ${hasAffordances && row.affordances ? `<td><div style="display:flex;flex-wrap:wrap;gap:4px">${Object.entries(row.affordances).map(([name, cmd]) =>
              `<button class="affordance-btn run-affordance" data-cmd="${escapeHtml(cmd)}" title="${escapeHtml(cmd)}">${escapeHtml(name)}</button>`
            ).join('')}</div></td>` : hasAffordances ? '<td></td>' : ''}
          </tr>`).join('')}
        </tbody>
      </table>
    </div>
    <div style="font-size:10px; color:var(--text-dim); margin-top:4px">${rows.length} record${rows.length !== 1 ? 's' : ''}</div>
  `;
}

function renderAffordances(affordances) {
  return `<div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:8px">${Object.entries(affordances).map(([name, cmd]) =>
    `<button class="affordance-btn run-affordance" data-cmd="${escapeHtml(cmd)}" title="${escapeHtml(cmd)}">${escapeHtml(name)}</button>`
  ).join('')}</div>`;
}

function renderJsonObject(obj) {
  const entries = Object.entries(obj).filter(([k]) => k !== 'affordances');
  let html = '<div style="margin:4px 0">';
  entries.forEach(([key, val]) => {
    const display = val === null || val === undefined ? 'null' : typeof val === 'object' ? JSON.stringify(val) : String(val);
    const style = (key === 'state' || key === 'status') ? stateColor(display) : key === 'id' ? 'color: rgba(96,165,250,0.7)' : typeof val === 'boolean' ? (val ? 'color: var(--success)' : 'color: rgba(248,113,113,0.6)') : '';
    html += `<div style="display:flex;gap:12px"><span style="color:var(--text-dim);flex-shrink:0;width:144px;text-align:right">${escapeHtml(key)}</span><span style="${style}">${escapeHtml(display)}</span></div>`;
  });
  html += '</div>';
  if (obj.affordances) html += renderAffordances(obj.affordances);
  return html;
}

function handleInput(e) {
  if (e.key === 'Enter') {
    const cmd = els.input.value.trim();
    if (!cmd || isRunning) return;
    els.input.value = '';
    const finalCmd = cmd.startsWith('asc ') || cmd === 'asc' ? cmd : `asc ${cmd}`;
    executeCommand(finalCmd);
  }
  if (e.key === 'ArrowUp') {
    e.preventDefault();
    if (historyIndex < cmdHistory.length - 1) { historyIndex++; els.input.value = cmdHistory[historyIndex]; }
  }
  if (e.key === 'ArrowDown') {
    e.preventDefault();
    if (historyIndex > 0) { historyIndex--; els.input.value = cmdHistory[historyIndex]; }
    else { historyIndex = -1; els.input.value = ''; }
  }
}
