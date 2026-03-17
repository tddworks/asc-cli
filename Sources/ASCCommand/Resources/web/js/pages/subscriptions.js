import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, affordanceButtons, empty, primaryButton } from '../components.js';

export async function render() {
  if (!state.appId) return empty('No app connected', 'Connect an app to manage subscriptions.');

  const groups = toList(await asc(`subscription-groups list --app-id ${state.appId} --output json`));

  let html = `<div class="flex items-center justify-between mb-6">
    <h1 class="text-lg font-semibold text-neutral-900">Subscriptions</h1>
    ${primaryButton('+ New Group', `asc subscription-groups create --app-id ${state.appId} --reference-name `)}
  </div>`;

  if (!groups.length) return html + empty('No subscription groups', 'Create a subscription group to add subscription products.');

  html += groups.map(g => `
    <div class="bg-white border border-neutral-200 rounded-xl mb-4 overflow-hidden hover:shadow-sm transition-shadow">
      <div class="px-5 py-3.5 flex items-center justify-between">
        <div>
          <h3 class="text-sm font-semibold text-neutral-800">${esc(g.referenceName || g.name || g.id)}</h3>
          <p class="text-[0.6rem] font-mono text-neutral-400 mt-0.5">${esc(g.id)}</p>
        </div>
      </div>
      ${g.affordances ? `<div class="px-5 py-3 border-t border-neutral-100">${affordanceButtons(g.affordances)}</div>` : ''}
    </div>
  `).join('');

  return html;
}
