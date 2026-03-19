// Page: Versions
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { showToast } from '../toast.js';
import { escapeHTML, statusBadge, formatDate } from '../helpers.js';

export function renderVersions() {
  const appName = state.selectedApp?.name || 'All Apps';
  return `
    <div class="card">
      <div class="toolbar">
        <div class="toolbar-left">
          <span style="font-size:13px;color:var(--text-muted)">App:</span>
          <span style="font-size:13px;font-weight:600">${escapeHTML(appName)}</span>
          <div class="filter-group">
            <button class="filter-btn active" onclick="filterVersions('all',this)">All</button>
            <button class="filter-btn" onclick="filterVersions('live',this)">Live</button>
            <button class="filter-btn" onclick="filterVersions('editable',this)">Editable</button>
          </div>
        </div>
        <div class="toolbar-right">
          <button class="btn btn-primary btn-sm" onclick="openModal('createVersionModal')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>New Version</button>
        </div>
      </div>
      <div class="table-wrapper" id="versionsTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>`;
}

export async function loadVersions() {
  const appId = state.selectedApp?.id || '6449071230';
  const result = await DataProvider.fetch(`versions list --app-id ${appId}`);
  if (result?.data) {
    state.versions = result.data;
    renderVersionRows(result.data);
  }
}

function renderVersionRows(versions) {
  document.getElementById('versionsTable').innerHTML = `<table><thead><tr><th>Version</th><th>Platform</th><th>State</th><th>Build</th><th>Created</th><th style="text-align:right">Actions</th></tr></thead><tbody>${versions.map(v => `<tr>
    <td><span class="cell-primary">${v.versionString}</span></td>
    <td><span class="platform-badge">${v.platform}</span></td>
    <td>${statusBadge(v.state)}</td>
    <td>${v.buildId ? `<span class="cell-mono">${v.buildId}</span>` : '<span style="color:var(--text-muted)">No build</span>'}</td>
    <td>${formatDate(v.createdDate)}</td>
    <td class="text-right">
      ${v.affordances?.checkReadiness ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(v.affordances.checkReadiness)}')">Check</button>` : ''}
      ${v.affordances?.submitForReview ? `<button class="btn btn-sm btn-success" onclick="runAffordance('${escapeHTML(v.affordances.submitForReview)}')">Submit</button>` : ''}
      ${v.affordances?.listLocalizations ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(v.affordances.listLocalizations)}')">Localizations</button>` : ''}
    </td>
  </tr>`).join('')}</tbody></table>`;
}

function filterVersions(type, btn) {
  btn.parentElement.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  let filtered = state.versions;
  if (type === 'live') filtered = filtered.filter(v => v.isLive);
  if (type === 'editable') filtered = filtered.filter(v => v.isEditable);
  renderVersionRows(filtered);
}

async function createVersion() {
  const version = document.getElementById('cvVersion').value;
  const platform = document.getElementById('cvPlatform').value;
  if (!version) { showToast('Enter a version number', 'error'); return; }
  const appId = state.selectedApp?.id || '6449071230';
  await DataProvider.fetch(`versions create --app-id ${appId} --version-string ${version} --platform ${platform}`);
  window.closeModal('createVersionModal');
  showToast(`Version ${version} created!`, 'success');
  loadVersions();
}

window.filterVersions = filterVersions;
window.createVersion = createVersion;
