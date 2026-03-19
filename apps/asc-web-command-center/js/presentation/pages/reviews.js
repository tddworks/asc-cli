// Page: Customer Reviews
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { escapeHTML, formatDate } from '../helpers.js';

export function renderReviews() {
  return `
    <div class="card">
      <div class="toolbar">
        <div class="toolbar-left">
          <div class="filter-group">
            <button class="filter-btn active">All</button>
            <button class="filter-btn">5 Stars</button>
            <button class="filter-btn">Needs Reply</button>
          </div>
        </div>
      </div>
      <div class="card-body" id="reviewsList">
        <div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div>
      </div>
    </div>`;
}

export async function loadReviews() {
  const appId = state.selectedApp?.id || '6449071230';
  const result = await DataProvider.fetch(`reviews list --app-id ${appId}`);
  if (result?.data) {
    document.getElementById('reviewsList').innerHTML = result.data.map(r => `
      <div style="padding:16px 20px;border-bottom:1px solid var(--border-light)">
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px">
          <span style="font-weight:600;font-size:13px">${escapeHTML(r.title)}</span>
          <span style="color:#F59E0B;font-size:12px">${'★'.repeat(r.rating)}${'☆'.repeat(5 - r.rating)}</span>
          ${r.territory ? `<span class="platform-badge">${r.territory}</span>` : ''}
          <span style="margin-left:auto;font-size:11px;color:var(--text-muted)">${formatDate(r.createdDate)}</span>
        </div>
        <p style="font-size:13px;color:var(--text-secondary);margin-bottom:8px">${escapeHTML(r.body)}</p>
        <div style="display:flex;align-items:center;gap:8px">
          <span style="font-size:11px;color:var(--text-muted)">by ${escapeHTML(r.reviewerNickname)}</span>
          <div style="margin-left:auto;display:flex;gap:6px">
            ${r.affordances?.respond ? `<button class="btn btn-sm btn-primary" onclick="runAffordance('${escapeHTML(r.affordances.respond)}')">Reply</button>` : ''}
            ${r.affordances?.getResponse ? `<button class="btn btn-sm btn-secondary" onclick="runAffordance('${escapeHTML(r.affordances.getResponse)}')">View Response</button>` : ''}
          </div>
        </div>
      </div>`).join('');
  }
}
