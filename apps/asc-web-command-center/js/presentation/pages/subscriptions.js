// Page: Subscriptions
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { showToast } from '../toast.js';
import { escapeHTML } from '../helpers.js';

export function renderSubscriptions() {
  return `
    <div class="card mb-24">
      <div class="toolbar">
        <div class="toolbar-left"><span class="card-title">Subscription Groups</span></div>
        <div class="toolbar-right">
          <button class="btn btn-sm btn-primary" onclick="showToast('asc subscription-groups create','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>New Group</button>
        </div>
      </div>
      <div class="table-wrapper" id="subGroupsTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><span class="card-title">Offer Codes</span></div>
      <div class="card-body padded">
        <div style="display:flex;gap:8px">
          <button class="btn btn-secondary btn-sm" onclick="showToast('asc subscription-offer-codes list','info')">List Codes</button>
          <button class="btn btn-secondary btn-sm" onclick="showToast('asc subscription-offer-codes create','info')">Create Code</button>
          <button class="btn btn-secondary btn-sm" onclick="showToast('asc subscription-offer-code-custom-codes list','info')">Custom Codes</button>
        </div>
      </div>
    </div>`;
}

export async function loadSubscriptions() {
  const appId = state.selectedApp?.id || '6449071230';
  const result = await DataProvider.fetch(`subscription-groups list --app-id ${appId}`);
  if (result?.data) {
    document.getElementById('subGroupsTable').innerHTML = `<table><thead><tr><th>Group</th><th>App ID</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(g => `<tr>
      <td><span class="cell-primary">${escapeHTML(g.referenceName)}</span></td>
      <td><span class="cell-mono">${g.appId}</span></td>
      <td class="text-right">
        ${Object.entries(g.affordances || {}).map(([k, cmd]) =>
          `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(cmd)}')">${k.replace(/([A-Z])/g, ' $1').trim()}</button>`
        ).join(' ')}
      </td>
    </tr>`).join('')}</tbody></table>`;
  }
}
