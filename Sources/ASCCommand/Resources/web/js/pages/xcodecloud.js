import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, affordanceButtons, empty } from '../components.js';

export async function render() {
  const products = toList(await asc(`xcode-cloud products list ${state.appId ? '--app-id ' + state.appId : ''} --output json`));

  let html = `<h1 class="text-lg font-semibold text-neutral-900 mb-6">Xcode Cloud</h1>`;

  if (!products.length) return html + empty('No CI/CD products', 'Set up Xcode Cloud in Xcode to see products here.');

  html += products.map(p => `
    <div class="bg-white border border-neutral-200 rounded-xl p-4 mb-4 hover:shadow-sm transition-shadow">
      <div class="flex items-center justify-between mb-1">
        <h3 class="text-sm font-semibold text-neutral-800">${esc(p.name || p.id)}</h3>
      </div>
      <p class="text-xs font-mono text-neutral-400 mb-3">${esc(p.bundleId || p.id)}</p>
      ${affordanceButtons(p.affordances)}
    </div>
  `).join('');

  return html;
}
