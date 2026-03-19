// Page: Dashboard
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { statusBadge, formatDate } from '../helpers.js';

export function renderDashboard() {
  return `
    <div class="dashboard-stats">
      <div class="stat-card">
        <div class="stat-header">
          <div class="stat-icon blue"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="4" width="16" height="16" rx="2"/><path d="M9 9h6v6H9z"/></svg></div>
          <span class="stat-change up" id="statAppsChange">--</span>
        </div>
        <div class="stat-value" id="statApps">--</div>
        <div class="stat-label">Total Apps</div>
      </div>
      <div class="stat-card">
        <div class="stat-header">
          <div class="stat-icon green"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="M22 4L12 14.01l-3-3"/></svg></div>
          <span class="stat-change up" id="statLiveChange">Live</span>
        </div>
        <div class="stat-value" id="statLive">--</div>
        <div class="stat-label">Live on Store</div>
      </div>
      <div class="stat-card">
        <div class="stat-header">
          <div class="stat-icon purple"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/></svg></div>
        </div>
        <div class="stat-value" id="statBuilds">--</div>
        <div class="stat-label">Recent Builds</div>
      </div>
      <div class="stat-card">
        <div class="stat-header">
          <div class="stat-icon orange"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20V10"/><path d="M18 20V4"/><path d="M6 20v-4"/></svg></div>
        </div>
        <div class="stat-value" id="statPending">--</div>
        <div class="stat-label">Pending Review</div>
      </div>
    </div>

    <div class="grid-2 mb-24">
      <div class="card">
        <div class="card-header">
          <span class="card-title">Recent Activity</span>
          <button class="btn btn-sm btn-secondary" onclick="navigate('builds')">View All</button>
        </div>
        <div class="card-body" id="recentActivity">
          <div class="empty-state"><div class="spinner" style="margin: 24px auto"></div></div>
        </div>
      </div>

      <div class="card">
        <div class="card-header">
          <span class="card-title">Release Pipeline</span>
        </div>
        <div class="card-body padded">
          <div class="timeline" id="releasePipeline">
            <div class="timeline-item done">
              <div class="timeline-dot"></div>
              <div class="timeline-title">Build Uploaded</div>
              <div class="timeline-desc">v2.2.0 (142) processed successfully</div>
              <div class="timeline-time">Mar 16, 2026 08:30</div>
            </div>
            <div class="timeline-item done">
              <div class="timeline-dot"></div>
              <div class="timeline-title">Metadata Updated</div>
              <div class="timeline-desc">What's New, screenshots refreshed</div>
              <div class="timeline-time">Mar 16, 2026 09:15</div>
            </div>
            <div class="timeline-item active">
              <div class="timeline-dot"></div>
              <div class="timeline-title">Build Linked to Version</div>
              <div class="timeline-desc">Awaiting: set build & submit for review</div>
            </div>
            <div class="timeline-item">
              <div class="timeline-dot"></div>
              <div class="timeline-title">Submit for Review</div>
              <div class="timeline-desc">Ready when build is linked</div>
            </div>
            <div class="timeline-item">
              <div class="timeline-dot"></div>
              <div class="timeline-title">App Store Release</div>
              <div class="timeline-desc">Publish after approval</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <span class="card-title">Quick Actions</span>
      </div>
      <div class="card-body padded">
        <div style="display:flex;gap:10px;flex-wrap:wrap">
          <button class="btn btn-primary" onclick="navigate('apps')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><rect x="4" y="4" width="16" height="16" rx="2"/><path d="M9 9h6v6H9z"/></svg>Browse Apps</button>
          <button class="btn btn-secondary" onclick="openModal('createVersionModal')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>New Version</button>
          <button class="btn btn-secondary" onclick="navigate('builds')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>Upload Build</button>
          <button class="btn btn-secondary" onclick="navigate('testflight')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><path d="M17.8 19.2L16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/></svg>TestFlight</button>
          <button class="btn btn-success" onclick="navigate('submissions')"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="M22 4L12 14.01l-3-3"/></svg>Submit for Review</button>
        </div>
      </div>
    </div>`;
}

export async function loadDashboard() {
  const result = await DataProvider.fetch('apps list');
  if (result?.data) {
    state.apps = result.data;
    const allVersions = [];
    for (const app of result.data) {
      const vr = await DataProvider.fetch(`versions list --app-id ${app.id}`);
      if (vr?.data) allVersions.push(...vr.data);
    }
    const live = allVersions.filter(v => v.isLive).length;
    const pending = allVersions.filter(v => v.isPending).length;
    document.getElementById('statApps').textContent = result.data.length;
    document.getElementById('statLive').textContent = live;
    document.getElementById('statPending').textContent = pending;
    document.getElementById('statAppsChange').textContent = `${result.data.length} total`;
  }
  const appId = state.apps[0]?.id || '6449071230';
  const br = await DataProvider.fetch(`builds list --app-id ${appId}`);
  if (br?.data) {
    document.getElementById('statBuilds').textContent = br.data.length;
    document.getElementById('recentActivity').innerHTML = `<table><thead><tr><th>Build</th><th>Version</th><th>Usable</th><th>Status</th><th>Uploaded</th></tr></thead><tbody>${br.data.slice(0, 5).map(b => `<tr>
      <td><span class="cell-primary">#${b.buildNumber}</span></td>
      <td>${b.version}</td>
      <td>${b.isUsable ? '<span class="status live">Yes</span>' : '<span class="status draft">No</span>'}</td>
      <td>${statusBadge(b.processingState)}</td>
      <td>${formatDate(b.uploadedDate)}</td>
    </tr>`).join('')}</tbody></table>`;
  }
}
