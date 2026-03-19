// Page: Builds
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { escapeHTML, statusBadge, formatDate } from '../helpers.js';

export function renderBuilds() {
  return `
    <div class="card">
      <div class="toolbar">
        <div class="toolbar-left">
          <div class="filter-group">
            <button class="filter-btn active">All</button>
            <button class="filter-btn">Valid</button>
            <button class="filter-btn">Processing</button>
            <button class="filter-btn">Invalid</button>
          </div>
        </div>
        <div class="toolbar-right">
          <button class="btn btn-primary btn-sm" onclick="showToast('Use: asc builds archive --scheme MyApp','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>Upload Build</button>
        </div>
      </div>
      <div class="table-wrapper" id="buildsTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>`;
}

export async function loadBuilds() {
  const appId = state.selectedApp?.id || '6449071230';
  const result = await DataProvider.fetch(`builds list --app-id ${appId}`);
  if (result?.data) {
    state.builds = result.data;
    document.getElementById('buildsTable').innerHTML = `<table><thead><tr><th>Build</th><th>Version</th><th>Usable</th><th>Status</th><th>Expired</th><th>Uploaded</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(b => `<tr>
      <td><span class="cell-primary">#${b.buildNumber}</span></td>
      <td>${b.version}</td>
      <td>${b.isUsable ? '<span class="status live">Yes</span>' : '<span class="status draft">No</span>'}</td>
      <td>${statusBadge(b.processingState)}</td>
      <td>${b.expired ? '<span class="status rejected">Expired</span>' : '<span class="status live">Active</span>'}</td>
      <td>${formatDate(b.uploadedDate)}</td>
      <td class="text-right">
        ${b.affordances?.addToTestFlight ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(b.affordances.addToTestFlight)}')">TestFlight</button>` : '<span style="color:var(--text-muted);font-size:11px">Not usable</span>'}
      </td>
    </tr>`).join('')}</tbody></table>`;
  }
}
