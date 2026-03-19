// Page: In-App Purchases
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { showToast } from '../toast.js';
import { escapeHTML, statusBadge } from '../helpers.js';

export function renderIAP() {
  return `
    <div class="card">
      <div class="toolbar">
        <div class="toolbar-left"><span class="card-title">In-App Purchases</span></div>
        <div class="toolbar-right">
          <button class="btn btn-sm btn-primary" onclick="showToast('asc iap create --type non-consumable','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>Create IAP</button>
        </div>
      </div>
      <div class="table-wrapper" id="iapTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>`;
}

export async function loadIAP() {
  const appId = state.selectedApp?.id || '6449071230';
  const result = await DataProvider.fetch(`iap list --app-id ${appId}`);
  if (result?.data) {
    document.getElementById('iapTable').innerHTML = `<table><thead><tr><th>Name</th><th>Product ID</th><th>Type</th><th>State</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(p => `<tr>
      <td><span class="cell-primary">${escapeHTML(p.referenceName)}</span></td>
      <td><span class="cell-mono">${p.productId}</span></td>
      <td><span class="platform-badge">${p.type}</span></td>
      <td>${statusBadge(p.state)}</td>
      <td class="text-right">
        ${p.affordances?.submit ? `<button class="btn btn-sm btn-success" onclick="runAffordance('${escapeHTML(p.affordances.submit)}')">Submit</button>` : ''}
        ${p.affordances?.listLocalizations ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(p.affordances.listLocalizations)}')">Locales</button>` : ''}
      </td>
    </tr>`).join('')}</tbody></table>`;
  }
}
