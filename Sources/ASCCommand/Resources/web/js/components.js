// Shared UI components

export function esc(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// ── State badges ──────────────────────────────────────
const STATE_MAP = {
  READY_FOR_SALE:              ['Live',              'bg-emerald-50 text-emerald-700 border-emerald-200'],
  PREPARE_FOR_SUBMISSION:      ['Prepare',           'bg-neutral-100 text-neutral-600 border-neutral-200'],
  WAITING_FOR_REVIEW:          ['Waiting for Review', 'bg-amber-50 text-amber-700 border-amber-200'],
  IN_REVIEW:                   ['In Review',          'bg-blue-50 text-blue-700 border-blue-200'],
  PENDING_DEVELOPER_RELEASE:   ['Pending Release',    'bg-violet-50 text-violet-700 border-violet-200'],
  READY_FOR_DISTRIBUTION:      ['Ready',              'bg-emerald-50 text-emerald-700 border-emerald-200'],
  DEVELOPER_REJECTED:          ['Dev Rejected',       'bg-red-50 text-red-700 border-red-200'],
  REJECTED:                    ['Rejected',           'bg-red-50 text-red-700 border-red-200'],
  PROCESSING_FOR_APP_STORE:    ['Processing',         'bg-amber-50 text-amber-700 border-amber-200'],
  DEVELOPER_REMOVED_FROM_SALE: ['Removed',            'bg-neutral-100 text-neutral-500 border-neutral-200'],
  REPLACED_WITH_NEW_VERSION:   ['Replaced',           'bg-neutral-100 text-neutral-400 border-neutral-200'],
  // Build states
  PROCESSING: ['Processing', 'bg-amber-50 text-amber-600 border-amber-200'],
  VALID:      ['Valid',       'bg-emerald-50 text-emerald-600 border-emerald-200'],
  INVALID:    ['Invalid',     'bg-red-50 text-red-600 border-red-200'],
  MISSING_EXPORT_COMPLIANCE: ['Compliance', 'bg-amber-50 text-amber-600 border-amber-200'],
  // Generic
  APPROVED:           ['Approved',   'bg-emerald-50 text-emerald-700 border-emerald-200'],
  READY_TO_SUBMIT:    ['Ready',      'bg-blue-50 text-blue-700 border-blue-200'],
  WAITING_FOR_UPLOAD: ['Awaiting',   'bg-neutral-100 text-neutral-500 border-neutral-200'],
};

export function badge(stateStr) {
  const [label, cls] = STATE_MAP[stateStr] || [stateStr, 'bg-neutral-100 text-neutral-500 border-neutral-200'];
  return `<span class="text-[0.65rem] font-medium px-2 py-0.5 rounded-full border whitespace-nowrap ${cls}">${label}</span>`;
}

// ── Time ──────────────────────────────────────────────
export function timeAgo(dateStr) {
  if (!dateStr) return '';
  const diff = Date.now() - new Date(dateStr).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 30) return `${d}d ago`;
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

// ── Affordance buttons ────────────────────────────────
export function affordanceButtons(affordances, opts = {}) {
  if (!affordances) return '';
  const exclude = new Set(opts.exclude || []);
  const entries = Object.entries(affordances).filter(([k]) => !exclude.has(k));
  if (!entries.length) return '';

  return `<div class="flex flex-wrap gap-1.5 ${opts.class || ''}">
    ${entries.map(([name, cmd]) =>
      `<button class="asc-action text-[0.65rem] font-medium text-neutral-500 bg-white border border-neutral-200 px-2.5 py-1 rounded-md cursor-pointer hover:bg-neutral-50 hover:border-neutral-300 transition-colors" data-cmd="${esc(cmd)}" data-label="${esc(name)}">${esc(name)}</button>`
    ).join('')}
  </div>`;
}

// Primary action button (blue, prominent)
export function primaryButton(label, cmd) {
  return `<button class="asc-action text-xs font-medium text-white bg-blue-600 hover:bg-blue-700 px-3.5 py-1.5 rounded-lg cursor-pointer transition-colors" data-cmd="${esc(cmd)}" data-label="${esc(label)}">${label}</button>`;
}

// Secondary action button (outlined)
export function secondaryButton(label, cmd) {
  return `<button class="asc-action text-xs font-medium text-neutral-600 bg-white border border-neutral-200 hover:bg-neutral-50 hover:border-neutral-300 px-3.5 py-1.5 rounded-lg cursor-pointer transition-colors" data-cmd="${esc(cmd)}" data-label="${esc(label)}">${label}</button>`;
}

// ── Page states ───────────────────────────────────────
export function loading(msg = 'Loading...') {
  return `<div class="flex items-center justify-center py-24 text-neutral-400 gap-2.5">
    <svg class="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" opacity="0.2"/><path d="M12 2a10 10 0 019.95 9" stroke="currentColor" stroke-width="3" stroke-linecap="round"/></svg>
    <span class="text-sm">${msg}</span>
  </div>`;
}

export function empty(title, sub) {
  return `<div class="flex flex-col items-center justify-center py-24 text-center">
    <div class="w-12 h-12 rounded-full bg-neutral-100 flex items-center justify-center mb-3">
      <svg class="w-5 h-5 text-neutral-300" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
    </div>
    <p class="text-sm font-medium text-neutral-600">${title}</p>
    <p class="text-xs text-neutral-400 mt-1 max-w-xs">${sub}</p>
  </div>`;
}

export function error(msg) {
  return `<div class="flex flex-col items-center justify-center py-24 text-center">
    <div class="w-12 h-12 rounded-full bg-red-50 flex items-center justify-center mb-3">
      <svg class="w-5 h-5 text-red-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
    </div>
    <p class="text-sm font-medium text-neutral-700">Something went wrong</p>
    <p class="text-xs text-red-500 mt-1.5 max-w-md font-mono">${esc(msg)}</p>
    <p class="text-xs text-neutral-400 mt-3">Make sure the server is running: <code class="font-mono bg-neutral-100 px-1.5 py-0.5 rounded text-neutral-600">python3 apps/asc-web/server.py</code></p>
  </div>`;
}

// ── Toast notifications ───────────────────────────────
let toastContainer = null;

function ensureToastContainer() {
  if (toastContainer) return;
  toastContainer = document.createElement('div');
  toastContainer.className = 'fixed top-4 right-4 z-[100] space-y-2 pointer-events-none';
  document.body.appendChild(toastContainer);
}

export function toast(message, type = 'info') {
  ensureToastContainer();

  const colors = {
    info:    'bg-white text-neutral-700 border-neutral-200',
    success: 'bg-emerald-50 text-emerald-800 border-emerald-200',
    error:   'bg-red-50 text-red-800 border-red-200',
    loading: 'bg-white text-neutral-500 border-neutral-200',
  };

  const icons = {
    info: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>',
    success: '<path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>',
    error: '<circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>',
    loading: '<circle cx="12" cy="12" r="10" opacity="0.2"/><path d="M12 2a10 10 0 019.95 9" stroke-linecap="round"/>',
  };

  const el = document.createElement('div');
  el.className = `pointer-events-auto flex items-center gap-2 px-4 py-2.5 rounded-xl border shadow-sm text-xs font-medium ${colors[type]} transform transition-all duration-200 translate-x-2 opacity-0`;
  el.innerHTML = `
    <svg class="w-3.5 h-3.5 shrink-0 ${type === 'loading' ? 'animate-spin' : ''}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">${icons[type]}</svg>
    <span>${esc(message)}</span>
  `;
  toastContainer.appendChild(el);

  requestAnimationFrame(() => { el.classList.remove('translate-x-2', 'opacity-0'); });

  if (type !== 'loading') {
    setTimeout(() => {
      el.classList.add('translate-x-2', 'opacity-0');
      setTimeout(() => el.remove(), 200);
    }, type === 'error' ? 5000 : 3000);
  }

  return el; // return ref so loading toasts can be removed
}

// ── Action handler ────────────────────────────────────
// Executes an asc command, shows toast, refreshes page
export function setupActionHandler(refreshFn) {
  document.addEventListener('click', async (e) => {
    const btn = e.target.closest('.asc-action');
    if (!btn) return;

    const cmd = btn.dataset.cmd;
    const label = btn.dataset.label || 'Command';
    if (!cmd) return;

    // Disable button
    btn.disabled = true;
    btn.style.opacity = '0.5';
    btn.style.pointerEvents = 'none';

    const loadingToast = toast(`Running ${label}...`, 'loading');

    try {
      const { asc } = await import('./api.js');
      const result = await asc(cmd);
      loadingToast.remove();
      toast(`${label} completed`, 'success');

      // Refresh current page
      if (refreshFn) refreshFn();
    } catch (err) {
      loadingToast.remove();
      toast(err.message, 'error');
    } finally {
      btn.disabled = false;
      btn.style.opacity = '';
      btn.style.pointerEvents = '';
    }
  });
}

// ── Table helper ──────────────────────────────────────
export function table(headers, rows) {
  return `<div class="bg-white border border-neutral-200 rounded-xl overflow-hidden">
    <table class="w-full">
      <thead><tr class="border-b border-neutral-100">
        ${headers.map(h => `<th class="text-left text-[0.65rem] font-medium text-neutral-400 uppercase tracking-wider px-5 py-2.5 ${h.align === 'right' ? 'text-right' : ''}">${h.label || h}</th>`).join('')}
      </tr></thead>
      <tbody>${rows}</tbody>
    </table>
  </div>`;
}
