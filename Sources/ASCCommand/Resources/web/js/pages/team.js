import { asc, toList } from '../api.js';
import { esc, table, empty, primaryButton } from '../components.js';

export async function render() {
  const users = toList(await asc('users list --output json'));

  let html = `<div class="flex items-center justify-between mb-6">
    <h1 class="text-lg font-semibold text-neutral-900">Team</h1>
    ${primaryButton('+ Invite Member', 'asc user-invitations invite --email  --first-name  --last-name  --role DEVELOPER')}
  </div>`;

  if (!users.length) return html + empty('No team members', 'Your App Store Connect team members will appear here.');

  const rows = users.map(u => `
    <tr class="border-t border-neutral-50 hover:bg-neutral-50/50 transition-colors">
      <td class="px-5 py-3">
        <div class="flex items-center gap-2.5">
          <div class="w-7 h-7 rounded-full bg-neutral-100 flex items-center justify-center text-[0.6rem] font-semibold text-neutral-500">${esc((u.firstName || '?')[0])}${esc((u.lastName || '?')[0])}</div>
          <span class="text-sm font-medium text-neutral-800">${esc(u.firstName || '')} ${esc(u.lastName || '')}</span>
        </div>
      </td>
      <td class="px-5 py-3 text-xs text-neutral-500">${esc(u.username || '-')}</td>
      <td class="px-5 py-3">
        <div class="flex flex-wrap gap-1">
          ${(u.roles || []).map(r => `<span class="text-[0.6rem] font-medium px-1.5 py-0.5 rounded bg-neutral-100 text-neutral-600">${esc(r)}</span>`).join('')}
        </div>
      </td>
      <td class="px-5 py-3 text-right">
        ${u.affordances ? Object.entries(u.affordances).slice(0, 2).map(([n, c]) =>
          `<button class="asc-action text-[0.6rem] font-medium text-blue-600 hover:text-blue-700 cursor-pointer px-1" data-cmd="${esc(c)}" data-label="${esc(n)}">${esc(n)}</button>`
        ).join('') : ''}
      </td>
    </tr>
  `).join('');

  return html + table(['Member', 'Username', 'Roles', { label: 'Actions', align: 'right' }], rows);
}
