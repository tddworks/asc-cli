// Presentation: Shared helpers
export function escapeHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

export function stateColor(state) {
  const s = String(state).toLowerCase();
  if (['ready_for_sale','ready_for_distribution','live','active','enabled','complete','succeeded','valid'].some(x => s.includes(x))) return 'color: var(--success)';
  if (['in_review','processing','pending','waiting','running'].some(x => s.includes(x))) return 'color: var(--warning)';
  if (['rejected','failed','error','invalid','expired','revoked'].some(x => s.includes(x))) return 'color: var(--danger)';
  return 'color: var(--text-secondary)';
}

export function actionColor(action) {
  const colors = {
    list: 'color-emerald', get: 'color-emerald',
    create: 'color-brand', add: 'color-brand', invite: 'color-brand', register: 'color-brand', install: 'color-brand', use: 'color-brand', request: 'color-brand',
    update: 'color-amber', set: 'color-amber', check: 'color-amber', disable: 'color-amber', html: 'color-amber',
    delete: 'color-danger', remove: 'color-danger', revoke: 'color-danger', cancel: 'color-danger', logout: 'color-danger', uninstall: 'color-danger',
    upload: 'color-violet', submit: 'color-violet', archive: 'color-violet', run: 'color-violet', start: 'color-violet', generate: 'color-violet', uploads: 'color-violet',
    download: 'color-cyan', import: 'color-cyan', export: 'color-cyan', translate: 'color-cyan',
    login: 'color-emerald', enable: 'color-emerald', installed: 'color-emerald',
    config: 'color-default',
  };
  return colors[action] || 'color-default';
}

// CSS class mapping for action tags
const actionCSSMap = {
  'color-emerald': 'background: var(--success-dim); color: var(--success); border-color: var(--success-border);',
  'color-brand': 'background: var(--accent-dim); color: #60a5fa; border-color: var(--accent-border);',
  'color-amber': 'background: var(--warning-dim); color: var(--warning); border-color: var(--warning-border);',
  'color-danger': 'background: var(--danger-dim); color: var(--danger); border-color: var(--danger-border);',
  'color-violet': 'background: var(--violet-dim); color: var(--violet); border-color: var(--violet-border);',
  'color-cyan': 'background: var(--cyan-dim); color: var(--cyan); border-color: var(--cyan-border);',
  'color-default': 'background: rgba(100,116,139,0.08); color: var(--text-secondary); border-color: rgba(100,116,139,0.2);',
};

export function actionStyle(action) {
  return actionCSSMap[actionColor(action)] || actionCSSMap['color-default'];
}
