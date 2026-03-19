// Presentation: Command palette (Cmd+K quick search)
import { icon } from './icons.js';
import { escapeHtml } from './helpers.js';
import { getAllCommands } from './nav-data.js';
import { toggleTerminal, executeCommand } from './terminal.js';

let paletteOpen = false;

export function initPalette() {
  const modal = document.getElementById('cmd-modal');
  const input = document.getElementById('palette-input');
  const results = document.getElementById('palette-results');
  const backdrop = document.getElementById('cmd-backdrop');

  input.addEventListener('input', () => renderResults(input, results));

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      const first = results.querySelector('.palette-item');
      if (first) {
        const cmd = first.dataset.cmd;
        toggle(false);
        toggleTerminal(true);
        setTimeout(() => executeCommand(cmd), 350);
      }
    }
  });

  backdrop.addEventListener('click', () => toggle(false));
}

export function toggle(show) {
  const modal = document.getElementById('cmd-modal');
  const input = document.getElementById('palette-input');
  const results = document.getElementById('palette-results');
  const shouldShow = show !== undefined ? show : !paletteOpen;
  paletteOpen = shouldShow;
  if (shouldShow) {
    modal.classList.add('open');
    input.value = '';
    renderResults(input, results);
    input.focus();
  } else {
    modal.classList.remove('open');
  }
}

export function isPaletteOpen() { return paletteOpen; }

function renderResults(input, container) {
  const all = getAllCommands();
  const q = input.value.toLowerCase();
  const filtered = q ? all.filter(c => c.cmd.includes(q) || c.label.toLowerCase().includes(q)) : all;
  const shown = filtered.slice(0, 15);

  container.innerHTML = shown.length ? shown.map((c, i) => `
    <button class="palette-item${i === 0 ? ' active' : ''}" data-cmd="${escapeHtml(c.cmd)}">
      <div style="display:flex;align-items:center;gap:10px">
        ${icon(c.icon)}
        <code style="font-size:12px;color:var(--text-secondary);font-family:var(--font-mono)">${escapeHtml(c.cmd)}</code>
      </div>
      <span style="font-size:10px;color:var(--text-dim)">${escapeHtml(c.label)}</span>
    </button>
  `).join('') : '<div style="padding:24px;text-align:center;font-size:14px;color:var(--text-dim)">No matching commands</div>';
}
