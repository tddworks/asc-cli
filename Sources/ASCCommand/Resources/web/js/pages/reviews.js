import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, affordanceButtons, empty } from '../components.js';

export async function render() {
  if (!state.appId) return empty('No app connected', 'Connect an app to see reviews.');

  const reviews = toList(await asc(`reviews list --app-id ${state.appId} --output json`));

  let html = `<h1 class="text-lg font-semibold text-neutral-900 mb-6">Customer Reviews</h1>`;

  if (!reviews.length) return html + empty('No reviews yet', 'Reviews will appear here once your app is live on the App Store.');

  html += `<div class="space-y-3">${reviews.map(r => {
    const stars = Array.from({ length: 5 }, (_, i) =>
      `<span class="${i < (r.rating || 0) ? 'text-amber-400' : 'text-neutral-200'} text-xs">&#9733;</span>`
    ).join('');

    return `
      <div class="bg-white border border-neutral-200 rounded-xl p-4 hover:shadow-sm transition-shadow">
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center gap-2.5">
            <div class="flex gap-0.5">${stars}</div>
            <span class="text-sm font-medium text-neutral-800">${esc(r.title || 'Untitled')}</span>
          </div>
          <span class="text-[0.6rem] text-neutral-400">${esc(r.reviewerNickname || 'Anonymous')}</span>
        </div>
        <p class="text-xs text-neutral-600 leading-relaxed">${esc(r.body || '')}</p>
        ${affordanceButtons(r.affordances, { class: 'mt-3 pt-2.5 border-t border-neutral-100' })}
      </div>`;
  }).join('')}</div>`;

  return html;
}
