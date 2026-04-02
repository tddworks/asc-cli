// Page: Simulators (free tier)
// Stream UI is provided by the ASC Pro plugin (sim-stream.js)
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { escapeHTML } from '../helpers.js';
import { showToast } from '../toast.js';

// Make helpers available to plugins
window.escapeHTML = escapeHTML;
window.DataProvider = DataProvider;

let simFrameInsets = {};
let simAxeAvailable = false;
let _allDevices = [];

function getSimAPI() {
  return (DataProvider._serverUrl || '') + '/api/sim';
}

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
          <div style="display:flex;align-items:center;gap:8px">
            <input type="text" id="simSearchInput" placeholder="Search devices..." oninput="simApplyFilters()"
              style="padding:6px 10px;border:1px solid var(--border);border-radius:6px;font-size:12px;width:180px;background:var(--bg);color:var(--text)">
            <select id="simTypeFilter" onchange="simApplyFilters()"
              style="padding:6px 8px;border:1px solid var(--border);border-radius:6px;font-size:12px;background:var(--bg);color:var(--text)">
              <option value="all">All Devices</option>
              <option value="iphone" selected>iPhones</option>
              <option value="ipad">iPads</option>
            </select>
            <select id="simRuntimeFilter" onchange="simApplyFilters()"
              style="padding:6px 8px;border:1px solid var(--border);border-radius:6px;font-size:12px;background:var(--bg);color:var(--text)">
              <option value="latest">Latest Runtime</option>
              <option value="all">All Runtimes</option>
            </select>
            <button class="btn btn-sm btn-secondary" onclick="simRefresh()">Refresh</button>
          </div>
        </div>
        <div class="card-body" id="simDeviceList">
          <div class="empty-state"><div class="spinner" style="margin: 24px auto"></div></div>
        </div>
      </div>

      <div class="card mt-16" style="margin-top:16px">
        <div class="card-header"><span class="card-title">Quick Actions</span></div>
        <div class="card-body padded">
          <div class="quick-actions">
            <button class="action-btn" onclick="runAffordance('asc simulators list --output table')">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><rect x="5" y="2" width="14" height="20" rx="2"/><line x1="12" y1="18" x2="12" y2="18"/></svg>
              List Simulators
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Plugin views injected here -->
    <div id="simPluginView" style="display:none"></div>
  `;
}

export async function loadSimulators() {
  loadSimDeviceList();
  loadPluginScripts();
}

// --- Device List ---

async function loadSimDeviceList() {
  try {
    const res = await fetch(`${getSimAPI()}/devices`);
    const data = await res.json();
    _allDevices = data.devices || [];
    simAxeAvailable = data.axeAvailable || false;
    updateStats();
    simApplyFilters();
  } catch {
    const el = document.getElementById('simDeviceList');
    if (el) el.innerHTML = '<div class="empty-state">Could not list simulators</div>';
  }
}
window.loadSimDeviceList = loadSimDeviceList;

function updateStats() {
  const booted = _allDevices.filter(d => d.state === 'Booted' || d.isBooted);
  const el = (id, val) => { const e = document.getElementById(id); if (e) e.textContent = val; };
  el('simBootedCount', booted.length);
  el('simBootedBadge', booted.length > 0 ? 'Active' : '');
  el('simTotalCount', _allDevices.length);
  el('simAxeStatus', simAxeAvailable ? 'Ready' : 'Not Found');
  el('simAxeBadge', simAxeAvailable ? 'Installed' : '');
}

function simApplyFilters() {
  const search = (document.getElementById('simSearchInput')?.value || '').toLowerCase();
  const typeFilter = document.getElementById('simTypeFilter')?.value || 'all';
  const runtimeFilter = document.getElementById('simRuntimeFilter')?.value || 'latest';

  let devices = _allDevices;
  if (search) devices = devices.filter(d => d.name?.toLowerCase().includes(search));
  if (typeFilter === 'iphone') devices = devices.filter(d => /iphone/i.test(d.name));
  else if (typeFilter === 'ipad') devices = devices.filter(d => /ipad/i.test(d.name));

  if (runtimeFilter === 'latest' && devices.length > 0) {
    const runtimes = [...new Set(devices.map(d => d.displayRuntime || d.runtime))].sort().reverse();
    if (runtimes.length) devices = devices.filter(d => (d.displayRuntime || d.runtime) === runtimes[0]);
  }

  const el = document.getElementById('simDeviceList');
  if (el) el.innerHTML = renderDeviceTable(devices);
}
window.simApplyFilters = simApplyFilters;

function renderDeviceTable(devices) {
  const booted = devices.filter(d => d.state === 'Booted' || d.isBooted);
  const available = devices.filter(d => d.state !== 'Booted' && !d.isBooted);

  let html = '';
  if (booted.length) html += renderSection('Running', booted);
  if (available.length) html += renderSection('Available', available);
  if (!devices.length) html = '<div class="empty-state">No simulators found</div>';
  return html;
}

function renderSection(title, devices) {
  let html = `<div style="padding:8px 16px;font-size:11px;font-weight:600;color:var(--primary);text-transform:uppercase">${title}</div>`;
  html += `<table class="data-table"><thead><tr><th>Name</th><th>State</th><th>Runtime</th><th style="text-align:right">Actions</th></tr></thead><tbody>`;
  for (const s of devices) {
    const dot = s.state === 'Booted' ? 'var(--success)' : 'var(--text-muted)';
    html += `<tr>
      <td><strong>${escapeHTML(s.name)}</strong></td>
      <td><span style="display:inline-block;width:6px;height:6px;border-radius:50%;background:${dot};margin-right:6px;vertical-align:middle"></span>${escapeHTML(s.state || '')}</td>
      <td style="font-size:12px;color:var(--text-muted)">${escapeHTML(s.displayRuntime || '')}</td>
      <td style="text-align:right">
        ${Object.entries(s.affordances || {}).filter(([k]) => k !== 'listSimulators').map(([key, cmd]) => {
          const label = key.charAt(0).toUpperCase() + key.slice(1);
          return `<button class="btn btn-secondary btn-sm" style="margin-left:4px" onclick="simAffordance('${escapeHTML(key)}','${s.id}','${escapeHTML(s.name)}','${escapeHTML(cmd)}')">${escapeHTML(label)}</button>`;
        }).join('')}
      </td>
    </tr>`;
  }
  html += `</tbody></table>`;
  return html;
}

// --- Affordance Handler Registry (OCP — plugins extend this) ---

window.simAffordanceHandlers = window.simAffordanceHandlers || {};

window.simAffordance = function (key, id, name, cmd) {
  const handler = window.simAffordanceHandlers[key];
  if (handler) {
    handler(id, name, cmd);
  } else {
    // Default: execute command via API
    showToast(`Running: ${cmd}...`, 'info');
    DataProvider.fetch(cmd.replace(/^asc\s+/, ''))
      .then(() => { showToast(`${key} succeeded`, 'success'); setTimeout(() => loadSimDeviceList(), 1000); })
      .catch(() => showToast(`${key} failed`, 'error'));
  }
};

// Built-in handlers
window.simAffordanceHandlers['boot'] = (id) => {
  showToast('Booting...', 'info');
  DataProvider.fetch(`simulators boot --udid ${id}`)
    .then(() => { showToast('Booted', 'success'); setTimeout(() => loadSimDeviceList(), 1000); })
    .catch(() => showToast('Boot failed', 'error'));
};
window.simAffordanceHandlers['shutdown'] = (id) => {
  showToast('Shutting down...', 'info');
  DataProvider.fetch(`simulators shutdown --udid ${id}`)
    .then(() => { showToast('Shutdown', 'success'); setTimeout(() => loadSimDeviceList(), 1000); })
    .catch(() => showToast('Shutdown failed', 'error'));
};

window.simRefresh = function () {
  showToast('Refreshing...', 'info');
  loadSimDeviceList();
};

// --- Plugin Script Loader ---

async function loadPluginScripts() {
  try {
    const res = await fetch(`${DataProvider._serverUrl || ''}/api/plugins`);
    const data = await res.json();
    for (const plugin of (data.plugins || [])) {
      for (const url of (plugin.ui || [])) {
        const fullUrl = `${DataProvider._serverUrl || ''}${url}`;
        const script = document.createElement('script');
        script.src = fullUrl;
        script.async = true;
        document.head.appendChild(script);
      }
    }
  } catch {}
}
