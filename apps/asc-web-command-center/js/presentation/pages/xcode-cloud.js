// Page: Xcode Cloud
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { showToast } from '../toast.js';
import { escapeHTML } from '../helpers.js';

export function renderXcodeCloud() {
  return `
    <div class="card mb-24">
      <div class="card-header"><span class="card-title">CI/CD Products</span></div>
      <div class="table-wrapper" id="xcpTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>
    <div class="card">
      <div class="card-header">
        <span class="card-title">Workflows</span>
        <button class="btn btn-sm btn-primary" onclick="showToast('asc xcode-cloud builds start','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><polygon points="5 3 19 12 5 21 5 3"/></svg>Start Build</button>
      </div>
      <div class="table-wrapper" id="xcwTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>`;
}

export async function loadXcodeCloud() {
  const prodResult = await DataProvider.fetch('xcode-cloud products list');
  if (prodResult?.data) {
    document.getElementById('xcpTable').innerHTML = `<table><thead><tr><th>Product</th><th>Type</th><th>App ID</th><th style="text-align:right">Actions</th></tr></thead><tbody>${prodResult.data.map(p => `<tr>
      <td><span class="cell-primary">${escapeHTML(p.name)}</span></td>
      <td><span class="platform-badge">${p.productType}</span></td>
      <td><span class="cell-mono">${p.appId}</span></td>
      <td class="text-right">
        ${p.affordances?.listWorkflows ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(p.affordances.listWorkflows)}')">Workflows</button>` : ''}
      </td>
    </tr>`).join('')}</tbody></table>`;

    const firstPid = prodResult.data[0]?.id;
    if (firstPid) {
      const wfResult = await DataProvider.fetch(`xcode-cloud workflows list --product-id ${firstPid}`);
      if (wfResult?.data) {
        document.getElementById('xcwTable').innerHTML = `<table><thead><tr><th>Workflow</th><th>Enabled</th><th>Locked</th><th style="text-align:right">Actions</th></tr></thead><tbody>${wfResult.data.map(w => `<tr>
          <td><span class="cell-primary">${escapeHTML(w.name)}</span></td>
          <td>${w.isEnabled ? '<span class="status live">Active</span>' : '<span class="status draft">Disabled</span>'}</td>
          <td>${w.isLockedForEditing ? '<span class="status pending">Locked</span>' : '<span class="status draft">Unlocked</span>'}</td>
          <td class="text-right">
            ${w.affordances?.startBuild ? `<button class="btn btn-sm btn-primary" onclick="runAffordance('${escapeHTML(w.affordances.startBuild)}')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><polygon points="5 3 19 12 5 21 5 3"/></svg>Run</button>` : '<span style="color:var(--text-muted);font-size:11px">Disabled</span>'}
            ${w.affordances?.listBuildRuns ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(w.affordances.listBuildRuns)}')">Builds</button>` : ''}
          </td>
        </tr>`).join('')}</tbody></table>`;
      }
    }
  }
}
