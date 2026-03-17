import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, badge, affordanceButtons, primaryButton, secondaryButton, empty } from '../components.js';

export async function render() {
  if (!state.appId) return empty('No app connected', 'Run asc auth login to connect your account.');

  const versions = toList(await asc(`versions list --app-id ${state.appId} --output json`));
  if (!versions.length) return empty('No versions', 'Create your first version to start the release process.');

  const active = versions.filter(v => ['PREPARE_FOR_SUBMISSION', 'WAITING_FOR_REVIEW', 'IN_REVIEW', 'PENDING_DEVELOPER_RELEASE', 'PROCESSING_FOR_APP_STORE'].includes(v.state));
  const live = versions.filter(v => v.state === 'READY_FOR_SALE');
  const past = versions.filter(v => ['REPLACED_WITH_NEW_VERSION', 'DEVELOPER_REMOVED_FROM_SALE', 'DEVELOPER_REJECTED', 'REJECTED'].includes(v.state));

  let html = `<div class="flex items-center justify-between mb-6">
    <h1 class="text-lg font-semibold text-neutral-900">Releases</h1>
    ${primaryButton('+ New Version', `asc versions create --app-id ${state.appId} --platform ${state.platform} --version-string `)}
  </div>`;

  if (active.length) {
    html += active.map(v => versionCard(v, true)).join('');
  }

  if (live.length) {
    html += `<div class="mt-8 mb-3"><span class="text-[0.65rem] font-semibold text-neutral-400 uppercase tracking-wider">Live</span></div>`;
    html += live.map(v => versionCard(v, false)).join('');
  }

  if (past.length) {
    html += `<div class="mt-8 mb-3"><span class="text-[0.65rem] font-semibold text-neutral-400 uppercase tracking-wider">Completed</span></div>`;
    html += past.slice(0, 5).map(v => versionCard(v, false)).join('');
  }

  return html;
}

function versionCard(v, expanded) {
  const a = v.affordances || {};

  return `
    <div class="bg-white border border-neutral-200 rounded-xl mb-3 overflow-hidden hover:shadow-sm transition-shadow">
      <div class="flex items-center justify-between px-5 py-3.5">
        <div class="flex items-center gap-3">
          <span class="text-base font-semibold text-neutral-900 tabular-nums">${esc(v.versionString || v.version || '?')}</span>
          ${badge(v.state)}
          ${v.platform ? `<span class="text-[0.6rem] font-mono text-neutral-400">${esc(v.platform)}</span>` : ''}
        </div>
        <div class="flex items-center gap-2">
          ${a.submitForReview ? primaryButton('Submit for Review', a.submitForReview) : ''}
          ${a.checkReadiness ? secondaryButton('Check Readiness', a.checkReadiness) : ''}
        </div>
      </div>

      ${expanded ? `
      <div class="border-t border-neutral-100 px-5 py-3.5">
        <div class="grid grid-cols-3 gap-4">
          <div class="bg-neutral-50 rounded-lg px-3.5 py-2.5">
            <p class="text-[0.6rem] text-neutral-400 uppercase tracking-wider mb-1">Build</p>
            <p class="text-sm font-medium text-neutral-800">${v.buildId ? `#${esc(v.buildId).slice(-6)}` : '<span class="text-neutral-400">No build attached</span>'}</p>
          </div>
          <div class="bg-neutral-50 rounded-lg px-3.5 py-2.5">
            <p class="text-[0.6rem] text-neutral-400 uppercase tracking-wider mb-1">Version ID</p>
            <p class="text-xs font-mono text-neutral-500 truncate" title="${esc(v.id)}">${esc(v.id)}</p>
          </div>
          <div class="bg-neutral-50 rounded-lg px-3.5 py-2.5">
            <p class="text-[0.6rem] text-neutral-400 uppercase tracking-wider mb-1">App ID</p>
            <p class="text-xs font-mono text-neutral-500 truncate">${esc(v.appId)}</p>
          </div>
        </div>
        ${affordanceButtons(a, { exclude: ['submitForReview', 'checkReadiness'], class: 'mt-3 pt-3 border-t border-neutral-100' })}
      </div>` : ''}
    </div>`;
}
