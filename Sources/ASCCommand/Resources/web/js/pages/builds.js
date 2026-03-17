import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, badge, timeAgo, table, empty, secondaryButton } from '../components.js';

export async function render() {
  if (!state.appId) return empty('No app connected', 'Connect an app to see builds.');

  const builds = toList(await asc(`builds list --app-id ${state.appId} --output json`));
  if (!builds.length) return empty('No builds', 'Upload a build to get started.');

  const rows = builds.map(b => `
    <tr class="border-t border-neutral-50 hover:bg-neutral-50/50 transition-colors">
      <td class="px-5 py-3 text-sm font-medium text-neutral-800">${esc(b.version || '-')}</td>
      <td class="px-5 py-3 text-sm font-mono text-neutral-500">${esc(b.buildNumber || '-')}</td>
      <td class="px-5 py-3 text-xs text-neutral-500">${esc(b.platform || '-')}</td>
      <td class="px-5 py-3">${badge(b.processingState || b.state || 'UNKNOWN')}</td>
      <td class="px-5 py-3 text-xs text-neutral-400">${timeAgo(b.uploadedDate || b.createdDate)}</td>
      <td class="px-5 py-3 text-right">
        <div class="flex justify-end gap-1.5">
          ${b.affordances ? Object.entries(b.affordances).slice(0, 3).map(([n, c]) =>
            `<button class="asc-action text-[0.6rem] font-medium text-blue-600 hover:text-blue-700 cursor-pointer" data-cmd="${esc(c)}" data-label="${esc(n)}">${esc(n)}</button>`
          ).join('') : ''}
        </div>
      </td>
    </tr>
  `).join('');

  return `<div class="flex items-center justify-between mb-6">
    <h1 class="text-lg font-semibold text-neutral-900">Builds</h1>
    ${secondaryButton('Upload Build', `asc builds upload --app-id ${state.appId} --file `)}
  </div>
  ${table(
    ['Version', 'Build #', 'Platform', 'Status', 'Uploaded', { label: 'Actions', align: 'right' }],
    rows
  )}`;
}
