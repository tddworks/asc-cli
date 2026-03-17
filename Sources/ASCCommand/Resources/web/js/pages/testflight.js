import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, affordanceButtons, empty } from '../components.js';

export async function render() {
  if (!state.appId) return empty('No app connected', 'Connect an app to manage TestFlight.');

  const groups = toList(await asc(`testflight groups list --app-id ${state.appId} --output json`));
  if (!groups.length) return `<h1 class="text-lg font-semibold text-neutral-900 mb-6">TestFlight</h1>` + empty('No beta groups', 'Create a beta group in App Store Connect to start distributing TestFlight builds.');

  return `<h1 class="text-lg font-semibold text-neutral-900 mb-6">TestFlight</h1>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      ${groups.map(g => `
        <div class="bg-white border border-neutral-200 rounded-xl p-4 hover:shadow-sm transition-shadow">
          <div class="flex items-center justify-between mb-3">
            <div>
              <h3 class="text-sm font-semibold text-neutral-800">${esc(g.name || g.id)}</h3>
              ${g.isInternalGroup !== undefined ? `<span class="text-[0.6rem] ${g.isInternalGroup ? 'text-blue-500' : 'text-neutral-400'}">${g.isInternalGroup ? 'Internal' : 'External'}</span>` : ''}
            </div>
            <div class="text-right">
              <span class="text-2xl font-semibold text-neutral-300">${g.testersCount ?? '?'}</span>
              <p class="text-[0.6rem] text-neutral-400">testers</p>
            </div>
          </div>
          ${affordanceButtons(g.affordances, { class: 'pt-3 border-t border-neutral-100' })}
        </div>
      `).join('')}
    </div>`;
}
