// Presentation: Search overlay (Cmd+K or / to open)
// Searches both features (pages) and CLI commands with keyboard navigation
import { icon } from './icons.js';
import { escapeHtml, actionStyle } from './helpers.js';
import { NAV, getAllCommands } from './nav-data.js';
import { toggleTerminal, executeCommand } from './terminal.js';
import { navigate } from './navigation.js';

let paletteOpen = false;
let activeIndex = 0;
let flatResults = [];

// Build search index: features + individual commands
function buildSearchIndex() {
  const index = [];
  NAV.forEach(section => {
    section.items.forEach(item => {
      if (item.id === 'dashboard') return;
      // Feature entry
      const allCmds = [...(item.entry || []), ...(item.workflow || [])];
      index.push({ type: 'page', id: item.id, label: item.label, group: section.group, icon: item.icon, cmdCount: allCmds.length });
      // Individual commands
      allCmds.forEach(cmd => {
        const parts = cmd.split(' ');
        const action = parts[parts.length - 1];
        index.push({ type: 'cmd', cmd: `asc ${cmd}`, action, label: cmd, pageId: item.id, pageLabel: item.label, group: section.group, icon: item.icon });
      });
    });
  });
  return index;
}
const SEARCH_INDEX = buildSearchIndex();

export function initPalette() {
  const input = document.getElementById('palette-input');
  const results = document.getElementById('palette-results');
  const backdrop = document.getElementById('cmd-backdrop');

  input.addEventListener('input', () => {
    activeIndex = 0;
    renderResults(input.value);
  });

  input.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      activeIndex = Math.min(activeIndex + 1, flatResults.length - 1);
      renderResults(input.value);
      scrollActiveIntoView();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      activeIndex = Math.max(activeIndex - 1, 0);
      renderResults(input.value);
      scrollActiveIntoView();
    } else if (e.key === 'Enter') {
      e.preventDefault();
      selectResult(activeIndex);
    } else if (e.key === 'Tab') {
      e.preventDefault();
      // Tab switches between features and commands mode
      const result = flatResults[activeIndex];
      if (result && result.type === 'page') {
        // Fill search with feature label to show its commands
        input.value = result.label.toLowerCase();
        activeIndex = 0;
        renderResults(input.value);
      }
    }
  });

  backdrop.addEventListener('click', () => toggle(false));
}

export function toggle(show) {
  const modal = document.getElementById('cmd-modal');
  const input = document.getElementById('palette-input');
  const shouldShow = show !== undefined ? show : !paletteOpen;
  paletteOpen = shouldShow;
  if (shouldShow) {
    modal.classList.add('open');
    input.value = '';
    activeIndex = 0;
    renderResults('');
    setTimeout(() => input.focus(), 10);
  } else {
    modal.classList.remove('open');
  }
}

export function isPaletteOpen() { return paletteOpen; }

function selectResult(idx) {
  const result = flatResults[idx];
  if (!result) return;
  toggle(false);
  if (result.type === 'page') {
    navigate(result.id);
  } else if (result.type === 'cmd') {
    navigate(result.pageId);
    toggleTerminal(true);
    setTimeout(() => executeCommand(result.cmd), 350);
  }
}

function scrollActiveIntoView() {
  const container = document.getElementById('palette-results');
  const active = container.querySelector('.palette-item.active');
  if (active) active.scrollIntoView({ block: 'nearest' });
}

function highlightMatch(text, query) {
  if (!query) return escapeHtml(text);
  const escaped = escapeHtml(text);
  const qEsc = escapeHtml(query).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return escaped.replace(new RegExp(`(${qEsc})`, 'gi'), '<span style="color:#60a5fa;font-weight:600">$1</span>');
}

function renderResults(rawQuery) {
  const container = document.getElementById('palette-results');
  const q = rawQuery.toLowerCase().trim();

  let results;
  if (!q) {
    // Show all features when empty
    results = SEARCH_INDEX.filter(r => r.type === 'page');
  } else {
    results = SEARCH_INDEX.filter(r => {
      if (r.type === 'page') return r.label.toLowerCase().includes(q) || r.group.toLowerCase().includes(q);
      if (r.type === 'cmd') return r.label.toLowerCase().includes(q) || r.pageLabel.toLowerCase().includes(q);
      return false;
    }).slice(0, 25);
  }

  flatResults = results;
  if (activeIndex >= results.length) activeIndex = Math.max(0, results.length - 1);

  if (results.length === 0) {
    container.innerHTML = `<div style="padding:24px;text-align:center;font-size:12px;color:var(--text-dim)">No results for "${escapeHtml(rawQuery)}"</div>`;
    return;
  }

  const pages = results.filter(r => r.type === 'page');
  const cmds = results.filter(r => r.type === 'cmd');
  let html = '';
  let idx = 0;

  if (pages.length > 0) {
    html += `<div style="padding:6px 16px;font-size:10px;color:var(--text-dim);text-transform:uppercase;letter-spacing:0.06em;font-weight:600">${q ? 'Features' : 'All Features'}</div>`;
    pages.forEach(r => {
      const active = idx === activeIndex ? ' active' : '';
      html += `<button class="palette-item${active}" data-idx="${idx}" data-type="page" data-page="${r.id}">
        <div style="display:flex;align-items:center;gap:10px;min-width:0">
          <span class="palette-icon">${icon(r.icon)}</span>
          <div style="min-width:0">
            <div class="palette-label" style="font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${highlightMatch(r.label, q)}</div>
            <div style="font-size:10px;color:var(--text-dim)">${r.group}${r.cmdCount ? ` · ${r.cmdCount} commands` : ''}</div>
          </div>
        </div>
        <svg class="palette-chevron" style="width:12px;height:12px;flex-shrink:0" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
      </button>`;
      idx++;
    });
  }

  if (cmds.length > 0) {
    html += `<div style="padding:6px 16px;font-size:10px;color:var(--text-dim);text-transform:uppercase;letter-spacing:0.06em;font-weight:600;margin-top:4px">Commands</div>`;
    cmds.forEach(r => {
      const active = idx === activeIndex ? ' active' : '';
      html += `<button class="palette-item${active}" data-idx="${idx}" data-type="cmd" data-cmd="${escapeHtml(r.cmd)}" data-page="${r.pageId}">
        <div style="display:flex;align-items:center;gap:10px;min-width:0">
          <span class="palette-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/></svg></span>
          <div style="min-width:0">
            <code class="palette-label" style="font-size:12px;font-family:var(--font-mono)">${highlightMatch(r.cmd, q)}</code>
            <div style="font-size:10px;color:var(--text-dim)">${r.pageLabel}</div>
          </div>
        </div>
        <span class="cmd-tag" style="${actionStyle(r.action)}">${r.action}</span>
      </button>`;
      idx++;
    });
  }

  container.innerHTML = html;

  // Click handler
  container.querySelectorAll('.palette-item').forEach(el => {
    el.addEventListener('click', () => selectResult(parseInt(el.dataset.idx)));
  });
}
