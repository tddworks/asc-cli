import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, badge, table, empty, primaryButton } from '../components.js';

export async function render() {
  if (!state.appId) return empty('No app connected', 'Connect an app to manage in-app purchases.');

  const iaps = toList(await asc(`iap list --app-id ${state.appId} --output json`));

  let html = `<div class="flex items-center justify-between mb-6">
    <h1 class="text-lg font-semibold text-neutral-900">In-App Purchases</h1>
    ${primaryButton('+ Create IAP', `asc iap create --app-id ${state.appId} --type `)}
  </div>`;

  if (!iaps.length) return html + empty('No in-app purchases', 'Create your first IAP to start monetizing.');

  const rows = iaps.map(p => `
    <tr class="border-t border-neutral-50 hover:bg-neutral-50/50 transition-colors">
      <td class="px-5 py-3 text-sm font-medium text-neutral-800">${esc(p.name || p.referenceName || '-')}</td>
      <td class="px-5 py-3 text-xs font-mono text-neutral-500">${esc(p.productId || '-')}</td>
      <td class="px-5 py-3 text-xs text-neutral-500">${esc(p.inAppPurchaseType || p.type || '-')}</td>
      <td class="px-5 py-3">${badge(p.state || 'UNKNOWN')}</td>
      <td class="px-5 py-3 text-right">
        ${p.affordances ? Object.entries(p.affordances).slice(0, 3).map(([n, c]) =>
          `<button class="asc-action text-[0.6rem] font-medium text-blue-600 hover:text-blue-700 cursor-pointer px-1" data-cmd="${esc(c)}" data-label="${esc(n)}">${esc(n)}</button>`
        ).join('') : ''}
      </td>
    </tr>
  `).join('');

  return html + table(['Name', 'Product ID', 'Type', 'State', { label: 'Actions', align: 'right' }], rows);
}
