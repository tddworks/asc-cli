// Presentation: Feature page — guides users through the CAEOAS journey
import { escapeHtml, actionStyle } from '../helpers.js';

export function renderFeaturePage(data) {
  const entry = data.entry || [];
  const workflow = data.workflow || [];
  const flow = data.flow || [];
  const totalCmds = entry.length + workflow.length;

  if (!totalCmds) return '<p style="color: var(--text-dim)">No commands available.</p>';

  // If no direct entry points, the flow's first step IS the entry point
  const hasDirectEntry = entry.length > 0;
  const flowEntry = !hasDirectEntry && flow.length > 0 ? flow[0] : null;

  return `
    ${flow.length ? renderFlow(flow, flowEntry) : ''}
    ${hasDirectEntry ? renderEntrySection(entry) : ''}
    ${!hasDirectEntry && flowEntry ? renderFlowEntrySection(flowEntry) : ''}
    ${workflow.length ? renderWorkflowSection(workflow) : ''}
  `;
}

function renderFlow(steps, activeStep) {
  return `
    <div class="cmd-group" style="margin-bottom:24px">
      <div class="cmd-group-header">
        <svg style="width:14px;height:14px;color:var(--text-dim)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
        <span style="font-size:12px;font-weight:500;color:var(--text-secondary)">Typical workflow</span>
      </div>
      <div style="padding:16px 20px;display:flex;flex-wrap:wrap;align-items:center;gap:8px">
        ${steps.map((step, i) => {
          const parts = step.split(' ');
          const cmd = parts[0];
          const rest = parts.slice(1).join(' ');
          const isEntry = step === activeStep;
          const borderColor = isEntry ? 'var(--success-border)' : 'var(--border)';
          const bgColor = isEntry ? 'rgba(5,150,105,0.08)' : 'rgba(15,23,42,0.8)';
          return `
            ${i > 0 ? '<svg style="width:16px;height:16px;color:var(--text-dim);flex-shrink:0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14"/><path d="M12 5l7 7-7 7"/></svg>' : ''}
            <code style="font-size:11px;font-family:var(--font-mono);padding:4px 8px;border-radius:6px;background:${bgColor};border:1px solid ${borderColor};color:var(--text-secondary);white-space:nowrap">
              <span style="color:#60a5fa">asc</span> ${escapeHtml(cmd)} <span style="color:var(--text-dim)">${escapeHtml(rest)}</span>
            </code>
          `;
        }).join('')}
      </div>
      <div style="padding:0 20px 12px;font-size:11px;color:var(--text-dim)">
        Each command returns affordances with the next available actions and pre-filled IDs.
      </div>
    </div>
  `;
}

function renderEntrySection(cmds) {
  return `
    <div class="cmd-group" style="margin-bottom:24px">
      <div class="cmd-group-header">
        <svg style="width:14px;height:14px;color:var(--success)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"/></svg>
        <span style="font-size:12px;font-weight:500;color:var(--text-secondary)">Start here</span>
        <span style="font-size:10px;color:var(--text-dim)">Run these to begin exploring</span>
      </div>
      ${cmds.map(cmd => renderRunnable(cmd)).join('')}
    </div>
  `;
}

function renderFlowEntrySection(flowFirstStep) {
  return `
    <div class="cmd-group" style="margin-bottom:24px">
      <div class="cmd-group-header">
        <svg style="width:14px;height:14px;color:var(--success)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="5 3 19 12 5 21 5 3"/></svg>
        <span style="font-size:12px;font-weight:500;color:var(--text-secondary)">Start here</span>
        <span style="font-size:10px;color:var(--text-dim)">Run this first, then follow the affordances</span>
      </div>
      ${renderRunnable(flowFirstStep)}
    </div>
  `;
}

function renderRunnable(cmd) {
  const parts = cmd.split(' ');
  const action = parts[parts.length - 1];
  return `
    <div class="cmd-row">
      <div style="display:flex;align-items:center;gap:12px">
        <span class="cmd-tag" style="${actionStyle(action)}">${escapeHtml(action)}</span>
        <code style="font-size:14px;font-family:var(--font-mono);color:var(--text-secondary)">asc ${escapeHtml(cmd)}</code>
      </div>
      <div style="display:flex;align-items:center;gap:8px">
        <button class="icon-btn copy-cmd" data-cmd="asc ${escapeHtml(cmd)}" title="Copy command">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>
        </button>
        <button class="icon-btn run-cmd" data-cmd="asc ${escapeHtml(cmd)}" title="Run in terminal" style="color:var(--success)">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg>
        </button>
      </div>
    </div>
  `;
}

function renderWorkflowSection(cmds) {
  const groups = {};
  cmds.forEach(cmd => {
    const parts = cmd.split(' ');
    const prefix = parts.length > 1 ? parts.slice(0, -1).join(' ') : cmd;
    if (!groups[prefix]) groups[prefix] = [];
    groups[prefix].push({ full: cmd, action: parts[parts.length - 1] });
  });

  return `
    <div class="cmd-group">
      <div class="cmd-group-header">
        <svg style="width:14px;height:14px;color:var(--text-dim)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
        <span style="font-size:12px;font-weight:500;color:var(--text-secondary)">Available via affordances</span>
        <span style="font-size:10px;color:var(--text-dim)">These appear in CLI output with pre-filled IDs</span>
      </div>
      ${Object.entries(groups).map(([prefix, items]) =>
        items.map(cmd => `
          <div class="cmd-row" style="opacity:0.7">
            <div style="display:flex;align-items:center;gap:12px">
              <span class="cmd-tag" style="${actionStyle(cmd.action)}">${escapeHtml(cmd.action)}</span>
              <code style="font-size:14px;font-family:var(--font-mono);color:var(--text-secondary)">asc ${escapeHtml(cmd.full)}</code>
            </div>
            <button class="icon-btn copy-cmd" data-cmd="asc ${escapeHtml(cmd.full)}" title="Copy command">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>
            </button>
          </div>
        `).join('')
      ).join('')}
    </div>
  `;
}
