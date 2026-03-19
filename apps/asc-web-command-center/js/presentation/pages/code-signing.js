// Page: Code Signing
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { showToast } from '../toast.js';
import { escapeHTML, formatDate } from '../helpers.js';

export function renderCodeSigning() {
  return `
    <div class="detail-tabs mb-24" id="cssTabs">
      <button class="detail-tab active" onclick="switchCSTab('bundles',this)">Bundle IDs</button>
      <button class="detail-tab" onclick="switchCSTab('certs',this)">Certificates</button>
      <button class="detail-tab" onclick="switchCSTab('devices',this)">Devices</button>
      <button class="detail-tab" onclick="switchCSTab('profiles',this)">Profiles</button>
    </div>
    <div class="card">
      <div class="toolbar">
        <div class="toolbar-left"></div>
        <div class="toolbar-right">
          <button class="btn btn-sm btn-primary" id="cssCreateBtn" onclick="showToast('asc bundle-ids create','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>Register</button>
        </div>
      </div>
      <div class="table-wrapper" id="cssTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>`;
}

export async function loadCodeSigning() {
  switchCSTab('bundles', document.querySelector('#cssTabs .detail-tab.active'));
}

async function switchCSTab(tab, btn) {
  document.querySelectorAll('#cssTabs .detail-tab').forEach(t => t.classList.remove('active'));
  if (btn) btn.classList.add('active');

  const tableEl = document.getElementById('cssTable');
  tableEl.innerHTML = '<div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>';

  if (tab === 'bundles') {
    const result = await DataProvider.fetch('bundle-ids list');
    if (result?.data) {
      tableEl.innerHTML = `<table><thead><tr><th>Name</th><th>Identifier</th><th>Platform</th><th>Seed ID</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(b => `<tr>
        <td><span class="cell-primary">${escapeHTML(b.name)}</span></td>
        <td><span class="cell-mono">${b.identifier}</span></td>
        <td><span class="platform-badge">${b.platform}</span></td>
        <td><span class="cell-mono">${b.seedID || '--'}</span></td>
        <td class="text-right">
          ${b.affordances?.delete ? `<button class="btn btn-sm btn-danger" onclick="runAffordance('${escapeHTML(b.affordances.delete)}')">Delete</button>` : ''}
          ${b.affordances?.listProfiles ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(b.affordances.listProfiles)}')">Profiles</button>` : ''}
        </td>
      </tr>`).join('')}</tbody></table>`;
    }
  }
  else if (tab === 'certs') {
    const result = await DataProvider.fetch('certificates list');
    if (result?.data) {
      tableEl.innerHTML = `<table><thead><tr><th>Name</th><th>Type</th><th>Serial</th><th>Expires</th><th>Status</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(c => `<tr>
        <td><span class="cell-primary">${escapeHTML(c.displayName || c.name)}</span></td>
        <td><span class="platform-badge">${c.certificateType}</span></td>
        <td><span class="cell-mono">${c.serialNumber || '--'}</span></td>
        <td>${formatDate(c.expirationDate)}</td>
        <td>${c.isExpired ? '<span class="status rejected">Expired</span>' : '<span class="status live">Valid</span>'}</td>
        <td class="text-right">
          ${c.affordances?.revoke ? `<button class="btn btn-sm btn-danger" onclick="runAffordance('${escapeHTML(c.affordances.revoke)}')">Revoke</button>` : ''}
        </td>
      </tr>`).join('')}</tbody></table>`;
    }
  }
  else if (tab === 'devices') {
    const result = await DataProvider.fetch('devices list');
    if (result?.data) {
      tableEl.innerHTML = `<table><thead><tr><th>Name</th><th>UDID</th><th>Class</th><th>Model</th><th>Status</th></tr></thead><tbody>${result.data.map(d => `<tr>
        <td><span class="cell-primary">${escapeHTML(d.name)}</span></td>
        <td><span class="cell-mono">${d.udid.substring(0, 16)}...</span></td>
        <td><span class="platform-badge">${d.deviceClass}</span></td>
        <td>${d.model || '--'}</td>
        <td>${d.status === 'ENABLED' ? '<span class="status live">Enabled</span>' : '<span class="status draft">Disabled</span>'}</td>
      </tr>`).join('')}</tbody></table>`;
    }
  }
  else if (tab === 'profiles') {
    const result = await DataProvider.fetch('profiles list');
    if (result?.data) {
      tableEl.innerHTML = `<table><thead><tr><th>Name</th><th>Type</th><th>State</th><th>Expires</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(p => `<tr>
        <td><span class="cell-primary">${escapeHTML(p.name)}</span></td>
        <td><span class="platform-badge">${p.profileType}</span></td>
        <td>${p.isActive ? '<span class="status live">Active</span>' : '<span class="status rejected">Invalid</span>'}</td>
        <td>${formatDate(p.expirationDate)}</td>
        <td class="text-right">
          ${p.affordances?.delete ? `<button class="btn btn-sm btn-danger" onclick="runAffordance('${escapeHTML(p.affordances.delete)}')">Delete</button>` : ''}
        </td>
      </tr>`).join('')}</tbody></table>`;
    }
  }
}

window.switchCSTab = switchCSTab;
