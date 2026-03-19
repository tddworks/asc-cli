// Presentation: Feature page — renders command groups for a nav item
import { escapeHtml, actionStyle } from '../helpers.js';

export function renderFeaturePage(data) {
  if (!data.cmds) return '<p style="color: var(--text-dim)">No commands available.</p>';

  const groups = {};
  data.cmds.forEach(cmd => {
    const parts = cmd.split(' ');
    const prefix = parts.length > 1 ? parts.slice(0, -1).join(' ') : cmd;
    if (!groups[prefix]) groups[prefix] = [];
    groups[prefix].push({ full: cmd, action: parts[parts.length - 1] });
  });

  return `
    <div style="display:flex;flex-direction:column;gap:24px">
      ${Object.entries(groups).map(([prefix, cmds]) => `
        <div class="cmd-group">
          <div class="cmd-group-header">
            <code>asc ${escapeHtml(prefix)}</code>
            <span class="count">${cmds.length} action${cmds.length > 1 ? 's' : ''}</span>
          </div>
          ${cmds.map(cmd => `
            <div class="cmd-row">
              <div style="display:flex;align-items:center;gap:12px">
                <span class="cmd-tag" style="${actionStyle(cmd.action)}">${escapeHtml(cmd.action)}</span>
                <code style="font-size:14px;font-family:var(--font-mono);color:var(--text-secondary)">asc ${escapeHtml(cmd.full)}</code>
              </div>
              <div style="display:flex;align-items:center;gap:8px">
                <button class="icon-btn copy-cmd" data-cmd="asc ${escapeHtml(cmd.full)}" title="Copy command">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>
                </button>
                <button class="icon-btn run-cmd" data-cmd="asc ${escapeHtml(cmd.full)}" title="Run in terminal">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>
                </button>
              </div>
            </div>
          `).join('')}
        </div>
      `).join('')}
    </div>

    <div class="group-card" style="margin-top:24px">
      <div class="group-card-title">Usage Example</div>
      <div class="usage-block">
        <span style="color:var(--text-dim)">$</span> <span style="color:#60a5fa">asc</span> ${escapeHtml(data.cmds[0])} <span style="color:var(--text-dim)">--output json --pretty</span>
      </div>
    </div>
  `;
}
