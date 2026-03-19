// Presentation: Dashboard page
import { icon } from '../icons.js';
import { NAV } from '../nav-data.js';

export function renderDashboard() {
  const totalCmds = NAV.reduce((s, g) => s + g.items.reduce((s2, i) => s2 + (i.entry?.length || 0) + (i.workflow?.length || 0), 0), 0);
  const totalFeatures = NAV.reduce((s, g) => s + g.items.length, 0) - 1;
  const groups = NAV.filter(g => g.group !== 'Overview');

  return `
    <div class="grid-4" style="margin-bottom:32px">
      ${statCard('Total Features', totalFeatures, 'box', 'color-brand')}
      ${statCard('CLI Commands', totalCmds, 'zap', 'color-emerald')}
      ${statCard('Categories', groups.length, 'layers', 'color-violet')}
      ${statCard('Version', 'v0.1.53', 'tag', 'color-amber')}
    </div>

    <div class="grid-3" style="margin-bottom:32px">
      ${groups.map(g => `
        <div class="group-card">
          <div class="group-card-title">${g.group}</div>
          <div>
            ${g.items.map(item => `
              <button data-page="${item.id}" class="group-card-item dashboard-nav">
                <div style="display:flex;align-items:center;gap:10px">
                  ${icon(item.icon)}
                  <span class="label">${item.label}</span>
                </div>
                ${(item.entry || item.workflow) ? `<span class="count">${(item.entry?.length || 0) + (item.workflow?.length || 0)} cmds</span>` : ''}
              </button>
            `).join('')}
          </div>
        </div>
      `).join('')}
    </div>

    <div class="group-card">
      <div class="group-card-title">Quick Actions</div>
      <div class="grid-4">
        ${quickAction('List Apps', 'asc apps list', 'box')}
        ${quickAction('Check Auth', 'asc auth check', 'key')}
        ${quickAction('List Builds', 'asc builds list', 'package')}
        ${quickAction('Sales Report', 'asc sales-reports download', 'bar-chart')}
      </div>
    </div>
  `;
}

function statCard(label, value, iconName, colorClass) {
  return `
    <div class="stat-card" style="cursor:default">
      <div style="display:flex;align-items:center;gap:12px">
        <div class="stat-card-icon ${colorClass}">${icon(iconName)}</div>
        <div>
          <div class="stat-card-value">${value}</div>
          <div class="stat-card-label">${label}</div>
        </div>
      </div>
    </div>
  `;
}

function quickAction(label, cmd, iconName) {
  return `
    <button class="quick-action quick-cmd" data-cmd="${cmd}">
      ${icon(iconName)}
      <div>
        <div class="label">${label}</div>
        <div class="cmd">${cmd}</div>
      </div>
    </button>
  `;
}
