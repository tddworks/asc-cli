// Page: Users & Roles
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { showToast } from '../toast.js';
import { escapeHTML } from '../helpers.js';

export function renderUsers() {
  return `
    <div class="card">
      <div class="toolbar">
        <div class="toolbar-left">
          <div class="filter-group">
            <button class="filter-btn active">All</button>
            <button class="filter-btn">Admin</button>
            <button class="filter-btn">Developer</button>
          </div>
        </div>
        <div class="toolbar-right">
          <button class="btn btn-sm btn-primary" onclick="showToast('asc user-invitations invite','info')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/></svg>Invite</button>
        </div>
      </div>
      <div class="table-wrapper" id="usersTable">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>`;
}

export async function loadUsers() {
  const result = await DataProvider.fetch('users list');
  if (result?.data) {
    document.getElementById('usersTable').innerHTML = `<table><thead><tr><th>Name</th><th>Email</th><th>Roles</th><th>All Apps</th><th>Provisioning</th><th style="text-align:right">Actions</th></tr></thead><tbody>${result.data.map(u => `<tr>
      <td><span class="cell-primary">${escapeHTML(u.firstName)} ${escapeHTML(u.lastName)}</span></td>
      <td>${escapeHTML(u.username)}</td>
      <td>${u.roles.map(r => `<span class="platform-badge">${r}</span>`).join(' ')}</td>
      <td>${u.isAllAppsVisible ? '<span class="status live">Yes</span>' : '<span class="status draft">No</span>'}</td>
      <td>${u.isProvisioningAllowed ? '<span class="status live">Yes</span>' : '<span class="status draft">No</span>'}</td>
      <td class="text-right">
        ${u.affordances?.updateRoles ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(u.affordances.updateRoles)}')">Edit</button>` : ''}
        ${u.affordances?.remove ? `<button class="btn btn-sm btn-danger" onclick="runAffordance('${escapeHTML(u.affordances.remove)}')">Remove</button>` : ''}
      </td>
    </tr>`).join('')}</tbody></table>`;
  }
}
