// Page: TestFlight
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { showToast } from '../toast.js';
import { escapeHTML } from '../helpers.js';

export function renderTestFlight() {
  return `
    <div class="grid-2 mb-24">
      <div class="card">
        <div class="card-header">
          <span class="card-title">Beta Groups</span>
          <button class="btn btn-sm btn-primary" onclick="showToast('asc testflight groups create','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>Add Group</button>
        </div>
        <div class="card-body" id="betaGroupsList">
          <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <span class="card-title">Quick Tester Actions</span>
        </div>
        <div class="card-body padded">
          <div class="form-group">
            <label class="form-label">Add Tester by Email</label>
            <div style="display:flex;gap:8px">
              <input class="form-input" placeholder="tester@example.com" id="testerEmail" style="flex:1"/>
              <button class="btn btn-primary" onclick="addTester()">Add</button>
            </div>
            <div class="form-hint">Adds to the first external beta group</div>
          </div>
          <div style="display:flex;gap:8px;margin-top:16px">
            <button class="btn btn-sm btn-secondary" onclick="showToast('asc testflight testers import --file testers.csv','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>Import CSV</button>
            <button class="btn btn-sm btn-secondary" onclick="showToast('asc testflight testers export','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>Export CSV</button>
          </div>
        </div>
      </div>
    </div>`;
}

export async function loadTestFlight() {
  const appId = state.selectedApp?.id || '6449071230';
  const result = await DataProvider.fetch(`testflight groups list --app-id ${appId}`);
  if (result?.data) {
    document.getElementById('betaGroupsList').innerHTML = `<table><thead><tr><th>Group</th><th>Type</th><th>Public Link</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(g => `<tr>
      <td><span class="cell-primary">${escapeHTML(g.name)}</span></td>
      <td>${g.isInternalGroup ? '<span class="status draft">Internal</span>' : '<span class="status processing">External</span>'}</td>
      <td>${g.publicLinkEnabled ? '<span class="status live">Enabled</span>' : '<span class="status draft">Off</span>'}</td>
      <td class="text-right">
        ${Object.entries(g.affordances || {}).map(([k, cmd]) =>
          `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(cmd)}')">${k.replace(/([A-Z])/g, ' $1').trim()}</button>`
        ).join(' ')}
      </td>
    </tr>`).join('')}</tbody></table>`;
  }
}

function addTester() {
  const email = document.getElementById('testerEmail').value;
  if (!email) { showToast('Enter an email address', 'error'); return; }
  DataProvider.fetch(`testflight testers add --beta-group-id bg-002 --email ${email}`);
  showToast(`Invited ${email} to TestFlight`, 'success');
  document.getElementById('testerEmail').value = '';
}

window.addTester = addTester;
